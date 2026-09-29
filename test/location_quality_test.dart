import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:espana_outdoor/core/location/location_quality.dart';

Position position({
  required double latitude,
  required double longitude,
  required double accuracy,
  required DateTime timestamp,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp,
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
    floor: null,
    isMocked: false,
  );
}

void main() {
  const policy = LocationQualityPolicy();
  final now = DateTime(2026, 9, 29, 12);

  test('accepts a normal accurate fix', () {
    final result = policy.evaluate(
      current: position(
        latitude: 40,
        longitude: -3,
        accuracy: 8,
        timestamp: now,
      ),
      now: now,
    );

    expect(result.accepted, isTrue);
  });

  test('rejects poor horizontal accuracy', () {
    final result = policy.evaluate(
      current: position(
        latitude: 40,
        longitude: -3,
        accuracy: 80,
        timestamp: now,
      ),
      now: now,
    );

    expect(result.accepted, isFalse);
  });

  test('rejects stale fixes', () {
    final result = policy.evaluate(
      current: position(
        latitude: 40,
        longitude: -3,
        accuracy: 8,
        timestamp: now.subtract(const Duration(minutes: 2)),
      ),
      now: now,
    );

    expect(result.accepted, isFalse);
  });

  test('rejects an impossible position jump', () {
    final result = policy.evaluate(
      previous: position(
        latitude: 40,
        longitude: -3,
        accuracy: 8,
        timestamp: now.subtract(const Duration(seconds: 5)),
      ),
      current: position(
        latitude: 41,
        longitude: -3,
        accuracy: 8,
        timestamp: now,
      ),
      now: now,
    );

    expect(result.accepted, isFalse);
  });
}
