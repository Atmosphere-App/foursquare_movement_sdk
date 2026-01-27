// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

package com.atmosphere.foursquare_movement_sdk

import kotlin.test.Test
import kotlin.test.assertNotNull

/*
 * Basic unit test for the Kotlin plugin implementation.
 *
 * NOTE: This plugin uses Pigeon for type-safe communication, so most testing
 * should be done at the integration test level with the native SDK configured.
 *
 * You can run these tests from IDEs that support JUnit such as Android Studio.
 */

internal class FoursquareMovementSdkPluginTest {
    @Test
    fun pluginCanBeInstantiated() {
        val plugin = FoursquareMovementSdkPlugin()
        assertNotNull(plugin)
    }
}
