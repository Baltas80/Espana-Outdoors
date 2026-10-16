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

  /// Returns whether this signal is active at a supplied instant.
  /// A signal is expired at the exact instant represented by [expiresAt].
  bool isActiveAt(DateTime referenceTime) =>
      expiresAt == null || expiresAt!.isAfter(referenceTime.toUtc());

  /// Convenience accessor for non-deterministic UI uses. The engine itself
  /// uses [isActiveAt] with a single captured reference instant.
  bool get isActive => isActiveAt(DateTime.now().toUtc());
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

  /// Normalized 0..3. This is a product classification, not a safety guarantee.
  final int difficultyScore;
  final int exposureScore;
  final int isolationScore;
  final int weatherSeverity;
  final int officialAlertSeverity;
  final int closureSeverity;
  final int fireSeverity;
  final int petRiskSeverity;
  final List<RiskSignal> signals;

  /// 0 = unknown/incomplete; 1 = all required inputs were evaluated.
  /// Completeness is separate from the risk score.
  final double dataCompleteness;

  /// Reject malformed inputs instead of silently clamping them.
  void validate() {
    if (!distanceKm.isFinite || distanceKm < 0) {
      throw ArgumentError.value(
        distanceKm,
        'distanceKm',
        'must be finite and non-negative',
      );
    }
    if (!elevationGainM.isFinite || elevationGainM < 0) {
      throw ArgumentError.value(
        elevationGainM,
        'elevationGainM',
        'must be finite and non-negative',
      );
    }

    _validateNormalizedScore(difficultyScore, 'difficultyScore');
    _validateNormalizedScore(exposureScore, 'exposureScore');
    _validateNormalizedScore(isolationScore, 'isolationScore');

    _validateSeverity(weatherSeverity, 'weatherSeverity');
    _validateSeverity(officialAlertSeverity, 'officialAlertSeverity');
    _validateSeverity(closureSeverity, 'closureSeverity');
    _validateSeverity(fireSeverity, 'fireSeverity');
    _validateSeverity(petRiskSeverity, 'petRiskSeverity');

    if (!dataCompleteness.isFinite ||
        dataCompleteness < 0 ||
        dataCompleteness > 1) {
      throw ArgumentError.value(
        dataCompleteness,
        'dataCompleteness',
        'must be in 0..1',
      );
    }

    for (final signal in signals) {
      _validateSeverity(signal.severity, 'signals.severity');
    }
  }

  static void _validateNormalizedScore(int value, String name) {
    if (value < 0 || value > 3) {
      throw ArgumentError.value(value, name, 'must be in 0..3');
    }
  }

  static void _validateSeverity(int value, String name) {
    if (value < 0 || value > 2) {
      throw ArgumentError.value(value, name, 'must be in 0..2');
    }
  }
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

/// Deterministic, auditable decision layer for route risk.
/// It never fabricates missing data and never claims that a route is safe.
final class RouteRiskEngine {
  const RouteRiskEngine();

  RouteRiskAssessment assess(RouteRiskInput input, {DateTime? now}) {
    input.validate();
    final evaluatedAt = (now ?? DateTime.now()).toUtc();
    final active = input.signals
        .where((signal) => signal.isActiveAt(evaluatedAt))
        .toList(growable: false);

    var score = 0;
    final reasons = <String>[];

    score += _weighted(
      input.weatherSeverity, 4, reasons, 'Meteorología desfavorable',
    );
    score += _weighted(
      input.officialAlertSeverity, 6, reasons, 'Aviso oficial activo',
    );
    score += _weighted(
      input.closureSeverity, 10, reasons, 'Cierre o restricción de acceso',
    );
    score += _weighted(input.fireSeverity, 8, reasons, 'Riesgo de incendio');
    score += _weighted(
      input.exposureScore, 2, reasons, 'Exposición de la ruta',
    );
    score += _weighted(
      input.isolationScore, 2, reasons, 'Aislamiento o acceso limitado',
    );
    score += _weighted(
      input.petRiskSeverity, 2, reasons, 'Riesgo adicional para mascota',
    );

    if (input.difficultyScore >= 3) {
      score += 3;
      reasons.add('Dificultad elevada');
    } else if (input.difficultyScore == 2) {
      score += 1;
      reasons.add('Dificultad moderada');
    }

    for (final signal in active) {
      score += signal.severity;
      reasons.add(
        signal.explanation?.isNotEmpty == true
            ? signal.explanation!
            : signal.label,
      );
    }

    final incompleteData = input.dataCompleteness < 1;
    if (incompleteData) {
      reasons.add('Información incompleta: revisa las fuentes antes de salir');
    }

    // Confirmed severe conditions remain hard stops.
    final hardStop = input.closureSeverity >= 2 ||
        input.officialAlertSeverity >= 2 ||
        input.fireSeverity >= 2 ||
        active.any(
          (signal) =>
              signal.severity >= 2 &&
              signal.sourceKind == RiskSourceKind.official,
        );

    final RouteReadiness readiness;
    if (hardStop || score >= 12) {
      readiness = RouteReadiness.noRecomendado;
    } else if (score >= 5 || incompleteData) {
      // Missing evidence is uncertainty, never evidence that a route is safe.
      readiness = RouteReadiness.precaucion;
    } else {
      readiness = RouteReadiness.apto;
    }

    return RouteRiskAssessment(
      readiness: readiness,
      score: score,
      reasons: List.unmodifiable(reasons),
      activeSignals: active,
      confidence: input.dataCompleteness,
    );
  }

  int _weighted(
    int severity,
    int weight,
    List<String> reasons,
    String label,
  ) {
    if (severity > 0) reasons.add(label);
    return severity * weight;
  }
}
