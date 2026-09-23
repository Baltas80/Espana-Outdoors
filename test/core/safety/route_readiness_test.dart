import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/safety/route_readiness.dart';

void main() {
  const engine = RouteReadinessEngine();

  test('closed route is never marked apto', () {
    final result = engine.evaluate(
      const RouteReadinessInput(routeClosed: true),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.reasons, contains('La ruta figura como cerrada.'));
  });

  test('missing critical data produces precaucion', () {
    final result = engine.evaluate(
      const RouteReadinessInput(missingCriticalData: true),
    );

    expect(result.status, RouteReadiness.precaucion);
    expect(result.reasons, isNotEmpty);
  });

  test('clean evidence can produce apto', () {
    final result = engine.evaluate(const RouteReadinessInput());

    expect(result.status, RouteReadiness.apto);
    expect(result.reasons, isNotEmpty);
  });

  test('hard safety block wins over caution signals', () {
    final result = engine.evaluate(
      const RouteReadinessInput(
        officialEvacuation: true,
        severeWeather: true,
        highExposure: true,
      ),
    );

    expect(result.status, RouteReadiness.noRecomendado);
    expect(result.reasons, hasLength(1));
  });
}
