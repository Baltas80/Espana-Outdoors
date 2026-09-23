import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/domain/risk/route_risk.dart';

void main() {
  const engine = RouteRiskEngine();

  test('does not claim high confidence when source data is incomplete', () {
    final assessment = engine.assess(
      const RouteRiskInput(
        distanceKm: 10,
        elevationGainM: 500,
        difficultyScore: 2,
      ),
    );

    expect(assessment.confidence, 0);
    expect(
      assessment.reasons,
      contains('Información incompleta: revisa las fuentes antes de salir'),
    );
  });

  test('uses verified completeness independently from risk score', () {
    final assessment = engine.assess(
      const RouteRiskInput(
        distanceKm: 10,
        elevationGainM: 500,
        difficultyScore: 1,
        dataCompleteness: 1,
      ),
    );

    expect(assessment.confidence, 1);
    expect(assessment.readiness, RouteReadiness.apto);
  });
}
