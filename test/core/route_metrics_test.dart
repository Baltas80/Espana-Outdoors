import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/location/route_metrics.dart';

void main() {
  final analyzer = RouteMetricsAnalyzer();
  final origin = DateTime.utc(2026, 1, 1, 12);

  RouteSample sample(double lat, double lon, int seconds) {
    return RouteSample(
      point: GeoPoint(latitude: lat, longitude: lon),
      capturedAt: origin.add(Duration(seconds: seconds)),
      accuracyMeters: 5,
    );
  }

  test('rejects samples with impossible accuracy', () {
    final result = analyzer.filterSamples([
      sample(40, -3, 0),
      RouteSample(
        point: const GeoPoint(latitude: 40.0001, longitude: -3),
        capturedAt: origin.add(const Duration(seconds: 5)),
        accuracyMeters: 200,
      ),
    ]);

    expect(result, hasLength(1));
  });

  test('rejects an impossible GPS jump', () {
    final result = analyzer.filterSamples([
      sample(40, -3, 0),
      sample(41, -3, 5),
    ]);

    expect(result, hasLength(1));
  });

  test('calculates distance, moving speed and long stops', () {
    final result = analyzer.analyze([
      sample(40, -3, 0),
      sample(40.0001, -3, 10),
      sample(40.0001, -3, 70),
      sample(40.0002, -3, 80),
    ]);

    expect(result.distanceMeters, greaterThan(15));
    expect(result.maxSpeedMps, greaterThan(0));
    expect(result.moving, greaterThan(Duration.zero));
    expect(result.stopped, greaterThan(Duration.zero));
    expect(result.stopCount, 1);
  });

  test('returns empty metrics for insufficient samples', () {
    final result = analyzer.analyze([sample(40, -3, 0)]);

    expect(result.distanceMeters, 0);
    expect(result.stopCount, 0);
    expect(result.elapsed, Duration.zero);
  });
}
