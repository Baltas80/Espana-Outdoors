enum RouteReadiness { apto, precaucion, noRecomendado }

enum RiskSourceKind { official, espanaOutdoor, community }

class RiskSignal {
  const RiskSignal({
    required this.id,
    required this.label,
    required this.severity,
    required this.sourceKind,
    this.sourceName,
    this.explanation,
    this.expiresAt,
  });

  final String id;
  final String label;
  /// 0 = no material risk, 1 = caution, 2 = severe.
  final int severity;
  final RiskSourceKind sourceKind;
  final String? sourceName;
  final String? explanation;
  final DateTime? expiresAt;

  bool get isActive =>
      expiresAt == null || expiresAt!.isAfter(DateTime.now().toUtc());
}

class RouteRiskInput {
  const RouteRiskInput({
    required this.distanceKm,
    required this.elevationGainM,
    required this.difficultyScore,
    this.exposureScore = 0,
    this.isolationScore = 0,
    this.weatherSeverity = 0,
    this.officialAlertSeverity = 0,
    this.closureSeverity = 0,
    this.fireSeverity = 0,
    this.petRiskSeverity = 0,
    this.signals = const <RiskSignal>[],
    this.dataCompleteness = 0,
  });

  final double distanceKm;
  final double elevationGainM;
  /// Normalized 0..3. This is a product classification, not a medical/safety guarantee.
  final int difficultyScore;
  final int exposureScore;
  final int isolationScore;
  final int weatherSeverity;
  final int officialAlertSeverity;
  final int closureSeverity;
  final int fireSeverity;
  final int petRiskSeverity;
  final List<RiskSignal> signals;

  /// Completeness of the verified inputs available for this assessment.
  /// 0 means unknown/incomplete; 1 means all required inputs were evaluated.
  /// This is deliberately separate from the risk score.
  final double dataCompleteness;
}

class RouteRiskAssessment {
  const RouteRiskAssessment({
    required this.readiness,
    required this.score,
    required this.reasons,
    required this.activeSignals,
    required this.confidence,
  });

  final RouteReadiness readiness;
  final int score;
  final List<String> reasons;
  final List<RiskSignal> activeSignals;
  /// 0..1. Confidence describes data completeness/quality, not safety.
  final double confidence;

  String get headline {
    switch (readiness) {
      case RouteReadiness.apto:
        return 'APTO';
      case RouteReadiness.precaucion:
        return 'PRECAUCIÓN';
      case RouteReadiness.noRecomendado:
        return 'NO RECOMENDADO';
    }
  }
}

/// Deterministic, auditable decision layer for "¿PUEDO HACER ESTA RUTA HOY?".
/// It never fabricates missing data and never claims that a route is safe.
class RouteRiskEngine {
  const RouteRiskEngine();

  RouteRiskAssessment assess(RouteRiskInput input) {
    final active = input.signals.where((signal) => signal.isActive).toList(growable: false);
    var score = 0;
    final reasons = <String>[];

    score += _weighted(input.weatherSeverity, 4, reasons, 'Meteorología desfavorable');
    score += _weighted(input.officialAlertSeverity, 6, reasons, 'Aviso oficial activo');
    score += _weighted(input.closureSeverity, 10, reasons, 'Cierre o restricción de acceso');
    score += _weighted(input.fireSeverity, 8, reasons, 'Riesgo de incendio');
    score += _weighted(input.exposureScore, 2, reasons, 'Exposición de la ruta');
    score += _weighted(input.isolationScore, 2, reasons, 'Aislamiento o acceso limitado');
    score += _weighted(input.petRiskSeverity, 2, reasons, 'Riesgo adicional para mascota');

    if (input.difficultyScore >= 3) {
      score += 3;
      reasons.add('Dificultad elevada');
    } else if (input.difficultyScore == 2) {
      score += 1;
      reasons.add('Dificultad moderada');
    }

    for (final signal in active) {
      score += signal.severity.clamp(0, 2);
      if (signal.explanation?.isNotEmpty == true) {
        reasons.add(signal.explanation!);
      } else {
        reasons.add(signal.label);
      }
    }

    if (input.dataCompleteness < 1) {
      reasons.add('Información incompleta: revisa las fuentes antes de salir');
    }

    // A confirmed closure or severe official/fire signal always wins.
    final hardStop = input.closureSeverity >= 2 ||
        input.officialAlertSeverity >= 2 ||
        input.fireSeverity >= 2 ||
        active.any((signal) =>
            signal.severity >= 2 && signal.sourceKind == RiskSourceKind.official);

    final readiness = hardStop || score >= 12
        ? RouteReadiness.noRecomendado
        : score >= 5
            ? RouteReadiness.precaucion
            : RouteReadiness.apto;

    return RouteRiskAssessment(
      readiness: readiness,
      score: score,
      reasons: List.unmodifiable(reasons),
      activeSignals: active,
      confidence: input.dataCompleteness.clamp(0.0, 1.0),
    );
  }

  int _weighted(int severity, int weight, List<String> reasons, String label) {
    final normalized = severity.clamp(0, 3);
    if (normalized > 0) reasons.add(label);
    return normalized * weight;
  }
}
