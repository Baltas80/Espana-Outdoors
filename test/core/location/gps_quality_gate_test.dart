import 'package:espana_outdoor/core/location/gps_quality_gate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_test/flutter_test.dart';

Position _position({
  double accuracy = 5,
  double speed = 2,
  DateTime? timestamp,
  double latitude = 40,
  double longitude = -3,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: timestamp ?? DateTime.now(),
    accuracy: accuracy,
    altitude: 500,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 5,
    speed: speed,
    speedAccuracy: 1,
  );
}

void main() {
  const gate = GpsQualityGate();

  test('accepts a fresh accurate position', () {
    final result = gate.evaluate(_position());
    expect(result.isUsable, isTrue);
    expect(result.reason, isNull);
  });

  test('rejects poor accuracy', () {
    final result = gate.evaluate(_position(accuracy: 150));
    expect(result.isUsable, isFalse);
  });

  test('rejects stale readings', () {
    final result = gate.evaluate(
      _position(timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
    );
    expect(result.isUsable, isFalse);
  });

  test('rejects implausible speed', () {
    final result = gate.evaluate(_position(speed: 80));
    expect(result.isUsable, isFalse);
  });
}
