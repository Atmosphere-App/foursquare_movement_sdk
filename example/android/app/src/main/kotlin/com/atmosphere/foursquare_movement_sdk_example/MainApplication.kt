package com.atmosphere.foursquare_movement_sdk_example

import android.app.Application
import com.foursquare.movement.LogLevel
import com.foursquare.movement.MovementSdk

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        MovementSdk.with(
            MovementSdk.Builder(this)
                .consumer("YOUR_CONSUMER_KEY", "YOUR_CONSUMER_SECRET")
                .enableDebugLogs()
                .logLevel(LogLevel.DEBUG)
                .enableLiveConsoleEvents()
        )
    }
}
