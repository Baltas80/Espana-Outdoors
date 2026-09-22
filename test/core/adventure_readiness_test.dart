import 'package:espana_outdoors/core/safety/adventure_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = AdventureReadinessEvaluator();

  test('closed route is not recommended', () {
    final result = evaluator.evaluate(const RouteDayInputs(routeClosed: true));

    expect(result.status, AdventureReadiness.notRecommended);
    expect(result.reasons, contains('La ruta figura como cerrada.'));
  });

  test('high weather risk produces caution', () {
    final result = evaluator.evaluate(const RouteDayInputs(highWeatherRisk: true));

    expect(result.status, AdventureReadiness.caution);
  });

  test('missing critical data is never treated as safe', () {
    final result = evaluator.evaluate(const RouteDayInputs(missingCriticalData: true));

    expect(result.status, AdventureReadiness.insufficientData);
  });
}
