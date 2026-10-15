import 'package:espana_outdoors/core/safety/route_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = RouteReadinessEngine();

  test('complete clean evidence returns apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(missingCriticalData: false),
    );

    expect(result.status, RouteReadiness.apto);
    expect(result.reasons, isNotEmpty);
    expect(result.factors, isEmpty);
  });

  test('incomplete evidence defaults to precaucion', () {
    final result = engine.evaluate(const RouteReadinessInput());

    expect(result.status, RouteReadiness.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.missingCriticalData));
  });

  test('official closure overrides all other factors', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        routeClosed: true,
        severeWeather: true,
        highExposure: true,
        missingCriticalData: true,
      ),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.factors, contains(RouteReadinessFactor.officialClosure));
    expect(result.factors, contains(RouteReadinessFactor.severeWeather));
    expect(result.factors, contains(RouteReadinessFactor.highExposure));
  });

  test('official evacuation and critical alert are hard blocks', () {
    for (final input in [
      const RouteReadinessInput(
        officialEvacuation: true,
        missingCriticalData: false,
      ),
      const RouteReadinessInput(
        criticalOfficialAlert: true,
        missingCriticalData: false,
      ),
    ]) {
      expect(engine.evaluate(input).status, RouteReadiness.noRecomendado);
    }
  });

  test('critical risk scores are hard blocks', () {
    for (final input in [
      const RouteReadinessInput(routeRiskLevel: 3, missingCriticalData: false),
      const RouteReadinessInput(weatherRiskLevel: 3, missingCriticalData: false),
      const RouteReadinessInput(hazardRiskLevel: 3, missingCriticalData: false),
    ]) {
      expect(engine.evaluate(input).status, RouteReadiness.noRecomendado);
    }
  });

  test('severe weather combined with elevated route or hazard risk blocks', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        severeWeather: true,
        routeRiskLevel: 2,
        missingCriticalData: false,
      ),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.factors, contains(RouteReadinessFactor.routeRisk));
  });

  test('moderate weather risk returns precaution with an explanation', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        weatherRiskLevel: 1,
        missingCriticalData: false,
      ),
    );

    expect(result.status, RouteReadiness.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.weatherRisk));
    expect(result.reasons, isNotEmpty);
  });

  test('stale information never returns apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        staleData: true,
        missingCriticalData: false,
      ),
    );

    expect(result.status, RouteReadiness.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.staleData));
  });

  test('pet heat risk is visible in factors and reasons', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        petHeatRisk: true,
        missingCriticalData: false,
      ),
    );

    expect(result.status, RouteReadiness.precaucion);
    expect(result.factors, contains(RouteReadinessFactor.petHeatRisk));
    expect(result.reasons, isNotEmpty);
  });

  test('invalid risk scores are rejected', () {
    expect(
      () => engine.evaluate(
        const RouteReadinessInput(routeRiskLevel: 4, missingCriticalData: false),
      ),
      throwsArgumentError,
    );
  });
}
