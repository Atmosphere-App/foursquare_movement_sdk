// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/generated/movement_sdk_api.g.dart',
    kotlinOut:
        'android/src/main/kotlin/com/atmosphere/foursquare_movement_sdk/MovementSdkApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.atmosphere.foursquare_movement_sdk',
    ),
    swiftOut: 'ios/Classes/MovementSdkApi.g.swift',
    swiftOptions: SwiftOptions(),
    dartPackageName: 'foursquare_movement_sdk',
  ),
)
/// A geographic coordinate.
class FSQLocation {
  FSQLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

/// Location information for a venue.
class FSQLocationInformation {
  FSQLocationInformation({
    this.address,
    this.crossStreet,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.location,
  });

  final String? address;
  final String? crossStreet;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final FSQLocation? location;
}

/// Icon image information for a category.
class FSQCategoryIcon {
  FSQCategoryIcon({required this.prefix, required this.suffix});

  final String prefix;
  final String suffix;
}

/// A Foursquare category for a venue.
class FSQCategory {
  FSQCategory({
    required this.id,
    required this.name,
    this.pluralName,
    this.shortName,
    this.icon,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String? pluralName;
  final String? shortName;
  final FSQCategoryIcon? icon;
  final bool isPrimary;
}

/// A Foursquare chain (e.g., Starbucks).
class FSQChain {
  FSQChain({required this.id, required this.name});

  final String id;
  final String name;
}

/// Parent venue in a hierarchy.
class FSQVenueParent {
  FSQVenueParent({
    required this.id,
    required this.name,
    required this.categories,
  });

  final String id;
  final String name;
  final List<FSQCategory> categories;
}

/// A venue in the Foursquare Places database.
class FSQVenue {
  FSQVenue({
    required this.id,
    required this.name,
    this.locationInformation,
    this.partnerVenueId,
    this.probability,
    required this.chains,
    required this.categories,
    required this.hierarchy,
  });

  final String id;
  final String name;
  final FSQLocationInformation? locationInformation;
  final String? partnerVenueId;
  final double? probability;
  final List<FSQChain> chains;
  final List<FSQCategory> categories;
  final List<FSQVenueParent> hierarchy;
}

/// The type of location detected for a visit.
enum FSQLocationType {
  unknown,
  home,
  work,
  venue,
}

/// The confidence level of a visit detection.
enum FSQConfidenceLevel {
  none,
  low,
  medium,
  high,
}

/// Everything the Movement SDK knows about a user's location.
class FSQVisit {
  FSQVisit({
    this.id,
    this.location,
    required this.locationType,
    required this.confidence,
    this.arrivalTime,
    this.venue,
    required this.otherPossibleVenues,
    required this.hasDeparted,
    this.departureTime,
  });

  /// Unique identifier for this visit, if available.
  final String? id;
  final FSQLocation? location;
  final FSQLocationType locationType;
  final FSQConfidenceLevel confidence;
  final int? arrivalTime;
  final FSQVenue? venue;
  final List<FSQVenue> otherPossibleVenues;

  /// Whether the user has departed from this visit.
  final bool hasDeparted;

  /// Departure time as milliseconds since epoch, if departed.
  final int? departureTime;
}

/// The type of geofence event.
enum FSQGeofenceEventType {
  entrance,
  dwell,
  exit,
  presence,
}

/// An interaction with one or more registered geofence radii.
class FSQGeofenceEvent {
  FSQGeofenceEvent({
    required this.geofenceId,
    required this.name,
    required this.eventType,
    this.venueId,
    this.venue,
    this.partnerVenueId,
    required this.location,
    required this.timestamp,
  });

  final String geofenceId;
  final String name;
  final FSQGeofenceEventType eventType;
  final String? venueId;
  final FSQVenue? venue;
  final String? partnerVenueId;
  final FSQLocation location;
  final int timestamp;
}

/// The current location of the user.
class FSQCurrentLocation {
  FSQCurrentLocation({
    required this.currentPlace,
    required this.matchedGeofences,
  });

  final FSQVisit currentPlace;
  final List<FSQGeofenceEvent> matchedGeofences;
}

/// A single entry from the native SDK's debug log buffer.
class FSQDebugLogEntry {
  FSQDebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.type,
    required this.message,
  });

  /// Milliseconds since epoch when the log was recorded.
  final int timestamp;

  /// Severity: "debug", "info", "warn", or "error".
  final String level;

  /// Log source category. iOS provides granular types ("network", "location",
  /// "geofence", etc.); Android always returns "general".
  final String type;

  /// Human-readable description of the event.
  final String message;
}

/// Host API for Movement SDK operations.
/// Implemented by the native platform (iOS/Android).
@HostApi()
abstract class MovementSdkHostApi {
  /// Returns a unique identifier generated the first time the SDK runs on a device.
  @async
  String getInstallId();

  /// Starts the SDK and begins receiving location updates.
  void start();

  /// Stops receiving location updates until [start] is called again.
  void stop();

  /// Gets the current location of the user, including venue and geofences.
  @async
  FSQCurrentLocation getCurrentLocation();

  /// Returns whether the Movement SDK is currently enabled.
  @async
  bool isEnabled();

  /// Generates a test visit at the given location for debugging.
  void fireTestVisit(double latitude, double longitude);

  /// Shows the debug screen for viewing Movement SDK logs.
  void showDebugScreen();

  /// Gets the current user info for server-to-server notifications.
  @async
  Map<String, String> getUserInfo();

  /// Sets user info for server-to-server visit notifications.
  void setUserInfo(Map<String, String> userInfo, bool persisted);

  /// Sets the user ID for server-to-server visit notifications.
  ///
  /// This uses the dedicated native setter which is required for the
  /// predefined "userId" key (the generic setUserInfo silently ignores it on iOS).
  void setUserId(String userId, bool persisted);

  /// Clears all data including unique identifiers and cached data.
  ///
  /// Should be called when a user logs out of your app.
  void clearAllData();

  /// Returns the currently active visit, or null if there is no active visit.
  @async
  FSQVisit? getActiveVisit();

  /// Returns recent debug log entries collected by the native SDK.
  ///
  /// Requires debug logging to be enabled natively
  /// (`isDebugLogsEnabled` on iOS, `setEnableDebugLogs` on Android).
  @async
  List<FSQDebugLogEntry> getDebugLogs();

  /// Clears the native SDK's debug log buffer.
  void clearDebugLogs();
}

/// Flutter API for receiving real-time events from the native SDK.
/// Implemented on the Dart side, called by native code.
@FlutterApi()
abstract class MovementSdkFlutterApi {
  /// Called when the user arrives at or departs from a place.
  void onVisit(FSQVisit visit);

  /// Called for visits that occurred when there was no network connectivity.
  void onBackfillVisit(FSQVisit visit);

  /// Called when geofence events are triggered.
  void onGeofenceEvents(List<FSQGeofenceEvent> events);
}
