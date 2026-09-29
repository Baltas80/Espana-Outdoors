import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/sensors/outdoor_sensor_models.dart';

void main() {
  test('standard pressure gives sea-level altitude near zero', () {
    expect(pressureToAltitudeMeters(1013.25), closeTo(0, 0.01));
  });

  test('lower pressure produces higher estimated altitude', () {
    final altitude = pressureToAltitudeMeters(898.76);
    expect(altitude, greaterThan(900));
    expect(altitude, lessThan(1100));
  });

  test('invalid pressure is rejected', () {
    expect(() => pressureToAltitudeMeters(0), throwsArgumentError);
    expect(() => pressureToAltitudeMeters(-1), throwsArgumentError);
  });
}
