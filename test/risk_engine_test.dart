import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/contracts/platform_services.dart';
import 'package:espana_outdoors/domain/safety/risk_engine.dart';

void main() {
  final now = DateTime.utc(2026, 9, 23, 16);
  final weather = WeatherSnapshot(
    observedAt: now.subtract(const Duration(minutes: 15)),
    expiresAt: now.add(const Duration(hours: 2)),
    confidence: DataConfidence.official,
    summary: 'Datos de prueba',
  );

  test('closed route is not recommended', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: weather,
        officialAlert: false,
        routeClosed: true,
        exposureScore: 0,
        technicalDifficulty: 0,
        isolationScore: 0,
        petCompatible: true,
      ),
      now: now,
    );

    expect(result.status, RouteSafetyStatus.notRecommended);
  });

  test('official alert is not recommended', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: weather,
        officialAlert: true,
        routeClosed: false,
        exposureScore: 0,
        technicalDifficulty: 0,
        isolationScore: 0,
        petCompatible: true,
      ),
      now: now,
    );

    expect(result.status, RouteSafetyStatus.notRecommended);
  });

  test('elevated exposure produces caution', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: weather,
        officialAlert: false,
        routeClosed: false,
        exposureScore: 0.9,
        technicalDifficulty: 0.2,
        isolationScore: 0.2,
        petCompatible: true,
      ),
      now: now,
    );

    expect(result.status, RouteSafetyStatus.caution);
  });
}
