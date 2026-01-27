// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

import 'package:foursquare_movement_sdk_example/main.dart';

void main() {
  testWidgets('App has control buttons', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that key buttons are present.
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Get Install ID'), findsOneWidget);
    expect(find.text('Get Current Location'), findsOneWidget);
    expect(find.text('Debug Screen'), findsOneWidget);
  });

  testWidgets('App displays status information', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify status displays are present.
    expect(find.textContaining('Enabled:'), findsOneWidget);
    expect(find.textContaining('Install ID:'), findsOneWidget);
    expect(find.textContaining('Venue:'), findsOneWidget);
  });
}
