import 'package:espana_outdoors/core/domain/route_readiness.dart';
import 'package:espana_outdoors/core/domain/route_readiness_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RouteReadinessEngine();

  test('returns apto when no relevant risk is present', () {
    final result = engine.evaluate(const RouteReadinessInput());

    expect(result.decision, RouteReadinessDecision.apto);
    expect(result.reasons, isEmpty);
  });

  test('official closure always overrides other factors', () {
    final result = engine.evaluate(
      const RouteReadinessInput(officialClosure: true),
    );

    expect(result.decision, RouteReadinessDecision.noRecomendado);
    expect(result.factors, contains(RouteReadinessFactor.officialClosure));
  });

  test('official emergency alert always overrides lower risk inputs', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        officialEmergencyAlert: true,
        routeRiskLevel: 1,
        weatherRiskLevel: 1,
        hazardRiskLevel: 1,
      ),
    );

    expect(result.decision, RouteReadinessDecision.noRecomendado);
    expect(
      result.factors,
      contains(RouteReadinessFactor.officialEmergencyAlert),
    );
  });

  test('critical hazard yields no recomendado', () {
    final result = engine.evaluate(
      const RouteReadinessInput(hazardRiskLevel: 3),
    );

    expect(result.decision, RouteReadinessDecision.noRecomendado);
  });

  test('combined severe weather and elevated route risk yields no recomendado', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        severeWeather: true,
        routeRiskLevel: 2,
      ),
    );

    expect(result.decision, RouteReadinessDecision.noRecomendado);
  });

  test('moderate weather risk yields precaucion with evidence', () {
    final result = engine.evaluate(
      const RouteReadinessInput(weatherRiskLevel: 1),
    );

    expect(result.decision, RouteReadinessDecision.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.weatherRisk));
    expect(result.reasons, isNotEmpty);
  });

  test('stale information never upgrades a route to apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(informationStale: true),
    );

    expect(result.decision, RouteReadinessDecision.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.staleInformation));
  });

  test('invalid risk scores are rejected', () {
    expect(
      () => engine.evaluate(const RouteReadinessInput(routeRiskLevel: 4)),
      throwsArgumentError,
    );
  });
}
