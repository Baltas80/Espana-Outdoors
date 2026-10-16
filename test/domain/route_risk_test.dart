import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/domain/risk/route_risk.dart';

void main() {
  const engine = RouteRiskEngine();

  test('returns apto only when no active risk is reported and inputs are complete', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 8,
      elevationGainM: 300,
      difficultyScore: 1,
      dataCompleteness: 1,
    ));

    expect(result.readiness, RouteReadiness.apto);
    expect(result.score, 0);
  });

  test('incomplete data never produces apto', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 8,
      elevationGainM: 300,
      difficultyScore: 1,
      dataCompleteness: 0,
    ));

    expect(result.readiness, RouteReadiness.precaucion);
    expect(result.confidence, 0);
    expect(
      result.reasons,
      contains('Información incompleta: revisa las fuentes antes de salir'),
    );
  });

  test('returns precaucion for moderate live risk', () {
    final result = engine.assess(const RouteRiskInput(
      distanceKm: 8,
      elevationGainM: 500,
      difficultyScore: 2,
      weatherSeverity: 1,
      exposureScore: 1,
      dataCompleteness: 1,
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
      dataCompleteness: 1,
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
  test('assessment is deterministic for a fixed reference time', () {
    final reference = DateTime.utc(2026, 10, 16, 12);
    final input = RouteRiskInput(
      distanceKm: 5,
      elevationGainM: 200,
      difficultyScore: 1,
      dataCompleteness: 1,
      signals: [
        RiskSignal(
          id: 'expires',
          label: 'Aviso vigente',
          severity: 1,
          sourceKind: RiskSourceKind.espanaOutdoor,
          expiresAt: reference.add(const Duration(minutes: 30)),
        ),
      ],
    );

    final first = engine.assess(input, now: reference);
    final second = engine.assess(input, now: reference);

    expect(first.readiness, second.readiness);
    expect(first.score, second.score);
    expect(first.reasons, second.reasons);
    expect(first.activeSignals, hasLength(1));
    expect(
      engine.assess(input, now: reference.add(const Duration(hours: 1))).activeSignals,
      isEmpty,
    );
  });

  test('rejects invalid risk severity', () {
    expect(
      () => engine.assess(const RouteRiskInput(
        distanceKm: 5,
        elevationGainM: 200,
        difficultyScore: 1,
        closureSeverity: 3,
      )),
      throwsArgumentError,
    );
  });
}
