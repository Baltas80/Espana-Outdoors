import 'package:espana_outdoors/core/safety/route_readiness.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const evaluator = RouteReadinessEvaluator();

  ReadinessFactor factor(ReadinessFactorLevel level) => ReadinessFactor(
        id: level.name,
        label: level.name,
        level: level,
        reason: 'fixture',
        source: 'test',
      );

  test('clear factors produce suitable', () {
    final result = evaluator.evaluate([
      factor(ReadinessFactorLevel.clear),
    ]);

    expect(result.result, RouteReadiness.suitable);
  });

  test('caution dominates clear factors', () {
    final result = evaluator.evaluate([
      factor(ReadinessFactorLevel.clear),
      factor(ReadinessFactorLevel.caution),
    ]);

    expect(result.result, RouteReadiness.caution);
    expect(result.actionableFactors, hasLength(1));
  });

  test('blocker dominates all other factors', () {
    final result = evaluator.evaluate([
      factor(ReadinessFactorLevel.caution),
      factor(ReadinessFactorLevel.blocker),
      factor(ReadinessFactorLevel.clear),
    ]);

    expect(result.result, RouteReadiness.notRecommended);
  });
}
