// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'generated/movement_sdk_api.g.dart';

export 'generated/movement_sdk_api.g.dart'
    show
        FSQLocation,
        FSQLocationInformation,
        FSQCategoryIcon,
        FSQCategory,
        FSQChain,
        FSQVenueParent,
        FSQVenue,
        FSQVisit,
        FSQLocationType,
        FSQConfidenceLevel,
        FSQGeofenceEventType,
        FSQGeofenceEvent,
        FSQCurrentLocation;

class _MovementSdkFlutterApiHandler extends MovementSdkFlutterApi {
  final StreamController<FSQVisit> _visitController =
      StreamController<FSQVisit>.broadcast();
  final StreamController<FSQVisit> _backfillVisitController =
      StreamController<FSQVisit>.broadcast();
  final StreamController<List<FSQGeofenceEvent>> _geofenceController =
      StreamController<List<FSQGeofenceEvent>>.broadcast();

  @override
  void onVisit(FSQVisit visit) => _visitController.add(visit);

  @override
  void onBackfillVisit(FSQVisit visit) => _backfillVisitController.add(visit);

  @override
  void onGeofenceEvents(List<FSQGeofenceEvent> events) =>
      _geofenceController.add(events);
}

/// Flutter wrapper for the Foursquare Movement SDK.
///
/// The Movement SDK enables passive location detection and venue matching
/// for your application. Before using any methods, you must configure the
/// SDK in your native application code.
///
/// ## iOS Setup
/// In your `AppDelegate.swift`:
/// ```swift
/// import MovementSdk
///
/// @UIApplicationMain
/// class AppDelegate: UIResponder, UIApplicationDelegate {
///   func application(_ application: UIApplication,
///     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
///     MovementSdkManager.shared.configure(
///       withConsumerKey: "YOUR_CONSUMER_KEY",
///       secret: "YOUR_CONSUMER_SECRET",
///       delegate: nil,
///       completion: nil
///     )
///     return true
///   }
/// }
/// ```
///
/// ## Android Setup
/// In your `Application` class:
/// ```kotlin
/// import com.foursquare.movement.MovementSdk
///
/// class MyApplication : Application() {
///   override fun onCreate() {
///     super.onCreate()
///     MovementSdk.with(
///       MovementSdk.Builder(this)
///         .consumer("YOUR_CONSUMER_KEY", "YOUR_CONSUMER_SECRET")
///         .enableDebugLogs()
///     )
///   }
/// }
/// ```
class MovementSdk {
  MovementSdk._();

  static final _MovementSdkFlutterApiHandler _handler =
      _MovementSdkFlutterApiHandler();
  static final MovementSdkHostApi _api = _createApi();

  static MovementSdkHostApi _createApi() {
    MovementSdkFlutterApi.setUp(_handler);
    return MovementSdkHostApi();
  }

  /// Returns a unique identifier generated the first time the SDK runs on a device.
  ///
  /// This can be used to allow your users to submit Data Erasure Requests
  /// or for debugging in the Foursquare Developer Console Event Logs tool.
  static Future<String> getInstallId() => _api.getInstallId();

  /// Starts the SDK and begins receiving location updates.
  ///
  /// Call this after configuring the SDK to enable passive location detection.
  static Future<void> start() => _api.start();

  /// Stops receiving location updates.
  ///
  /// Location updates will resume when [start] is called again.
  static Future<void> stop() => _api.stop();

  /// Gets the current location of the user.
  ///
  /// Returns a [FSQCurrentLocation] containing the current place visit
  /// and any matched geofences.
  static Future<FSQCurrentLocation> getCurrentLocation() =>
      _api.getCurrentLocation();

  /// Returns whether the Movement SDK is currently enabled.
  static Future<bool> isEnabled() => _api.isEnabled();

  /// Generates a test visit at the given location for debugging.
  ///
  /// This will trigger a visit notification as if the user had arrived
  /// at the specified location.
  static Future<void> fireTestVisit(double latitude, double longitude) =>
      _api.fireTestVisit(latitude, longitude);

  /// Shows the debug screen for viewing Movement SDK logs.
  ///
  /// On iOS, this requires iOS 14.0 or later.
  static Future<void> showDebugScreen() => _api.showDebugScreen();

  /// Gets the current user info for server-to-server notifications.
  ///
  /// Returns a map of user info key-value pairs.
  static Future<Map<String, String>> getUserInfo() async {
    final result = await _api.getUserInfo();
    return Map<String, String>.from(result);
  }

  /// Sets user info for server-to-server visit notifications.
  ///
  /// For applications utilizing the server-to-server method for visit
  /// notifications, you can use this to pass through your own identifier
  /// to the notification endpoint call.
  ///
  /// Set [persisted] to `true` to persist the user info data across
  /// app restarts.
  static Future<void> setUserInfo(
    Map<String, String> userInfo, {
    bool persisted = false,
  }) => _api.setUserInfo(userInfo, persisted);

  /// Sets the user ID for server-to-server visit notifications.
  ///
  /// This uses the dedicated native setter which is required for the
  /// predefined "userId" key. The generic [setUserInfo] method silently
  /// ignores predefined keys like userId on iOS.
  ///
  /// Set [persisted] to `true` to persist across app restarts.
  static Future<void> setUserId(
    String userId, {
    bool persisted = false,
  }) => _api.setUserId(userId, persisted);

  /// Clears all data including unique identifiers and cached data.
  ///
  /// Should be called when a user logs out of your app to reset
  /// any configured identifiers.
  static Future<void> clearAllData() => _api.clearAllData();

  /// Returns the currently active visit, or `null` if there is no active visit.
  static Future<FSQVisit?> getActiveVisit() => _api.getActiveVisit();

  /// Stream of visit events (arrivals and departures).
  ///
  /// Listen to this stream to receive real-time visit notifications
  /// from the native Movement SDK.
  static Stream<FSQVisit> get onVisit => _handler._visitController.stream;

  /// Stream of backfill visit events.
  ///
  /// These are visits that occurred when there was no network connectivity
  /// and are being reported retroactively.
  static Stream<FSQVisit> get onBackfillVisit =>
      _handler._backfillVisitController.stream;

  /// Stream of geofence events.
  ///
  /// Listen to this stream to receive real-time geofence entry, dwell,
  /// exit, and presence events.
  static Stream<List<FSQGeofenceEvent>> get onGeofenceEvents =>
      _handler._geofenceController.stream;
}
