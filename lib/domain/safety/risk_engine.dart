import '../../core/contracts/platform_services.dart';

enum RouteSafetyStatus { suitable, caution, notRecommended }

final class RouteRiskInput {
  const RouteRiskInput({
    required this.weather,
    required this.officialAlert,
    required this.routeClosed,
    required this.exposureScore,
    required this.technicalDifficulty,
    required this.isolationScore,
    required this.petCompatible,
  });

  final WeatherSnapshot weather;
  final bool officialAlert;
  final bool routeClosed;
  final double exposureScore;
  final double technicalDifficulty;
  final double isolationScore;
  final bool petCompatible;
}

final class RouteSafetyAssessment {
  const RouteSafetyAssessment({
    required this.status,
    required this.reasons,
    required this.evaluatedAt,
  });

  final RouteSafetyStatus status;
  final List<String> reasons;
  final DateTime evaluatedAt;
}

/// Conservative deterministic first layer. Critical providers must feed this
/// engine; missing evidence never becomes an implicit approval.
final class RouteRiskEngine {
  const RouteRiskEngine();

  RouteSafetyAssessment assess(RouteRiskInput input, {DateTime? now}) {
    final evaluatedAt = now ?? DateTime.now().toUtc();
    final reasons = <String>[];
    var status = RouteSafetyStatus.suitable;

    if (input.routeClosed) {
      return RouteSafetyAssessment(
        status: RouteSafetyStatus.notRecommended,
        reasons: const ['La ruta figura como cerrada.'],
        evaluatedAt: evaluatedAt,
      );
    }

    if (input.officialAlert) {
      status = RouteSafetyStatus.notRecommended;
      reasons.add('Existe un aviso oficial activo que afecta al contexto evaluado.');
    }

    if (input.weather.expiresAt.isBefore(evaluatedAt)) {
      status = _max(status, RouteSafetyStatus.caution);
      reasons.add('La previsión disponible está caducada.');
    }

    if (input.exposureScore >= 0.8) {
      status = _max(status, RouteSafetyStatus.caution);
      reasons.add('La ruta presenta exposición elevada.');
    }

    if (input.technicalDifficulty >= 0.8) {
      status = _max(status, RouteSafetyStatus.caution);
      reasons.add('La dificultad técnica estimada es elevada.');
    }

    if (input.isolationScore >= 0.8) {
      status = _max(status, RouteSafetyStatus.caution);
      reasons.add('La ruta presenta aislamiento elevado.');
    }

    if (!input.petCompatible) {
      status = _max(status, RouteSafetyStatus.notRecommended);
      reasons.add('La ruta no es compatible con el perfil de mascota seleccionado.');
    }

    if (reasons.isEmpty) {
      reasons.add('No se han detectado factores de riesgo críticos en los datos disponibles.');
    }

    return RouteSafetyAssessment(
      status: status,
      reasons: reasons,
      evaluatedAt: evaluatedAt,
    );
  }

  RouteSafetyStatus _max(RouteSafetyStatus a, RouteSafetyStatus b) {
    const rank = <RouteSafetyStatus, int>{
      RouteSafetyStatus.suitable: 0,
      RouteSafetyStatus.caution: 1,
      RouteSafetyStatus.notRecommended: 2,
    };
    return rank[b]! > rank[a]! ? b : a;
  }
}
