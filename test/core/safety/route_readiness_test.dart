import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/safety/route_readiness.dart';

void main() {
  const engine = RouteReadinessEngine();

  test('closed route is never marked apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(routeClosed: true, missingCriticalData: false),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.reasons, contains('La ruta figura como cerrada.'));
    expect(result.factors, contains(RouteReadinessFactor.officialClosure));
  });

  test('missing critical data produces precaucion by default', () {
    final result = engine.evaluate(const RouteReadinessInput());

    expect(result.status, RouteReadiness.precaucion);
    expect(result.reasons, isNotEmpty);
    expect(result.factors, contains(RouteReadinessFactor.missingCriticalData));
  });

  test('complete clean evidence can produce apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(missingCriticalData: false),
    );

    expect(result.status, RouteReadiness.apto);
    expect(result.reasons, isNotEmpty);
  });

  test('hard safety block wins while preserving all reasons', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        officialEvacuation: true,
        severeWeather: true,
        highExposure: true,
        missingCriticalData: true,
      ),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.reasons, contains('Existe una evacuación oficial activa.'));
    expect(result.factors, contains(RouteReadinessFactor.severeWeather));
    expect(result.factors, contains(RouteReadinessFactor.highExposure));
    expect(result.factors, contains(RouteReadinessFactor.missingCriticalData));
  });
}
