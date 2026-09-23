import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/domain/risk/route_risk.dart';

void main() {
  const engine = RouteRiskEngine();

  test('returns apto when no active risk is reported', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 8,
      elevationGainM: 300,
      difficultyScore: 1,
    ));

    expect(result.readiness, RouteReadiness.apto);
    expect(result.score, 0);
  });

  test('returns precaucion for moderate live risk', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 8,
      elevationGainM: 500,
      difficultyScore: 2,
      weatherSeverity: 1,
      exposureScore: 1,
    ));

    expect(result.readiness, RouteReadiness.precaucion);
    expect(result.reasons, contains('Meteorología desfavorable'));
  });

  test('official closure is a hard stop', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 3,
      elevationGainM: 100,
      difficultyScore: 1,
      closureSeverity: 2,
    ));

    expect(result.readiness, RouteReadiness.noRecomendado);
    expect(result.reasons, contains('Cierre o restricción de acceso'));
  });

  test('active official severe signal is a hard stop', () {
    final result = engine.assess(RouteRiskInput(
      distanceKm: 3,
      elevationGainM: 100,
      difficultyScore: 1,
      signals: [
        RiskSignal(
          id: 'alert-1',
          label: 'Aviso oficial',
          severity: 2,
          sourceKind: RiskSourceKind.official,
          sourceName: 'Fuente oficial',
        ),
      ],
    ));

    expect(result.readiness, RouteReadiness.noRecomendado);
    expect(result.activeSignals, hasLength(1));
  });

  test('expired signals are ignored', () {
    final result = engine.assess(RouteRiskInput(
      distanceKm: 3,
      elevationGainM: 100,
      difficultyScore: 1,
      signals: [
        RiskSignal(
          id: 'expired',
          label: 'Aviso caducado',
          severity: 2,
          sourceKind: RiskSourceKind.official,
          expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
        ),
      ],
    ));

    expect(result.activeSignals, isEmpty);
    expect(result.readiness, RouteReadiness.apto);
  });
}
