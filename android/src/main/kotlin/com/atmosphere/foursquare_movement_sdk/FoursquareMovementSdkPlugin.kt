// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

package com.atmosphere.foursquare_movement_sdk

import android.app.Activity
import android.content.Context
import android.content.Intent
import com.foursquare.api.FoursquareLocation
import com.foursquare.api.types.Category
import com.foursquare.api.types.Photo
import com.foursquare.api.types.Venue
import com.foursquare.api.types.geofence.GeofenceEvent
import com.foursquare.api.types.geofence.GeofenceEventType
import com.foursquare.movement.BackfillNotification
import com.foursquare.movement.Confidence
import com.foursquare.movement.CurrentLocation
import com.foursquare.movement.GeofenceEventNotification
import com.foursquare.movement.LocationType
import com.foursquare.movement.MovementSdk
import com.foursquare.movement.NotificationHandler
import com.foursquare.movement.NotificationTester
import com.foursquare.movement.UserInfo
import com.foursquare.movement.UserStateNotification
import com.foursquare.movement.Visit
import com.foursquare.movement.VisitNotification
import com.foursquare.movement.debugging.DebugActivity
import com.foursquare.api.types.Journey
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import android.os.Handler
import android.os.Looper
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/** FoursquareMovementSdkPlugin */
class FoursquareMovementSdkPlugin :
    FlutterPlugin,
    ActivityAware,
    MovementSdkHostApi,
    NotificationHandler {

    private lateinit var context: Context
    private var activity: Activity? = null
    private var flutterApi: MovementSdkFlutterApi? = null
    private val executor: ExecutorService = Executors.newSingleThreadExecutor()
    private val mainHandler: Handler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        MovementSdkHostApi.setUp(flutterPluginBinding.binaryMessenger, this)
        flutterApi = MovementSdkFlutterApi(flutterPluginBinding.binaryMessenger)
        try {
            MovementSdk.get().setNotificationHandler(this)
        } catch (_: Exception) {
            // SDK may not be initialized yet
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        MovementSdkHostApi.setUp(binding.binaryMessenger, null)
        flutterApi = null
        executor.shutdown()
    }

    // MARK: - NotificationHandler

    override fun handleVisit(context: Context, notification: VisitNotification) {
        val converted = convertVisit(notification.visit)
        mainHandler.post { flutterApi?.onVisit(converted) {} }
    }

    override fun handleBackfillVisit(context: Context, notification: BackfillNotification) {
        val converted = convertVisit(notification.visit)
        mainHandler.post { flutterApi?.onBackfillVisit(converted) {} }
    }

    override fun handleGeofenceEventNotification(context: Context, notification: GeofenceEventNotification) {
        val converted = notification.geofenceEvents.map { convertGeofenceEvent(it) }
        mainHandler.post { flutterApi?.onGeofenceEvents(converted) {} }
    }

    override fun handleUserStateChange(context: Context, notification: UserStateNotification) {
        // Not yet exposed to Flutter
    }

    override fun handleJourneyUpdate(context: Context, journey: Journey) {
        // Not yet exposed to Flutter
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // MARK: - MovementSdkHostApi Implementation

    override fun getInstallId(callback: (Result<String>) -> Unit) {
        callback(Result.success(MovementSdk.getInstallId()))
    }

    override fun start() {
        MovementSdk.start(context)
    }

    override fun stop() {
        MovementSdk.stop(context)
    }

    override fun getCurrentLocation(callback: (Result<FSQCurrentLocation>) -> Unit) {
        executor.execute {
            val result = MovementSdk.get().getCurrentLocation()
            if (result.isOk) {
                callback(Result.success(convertCurrentLocation(result.result)))
            } else {
                callback(Result.failure(Exception(result.err)))
            }
        }
    }

    override fun isEnabled(callback: (Result<Boolean>) -> Unit) {
        callback(Result.success(MovementSdk.isEnabled()))
    }

    override fun fireTestVisit(latitude: Double, longitude: Double) {
        NotificationTester.sendTestVisitArrivalAtLocation(
            context,
            latitude,
            longitude,
            false
        )
    }

    override fun showDebugScreen() {
        val intent = Intent(context, DebugActivity::class.java)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    override fun getUserInfo(callback: (Result<Map<String, String>>) -> Unit) {
        val userInfo = MovementSdk.get().userInfo
        val result = mutableMapOf<String, String>()
        userInfo?.entries?.forEach { entry ->
            result[entry.key] = entry.value
        }
        callback(Result.success(result))
    }

    override fun setUserInfo(userInfo: Map<String, String>, persisted: Boolean) {
        val fsqUserInfo = UserInfo()
        userInfo.entries.forEach { entry ->
            fsqUserInfo[entry.key] = entry.value
        }
        MovementSdk.get().setUserInfo(fsqUserInfo, persisted)
    }

    override fun setUserId(userId: String, persisted: Boolean) {
        val fsqUserInfo = MovementSdk.get().userInfo ?: UserInfo()
        fsqUserInfo.setUserId(userId)
        MovementSdk.get().setUserInfo(fsqUserInfo, persisted)
    }

    override fun clearAllData() {
        MovementSdk.clearAllData(context)
    }

    override fun getActiveVisit(callback: (Result<FSQVisit?>) -> Unit) {
        executor.execute {
            val visit = MovementSdk.get().getCurrentVisit(context)
            callback(Result.success(visit?.let { convertVisit(it) }))
        }
    }

    // MARK: - Conversion Methods

    private fun convertCurrentLocation(currentLocation: CurrentLocation): FSQCurrentLocation {
        return FSQCurrentLocation(
            currentPlace = convertVisit(currentLocation.currentPlace),
            matchedGeofences = currentLocation.matchedGeofences.map { convertGeofenceEvent(it) }
        )
    }

    private fun convertVisit(visit: Visit): FSQVisit {
        val locationType = when (visit.getType()) {
            LocationType.HOME -> FSQLocationType.HOME
            LocationType.WORK -> FSQLocationType.WORK
            LocationType.VENUE -> FSQLocationType.VENUE
            else -> FSQLocationType.UNKNOWN
        }
        val confidence = when (visit.getConfidence()) {
            Confidence.LOW -> FSQConfidenceLevel.LOW
            Confidence.MEDIUM -> FSQConfidenceLevel.MEDIUM
            Confidence.HIGH -> FSQConfidenceLevel.HIGH
            else -> FSQConfidenceLevel.NONE
        }
        return FSQVisit(
            id = visit.getVisitId(),
            location = convertFoursquareLocation(visit.location),
            locationType = locationType,
            confidence = confidence,
            arrivalTime = visit.arrival,
            venue = visit.getVenue()?.let { convertVenue(it) },
            otherPossibleVenues = visit.getOtherPossibleVenues().map { convertVenue(it) },
            hasDeparted = visit.hasDeparted(),
            departureTime = if (visit.hasDeparted()) visit.getDeparture() else null
        )
    }

    private fun convertVenue(venue: Venue): FSQVenue {
        return FSQVenue(
            id = venue.id,
            name = venue.name,
            locationInformation = convertVenueLocation(venue.location),
            partnerVenueId = venue.partnerVenueId,
            probability = venue.probability,
            chains = venue.venueChains.map { convertChain(it) },
            categories = venue.categories.map { convertCategory(it) },
            hierarchy = venue.hierarchy.map { convertVenueParent(it) }
        )
    }

    private fun convertVenueLocation(location: Venue.Location): FSQLocationInformation {
        return FSQLocationInformation(
            address = location.address,
            crossStreet = location.crossStreet,
            city = location.city,
            state = location.state,
            postalCode = location.postalCode,
            country = location.country,
            location = FSQLocation(
                latitude = location.lat,
                longitude = location.lng
            )
        )
    }

    private fun convertCategory(category: Category): FSQCategory {
        return FSQCategory(
            id = category.id ?: "",
            name = category.name ?: "",
            pluralName = category.pluralName,
            shortName = category.shortName,
            icon = category.image?.let { convertCategoryIcon(it) },
            isPrimary = category.isPrimary
        )
    }

    private fun convertCategoryIcon(photo: Photo): FSQCategoryIcon {
        return FSQCategoryIcon(
            prefix = photo.prefix ?: "",
            suffix = photo.suffix ?: ""
        )
    }

    private fun convertChain(chain: Venue.VenueChain): FSQChain {
        return FSQChain(
            id = chain.id ?: "",
            name = chain.name ?: ""
        )
    }

    private fun convertVenueParent(parent: Venue.VenueParent): FSQVenueParent {
        return FSQVenueParent(
            id = parent.id ?: "",
            name = parent.name ?: "",
            categories = parent.categories.map { convertCategory(it) }
        )
    }

    private fun convertGeofenceEvent(event: GeofenceEvent): FSQGeofenceEvent {
        val eventType = when (event.geofenceEventType) {
            GeofenceEventType.ENTRANCE -> FSQGeofenceEventType.ENTRANCE
            GeofenceEventType.DWELL -> FSQGeofenceEventType.DWELL
            GeofenceEventType.EXIT -> FSQGeofenceEventType.EXIT
            GeofenceEventType.PRESENCE -> FSQGeofenceEventType.PRESENCE
            else -> FSQGeofenceEventType.ENTRANCE
        }
        return FSQGeofenceEvent(
            geofenceId = event.id ?: "",
            name = event.name ?: "",
            eventType = eventType,
            venueId = event.venue?.id,
            venue = event.venue?.let { convertVenue(it) },
            partnerVenueId = event.partnerVenueId,
            location = FSQLocation(
                latitude = event.lat,
                longitude = event.lng
            ),
            timestamp = event.timestamp
        )
    }

    private fun convertFoursquareLocation(location: FoursquareLocation): FSQLocation {
        return FSQLocation(
            latitude = location.lat,
            longitude = location.lng
        )
    }
}
