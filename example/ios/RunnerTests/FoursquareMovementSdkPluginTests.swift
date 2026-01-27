// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import XCTest
@testable import foursquare_movement_sdk

/// Basic unit test for the Swift plugin implementation.
///
/// NOTE: This plugin uses Pigeon for type-safe communication, so most testing
/// should be done at the integration test level with the native SDK configured.
class FoursquareMovementSdkPluginTests: XCTestCase {

  func testPluginCanBeInstantiated() {
    let plugin = FoursquareMovementSdkPlugin()
    XCTAssertNotNil(plugin)
  }
}
