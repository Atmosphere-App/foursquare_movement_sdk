// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing
//
// NOTE: These tests require Foursquare Movement SDK to be properly configured
// in the native code with valid consumer key and secret.

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare_movement_sdk/foursquare_movement_sdk.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('MovementSdk Integration Tests', () {
    test('getInstallId returns non-empty string', () async {
      final installId = await MovementSdk.getInstallId();
      expect(installId, isNotNull);
      expect(installId.isNotEmpty, true);
    });

    test('isEnabled returns boolean', () async {
      final enabled = await MovementSdk.isEnabled();
      expect(enabled, isA<bool>());
    });

    test('getUserInfo returns map', () async {
      final userInfo = await MovementSdk.getUserInfo();
      expect(userInfo, isA<Map<String, String>>());
    });

    test('start and stop do not throw', () async {
      await expectLater(MovementSdk.start(), completes);
      await expectLater(MovementSdk.stop(), completes);
    });

    test('setUserInfo and getUserInfo round-trip', () async {
      final testData = {
        'customId': 'test_user_123',
        'customKey': 'customValue',
      };
      await MovementSdk.setUserInfo(testData, persisted: false);

      // Retrieve and verify
      final retrievedInfo = await MovementSdk.getUserInfo();
      expect(retrievedInfo, isA<Map<String, String>>());
      expect(retrievedInfo['customId'], equals('test_user_123'));
      expect(retrievedInfo['customKey'], equals('customValue'));
    });

    test('setUserInfo with persisted flag round-trips', () async {
      final testData = {
        'persistedKey': 'persistedValue',
      };
      await MovementSdk.setUserInfo(testData, persisted: true);

      final retrievedInfo = await MovementSdk.getUserInfo();
      expect(retrievedInfo['persistedKey'], equals('persistedValue'));
    });

    test('setUserInfo with empty map clears user info', () async {
      // First set some data
      await MovementSdk.setUserInfo({'tempKey': 'tempValue'}, persisted: false);
      // Then clear it
      await MovementSdk.setUserInfo({}, persisted: false);

      final retrievedInfo = await MovementSdk.getUserInfo();
      expect(retrievedInfo['tempKey'], isNull);
    });

    test('getInstallId returns same value on repeated calls', () async {
      final id1 = await MovementSdk.getInstallId();
      final id2 = await MovementSdk.getInstallId();
      expect(id1, equals(id2));
    });

    test('stop before start does not throw', () async {
      await expectLater(MovementSdk.stop(), completes);
    });

    test('start then stop changes isEnabled', () async {
      await MovementSdk.start();
      await MovementSdk.stop();
      final enabledAfterStop = await MovementSdk.isEnabled();
      expect(enabledAfterStop, isFalse);
    });

    // Note: getCurrentLocation is not tested here because it requires a real
    // GPS fix and will block indefinitely on Android in test environments.

    test('fireTestVisit does not throw', () async {
      // Fire a test visit at a known location (Times Square, NYC)
      await MovementSdk.fireTestVisit(40.7580, -73.9855);
    });

    test('setUserId does not throw', () async {
      await MovementSdk.setUserId('test_user_abc');
    });

    test('setUserId preserves existing user info', () async {
      // Set custom keys first
      await MovementSdk.setUserInfo(
        {'customKey': 'customValue'},
        persisted: false,
      );

      // Now set userId — should not clear customKey
      await MovementSdk.setUserId('preserve_test_user', persisted: false);

      final retrievedInfo = await MovementSdk.getUserInfo();
      expect(retrievedInfo['customKey'], equals('customValue'));
    });

    test('clearAllData does not throw', () async {
      await MovementSdk.clearAllData();
    });

    test('getActiveVisit returns FSQVisit or null', () async {
      final visit = await MovementSdk.getActiveVisit();
      expect(visit, anyOf(isNull, isA<FSQVisit>()));
    });

    test('stream accessors return broadcast streams', () {
      final visitStream = MovementSdk.onVisit;
      expect(visitStream, isA<Stream<FSQVisit>>());
      expect(visitStream.isBroadcast, isTrue);

      final backfillStream = MovementSdk.onBackfillVisit;
      expect(backfillStream, isA<Stream<FSQVisit>>());
      expect(backfillStream.isBroadcast, isTrue);

      final geofenceStream = MovementSdk.onGeofenceEvents;
      expect(geofenceStream, isA<Stream<List<FSQGeofenceEvent>>>());
      expect(geofenceStream.isBroadcast, isTrue);
    });

    test('getDebugLogs returns list', () async {
      final logs = await MovementSdk.getDebugLogs();
      expect(logs, isA<List<FSQDebugLogEntry>>());
    });

    test('clearDebugLogs does not throw', () async {
      await expectLater(MovementSdk.clearDebugLogs(), completes);
    });

    test('clearDebugLogs then getDebugLogs returns empty', () async {
      await MovementSdk.clearDebugLogs();
      final logs = await MovementSdk.getDebugLogs();
      expect(logs, isEmpty);
    });
  });
}
