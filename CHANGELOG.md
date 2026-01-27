## 0.0.1

* Initial release of the Foursquare Movement SDK Flutter plugin
* Support for passive location detection and venue matching
* Geofence monitoring capabilities
* Cross-platform support for iOS (13.0+) and Android (API 24+)
* Type-safe API using Pigeon for platform communication
* Type-safe `FSQLocationType`, `FSQConfidenceLevel`, and `FSQGeofenceEventType` enums
* `FSQVisit` includes `id`, `hasDeparted`, and `departureTime` fields
* Real-time event streams: `onVisit`, `onBackfillVisit`, `onGeofenceEvents`
* Methods:
  * `start()` / `stop()` - Control SDK location tracking
  * `getCurrentLocation()` - Get current place visit and matched geofences
  * `getActiveVisit()` - Get the currently active visit
  * `getInstallId()` - Retrieve unique device identifier
  * `isEnabled()` - Check SDK status
  * `fireTestVisit()` - Generate test visits for debugging
  * `showDebugScreen()` - Display SDK debug logs
  * `setUserInfo()` / `getUserInfo()` - Manage user info for server-to-server notifications
  * `setUserId()` - Set user ID for server-to-server notifications
  * `clearAllData()` - Clear all SDK data and identifiers
* Native SDK versions:
  * Android: Movement SDK 4.0.1
  * iOS: Movement SDK 4.0.5
