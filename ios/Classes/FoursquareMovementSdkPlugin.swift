// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import Flutter
import UIKit
import CoreLocation
import MovementSdk

// Type aliases to disambiguate SDK types from Pigeon-generated types
typealias SDKCurrentLocation = MovementSdk.CurrentLocation
typealias SDKVisit = MovementSdk.Visit
typealias SDKVenue = MovementSdk.Venue
typealias SDKVenueLocation = MovementSdk.Venue.Location
typealias SDKCategory = MovementSdk.Category
typealias SDKCategoryIcon = MovementSdk.Category.Icon
typealias SDKChain = MovementSdk.Venue.Chain
typealias SDKGeofenceEvent = MovementSdk.GeofenceEvent

public class FoursquareMovementSdkPlugin: NSObject, FlutterPlugin, MovementSdkHostApi, MovementSdkManagerDelegate {
  private var flutterApi: MovementSdkFlutterApi?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = FoursquareMovementSdkPlugin()
    MovementSdkHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    instance.flutterApi = MovementSdkFlutterApi(binaryMessenger: registrar.messenger())
    MovementSdkManager.shared.delegate = instance
  }

  // MARK: - MovementSdkManagerDelegate

  public func movementManager(_ movementManager: MovementSdkManager, handle visit: MovementSdk.Visit) {
    let converted = convertVisit(visit)
    DispatchQueue.main.async { [weak self] in
      self?.flutterApi?.onVisit(visit: converted) { _ in }
    }
  }

  public func movementManager(_ movementManager: MovementSdkManager, handleBackfill visit: MovementSdk.Visit) {
    let converted = convertVisit(visit)
    DispatchQueue.main.async { [weak self] in
      self?.flutterApi?.onBackfillVisit(visit: converted) { _ in }
    }
  }

  public func movementManager(_ movementManager: MovementSdkManager, handle geofenceEvents: [MovementSdk.GeofenceEvent]) {
    let converted = geofenceEvents.map { convertGeofenceEvent($0) }
    DispatchQueue.main.async { [weak self] in
      self?.flutterApi?.onGeofenceEvents(events: converted) { _ in }
    }
  }

  // MARK: - MovementSdkHostApi Implementation

  func getInstallId(completion: @escaping (Result<String, any Error>) -> Void) {
    completion(.success(MovementSdkManager.shared.installId ?? ""))
  }

  func start() throws {
    MovementSdkManager.shared.start()
  }

  func stop() throws {
    MovementSdkManager.shared.stop()
  }

  func getCurrentLocation(completion: @escaping (Result<FSQCurrentLocation, any Error>) -> Void) {
    MovementSdkManager.shared.getCurrentLocation { sdkCurrentLocation, error in
      if let error = error {
        completion(.failure(PigeonError(code: "GET_CURRENT_LOCATION_ERROR", message: error.localizedDescription, details: nil)))
        return
      }
      guard let sdkCurrentLocation = sdkCurrentLocation else {
        completion(.failure(PigeonError(code: "GET_CURRENT_LOCATION_ERROR", message: "No current location available", details: nil)))
        return
      }
      completion(.success(self.convertCurrentLocation(sdkCurrentLocation)))
    }
  }

  func isEnabled(completion: @escaping (Result<Bool, any Error>) -> Void) {
    completion(.success(MovementSdkManager.shared.isEnabled))
  }

  func fireTestVisit(latitude: Double, longitude: Double) throws {
    let location = CLLocation(latitude: latitude, longitude: longitude)
    MovementSdkManager.shared.visitTester.fireTestVisit(location: location)
  }

  func showDebugScreen() throws {
    MovementSdkManager.shared.isDebugLogsEnabled = true
    guard #available(iOS 14.0, *) else { return }
    let viewController = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
    if let viewController = viewController {
      MovementSdkManager.shared.presentDebugViewController(parentViewController: viewController)
    }
  }

  func getUserInfo(completion: @escaping (Result<[String: String], any Error>) -> Void) {
    completion(.success(MovementSdkManager.shared.userInfo.source))
  }

  func setUserInfo(userInfo: [String: String], persisted: Bool) throws {
    let fsqUserInfo = UserInfo()
    for (key, value) in userInfo {
      fsqUserInfo.setUserInfo(value, forKey: key)
    }
    MovementSdkManager.shared.setUserInfo(fsqUserInfo, persisted: persisted)
  }

  func setUserId(userId: String, persisted: Bool) throws {
    let fsqUserInfo = MovementSdkManager.shared.userInfo
    fsqUserInfo.setUserId(userId)
    MovementSdkManager.shared.setUserInfo(fsqUserInfo, persisted: persisted)
  }

  func clearAllData() throws {
    MovementSdkManager.shared.clearAllData(completion: nil)
  }

  func getActiveVisit(completion: @escaping (Result<FSQVisit?, any Error>) -> Void) {
    MovementSdkManager.shared.getCurrentLocation { currentLocation, error in
      guard let currentLocation = currentLocation, error == nil else {
        completion(.success(nil))
        return
      }
      completion(.success(self.convertVisit(currentLocation.currentPlace)))
    }
  }

  // MARK: - Conversion Methods

  private func convertCurrentLocation(_ sdkCurrentLocation: SDKCurrentLocation) -> FSQCurrentLocation {
    return FSQCurrentLocation(
      currentPlace: convertVisit(sdkCurrentLocation.currentPlace),
      matchedGeofences: sdkCurrentLocation.matchedGeofences.map { convertGeofenceEvent($0) }
    )
  }

  private func convertVisit(_ sdkVisit: SDKVisit) -> FSQVisit {
    let locationType: FSQLocationType
    switch sdkVisit.locationType {
    case .home:
      locationType = .home
    case .work:
      locationType = .work
    case .venue:
      locationType = .venue
    default:
      locationType = .unknown
    }

    let confidence: FSQConfidenceLevel
    switch sdkVisit.confidence {
    case .low:
      confidence = .low
    case .medium:
      confidence = .medium
    case .high:
      confidence = .high
    default:
      confidence = .none
    }

    return FSQVisit(
      id: sdkVisit.id,
      location: sdkVisit.arrivalLocation.map { convertCLLocation($0) },
      locationType: locationType,
      confidence: confidence,
      arrivalTime: sdkVisit.arrivalDate.map { Int64($0.timeIntervalSince1970 * 1000) },
      venue: sdkVisit.venue.map { convertVenue($0) },
      otherPossibleVenues: sdkVisit.otherPossibleVenues.map { convertVenue($0) },
      hasDeparted: sdkVisit.hasDeparted,
      departureTime: sdkVisit.departureDate.map { Int64($0.timeIntervalSince1970 * 1000) }
    )
  }

  private func convertVenue(_ sdkVenue: SDKVenue) -> FSQVenue {
    return FSQVenue(
      id: sdkVenue.id,
      name: sdkVenue.name,
      locationInformation: sdkVenue.locationInformation.map { convertVenueLocation($0) },
      partnerVenueId: sdkVenue.partnerVenueId,
      probability: sdkVenue.probability?.doubleValue,
      chains: sdkVenue.chains.map { convertChain($0) },
      categories: sdkVenue.categories.map { convertCategory($0) },
      hierarchy: sdkVenue.hierarchy.map { convertVenueParent($0) }
    )
  }

  private func convertVenueLocation(_ sdkLocation: SDKVenueLocation) -> FSQLocationInformation {
    return FSQLocationInformation(
      address: sdkLocation.address,
      crossStreet: sdkLocation.crossStreet,
      city: sdkLocation.city,
      state: sdkLocation.state,
      postalCode: sdkLocation.postalCode,
      country: sdkLocation.country,
      location: FSQLocation(
        latitude: sdkLocation.coordinate.latitude,
        longitude: sdkLocation.coordinate.longitude
      )
    )
  }

  private func convertCategory(_ sdkCategory: SDKCategory) -> FSQCategory {
    return FSQCategory(
      id: sdkCategory.id ?? "",
      name: sdkCategory.name ?? "",
      pluralName: sdkCategory.pluralName,
      shortName: sdkCategory.shortName,
      icon: sdkCategory.icon.map { convertCategoryIcon($0) },
      isPrimary: sdkCategory.isPrimary
    )
  }

  private func convertCategoryIcon(_ sdkIcon: SDKCategoryIcon) -> FSQCategoryIcon {
    return FSQCategoryIcon(
      prefix: sdkIcon.prefix ?? "",
      suffix: sdkIcon.suffix ?? ""
    )
  }

  private func convertChain(_ sdkChain: SDKChain) -> FSQChain {
    return FSQChain(
      id: sdkChain.id ?? "",
      name: sdkChain.name ?? ""
    )
  }

  private func convertVenueParent(_ sdkParentVenue: SDKVenue) -> FSQVenueParent {
    return FSQVenueParent(
      id: sdkParentVenue.id,
      name: sdkParentVenue.name,
      categories: sdkParentVenue.categories.map { convertCategory($0) }
    )
  }

  private func convertGeofenceEvent(_ sdkEvent: SDKGeofenceEvent) -> FSQGeofenceEvent {
    let eventType: FSQGeofenceEventType
    switch sdkEvent.eventType {
    case .entrance:
      eventType = .entrance
    case .dwell:
      eventType = .dwell
    case .exit:
      eventType = .exit
    case .presence:
      eventType = .presence
    default:
      eventType = .entrance
    }

    return FSQGeofenceEvent(
      geofenceId: sdkEvent.geofenceId,
      name: sdkEvent.name,
      eventType: eventType,
      venueId: sdkEvent.venue?.id,
      venue: sdkEvent.venue.map { convertVenue($0) },
      partnerVenueId: sdkEvent.partnerVenueId,
      location: FSQLocation(
        latitude: sdkEvent.location.coordinate.latitude,
        longitude: sdkEvent.location.coordinate.longitude
      ),
      timestamp: Int64(sdkEvent.timestamp.timeIntervalSince1970 * 1000)
    )
  }

  private func convertCLLocation(_ location: CLLocation) -> FSQLocation {
    return FSQLocation(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude
    )
  }
}
