// Copyright 2026 Atmosphere Innovations, Inc. All rights reserved.
// Use of this source code is governed by an MIT-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare_movement_sdk/foursquare_movement_sdk.dart';

void main() {
  // Note: Platform method tests require native bindings and cannot run in
  // pure Dart unit tests. Those are covered by integration tests.
  // Here we test the data models and verify the API surface exists.

  group('MovementSdk API surface', () {
    test('MovementSdk class exists', () {
      expect(MovementSdk, isNotNull);
    });
  });

  group('FSQLocation', () {
    test('can be constructed', () {
      final location = FSQLocation(latitude: 40.7128, longitude: -74.0060);
      expect(location.latitude, 40.7128);
      expect(location.longitude, -74.0060);
    });
  });

  group('FSQLocationInformation', () {
    test('can be constructed with all fields', () {
      final location = FSQLocation(latitude: 40.0, longitude: -74.0);
      final info = FSQLocationInformation(
        address: '123 Main St',
        crossStreet: 'at 5th Ave',
        city: 'New York',
        state: 'NY',
        postalCode: '10001',
        country: 'US',
        location: location,
      );
      expect(info.address, '123 Main St');
      expect(info.crossStreet, 'at 5th Ave');
      expect(info.city, 'New York');
      expect(info.state, 'NY');
      expect(info.postalCode, '10001');
      expect(info.country, 'US');
      expect(info.location, location);
    });

    test('can be constructed with minimal fields', () {
      final info = FSQLocationInformation();
      expect(info.address, isNull);
      expect(info.location, isNull);
    });
  });

  group('FSQCategoryIcon', () {
    test('can be constructed', () {
      final icon = FSQCategoryIcon(
        prefix: 'https://ss3.4sqi.net/img/categories_v2/',
        suffix: '/bg_64.png',
      );
      expect(icon.prefix, 'https://ss3.4sqi.net/img/categories_v2/');
      expect(icon.suffix, '/bg_64.png');
    });
  });

  group('FSQCategory', () {
    test('can be constructed', () {
      final icon = FSQCategoryIcon(prefix: 'pre', suffix: 'suf');
      final category = FSQCategory(
        id: 'cat123',
        name: 'Coffee Shop',
        pluralName: 'Coffee Shops',
        shortName: 'Coffee',
        icon: icon,
        isPrimary: true,
      );
      expect(category.id, 'cat123');
      expect(category.name, 'Coffee Shop');
      expect(category.pluralName, 'Coffee Shops');
      expect(category.shortName, 'Coffee');
      expect(category.icon, icon);
      expect(category.isPrimary, true);
    });
  });

  group('FSQChain', () {
    test('can be constructed', () {
      final chain = FSQChain(id: 'chain123', name: 'Starbucks');
      expect(chain.id, 'chain123');
      expect(chain.name, 'Starbucks');
    });
  });

  group('FSQVenueParent', () {
    test('can be constructed', () {
      final category = FSQCategory(
        id: 'cat1',
        name: 'Shopping',
        isPrimary: true,
      );
      final parent = FSQVenueParent(
        id: 'parent123',
        name: 'Shopping Mall',
        categories: [category],
      );
      expect(parent.id, 'parent123');
      expect(parent.name, 'Shopping Mall');
      expect(parent.categories, hasLength(1));
    });
  });

  group('FSQVenue', () {
    test('can be constructed with all fields', () {
      final locInfo = FSQLocationInformation(city: 'NYC');
      final venue = FSQVenue(
        id: 'venue123',
        name: 'Test Venue',
        locationInformation: locInfo,
        partnerVenueId: 'partner456',
        probability: 0.95,
        chains: [],
        categories: [],
        hierarchy: [],
      );
      expect(venue.id, 'venue123');
      expect(venue.name, 'Test Venue');
      expect(venue.locationInformation, locInfo);
      expect(venue.partnerVenueId, 'partner456');
      expect(venue.probability, 0.95);
      expect(venue.chains, isEmpty);
      expect(venue.categories, isEmpty);
      expect(venue.hierarchy, isEmpty);
    });

    test('can be constructed with populated lists', () {
      final chain = FSQChain(id: 'c1', name: 'Chain');
      final category = FSQCategory(id: 'cat1', name: 'Cat', isPrimary: true);
      final parent = FSQVenueParent(
        id: 'p1',
        name: 'Parent',
        categories: [category],
      );
      final venue = FSQVenue(
        id: 'v1',
        name: 'Venue',
        chains: [chain],
        categories: [category],
        hierarchy: [parent],
      );
      expect(venue.chains, hasLength(1));
      expect(venue.chains.first.name, 'Chain');
      expect(venue.categories, hasLength(1));
      expect(venue.categories.first.name, 'Cat');
      expect(venue.hierarchy, hasLength(1));
      expect(venue.hierarchy.first.name, 'Parent');
    });

    test('nullable fields default to null', () {
      final venue = FSQVenue(
        id: 'v1',
        name: 'Venue',
        chains: [],
        categories: [],
        hierarchy: [],
      );
      expect(venue.locationInformation, isNull);
      expect(venue.partnerVenueId, isNull);
      expect(venue.probability, isNull);
    });
  });

  group('FSQLocationType', () {
    test('has expected values', () {
      expect(FSQLocationType.values, hasLength(4));
      expect(FSQLocationType.unknown, isNotNull);
      expect(FSQLocationType.home, isNotNull);
      expect(FSQLocationType.work, isNotNull);
      expect(FSQLocationType.venue, isNotNull);
    });
  });

  group('FSQConfidenceLevel', () {
    test('has expected values', () {
      expect(FSQConfidenceLevel.values, hasLength(4));
      expect(FSQConfidenceLevel.none, isNotNull);
      expect(FSQConfidenceLevel.low, isNotNull);
      expect(FSQConfidenceLevel.medium, isNotNull);
      expect(FSQConfidenceLevel.high, isNotNull);
    });
  });

  group('FSQVisit', () {
    test('can be constructed with all fields', () {
      final location = FSQLocation(latitude: 40.0, longitude: -74.0);
      final venue = FSQVenue(
        id: 'v1',
        name: 'Venue',
        chains: [],
        categories: [],
        hierarchy: [],
      );
      final visit = FSQVisit(
        id: 'visit123',
        location: location,
        locationType: FSQLocationType.home,
        confidence: FSQConfidenceLevel.high,
        arrivalTime: 1000,
        venue: venue,
        otherPossibleVenues: [],
        hasDeparted: true,
        departureTime: 2000,
      );
      expect(visit.id, 'visit123');
      expect(visit.location, location);
      expect(visit.locationType, FSQLocationType.home);
      expect(visit.confidence, FSQConfidenceLevel.high);
      expect(visit.arrivalTime, 1000);
      expect(visit.venue, venue);
      expect(visit.otherPossibleVenues, isEmpty);
      expect(visit.hasDeparted, true);
      expect(visit.departureTime, 2000);
    });

    test('nullable fields default to null', () {
      final visit = FSQVisit(
        locationType: FSQLocationType.unknown,
        confidence: FSQConfidenceLevel.none,
        otherPossibleVenues: [],
        hasDeparted: false,
      );
      expect(visit.id, isNull);
      expect(visit.location, isNull);
      expect(visit.arrivalTime, isNull);
      expect(visit.venue, isNull);
      expect(visit.departureTime, isNull);
      expect(visit.hasDeparted, false);
    });
  });

  group('FSQGeofenceEventType', () {
    test('has expected values', () {
      expect(FSQGeofenceEventType.values, hasLength(4));
      expect(FSQGeofenceEventType.entrance, isNotNull);
      expect(FSQGeofenceEventType.dwell, isNotNull);
      expect(FSQGeofenceEventType.exit, isNotNull);
      expect(FSQGeofenceEventType.presence, isNotNull);
    });
  });

  group('FSQGeofenceEvent', () {
    test('can be constructed', () {
      final location = FSQLocation(latitude: 40.0, longitude: -74.0);
      final venue = FSQVenue(
        id: 'v1',
        name: 'Venue',
        chains: [],
        categories: [],
        hierarchy: [],
      );
      final event = FSQGeofenceEvent(
        geofenceId: 'geo123',
        name: 'Test Geofence',
        eventType: FSQGeofenceEventType.entrance,
        venueId: 'v1',
        venue: venue,
        location: location,
        timestamp: 1234567890,
        partnerVenueId: 'partner123',
      );
      expect(event.geofenceId, 'geo123');
      expect(event.name, 'Test Geofence');
      expect(event.eventType, FSQGeofenceEventType.entrance);
      expect(event.venueId, 'v1');
      expect(event.venue, venue);
      expect(event.location, location);
      expect(event.timestamp, 1234567890);
      expect(event.partnerVenueId, 'partner123');
    });

    test('nullable fields default to null', () {
      final location = FSQLocation(latitude: 0.0, longitude: 0.0);
      final event = FSQGeofenceEvent(
        geofenceId: 'geo1',
        name: 'Geofence',
        eventType: FSQGeofenceEventType.dwell,
        location: location,
        timestamp: 0,
      );
      expect(event.venueId, isNull);
      expect(event.venue, isNull);
      expect(event.partnerVenueId, isNull);
    });
  });

  group('FSQCurrentLocation', () {
    test('can be constructed', () {
      final location = FSQLocation(latitude: 40.0, longitude: -74.0);
      final venue = FSQVenue(
        id: 'v1',
        name: 'Venue',
        chains: [],
        categories: [],
        hierarchy: [],
      );
      final currentPlace = FSQVisit(
        location: location,
        locationType: FSQLocationType.home,
        confidence: FSQConfidenceLevel.medium,
        venue: venue,
        otherPossibleVenues: [],
        hasDeparted: false,
      );
      final currentLocation = FSQCurrentLocation(
        currentPlace: currentPlace,
        matchedGeofences: [],
      );
      expect(currentLocation.currentPlace, currentPlace);
      expect(currentLocation.matchedGeofences, isEmpty);
    });

    test('can be constructed with matched geofences', () {
      final location = FSQLocation(latitude: 40.0, longitude: -74.0);
      final geofence = FSQGeofenceEvent(
        geofenceId: 'geo1',
        name: 'Test Geofence',
        eventType: FSQGeofenceEventType.entrance,
        location: location,
        timestamp: 1234567890,
      );
      final currentPlace = FSQVisit(
        locationType: FSQLocationType.unknown,
        confidence: FSQConfidenceLevel.none,
        otherPossibleVenues: [],
        hasDeparted: false,
      );
      final currentLocation = FSQCurrentLocation(
        currentPlace: currentPlace,
        matchedGeofences: [geofence],
      );
      expect(currentLocation.matchedGeofences, hasLength(1));
      expect(currentLocation.matchedGeofences.first.geofenceId, 'geo1');
    });
  });
}
