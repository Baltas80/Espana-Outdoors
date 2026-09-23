import 'package:espana_outdoors/core/contracts/platform_services.dart';
import 'package:espana_outdoors/domain/safety/risk_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 1, 1, 12);

  WeatherSnapshot weather({bool expired = false}) => WeatherSnapshot(
        observedAt: now.subtract(const Duration(hours: 1)),
        expiresAt: now.add(Duration(minutes: expired ? -1 : 30)),
        confidence: DataConfidence.official,
        summary: 'test',
      );

  test('closed route is never suitable', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: WeatherSnapshot(
          observedAt: DateTime.utc(2026, 1, 1, 11),
          expiresAt: DateTime.utc(2026, 1, 1, 12, 30),
          confidence: DataConfidence.official,
        ),
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

  test('expired weather prevents an implicit approval', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: weather(expired: true),
        officialAlert: false,
        routeClosed: false,
        exposureScore: 0,
        technicalDifficulty: 0,
        isolationScore: 0,
        petCompatible: true,
      ),
      now: now,
    );
    expect(result.status, RouteSafetyStatus.caution);
  });

  test('official alert dominates ordinary risk factors', () {
    final result = const RouteRiskEngine().assess(
      RouteRiskInput(
        weather: weather(),
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
}
