enum RouteReadiness {
  apto,
  precaucion,
  noRecomendado,
}

/// Evidence categories surfaced to the UI so the decision is explainable.
enum RouteReadinessFactor {
  officialClosure,
  officialEvacuation,
  criticalOfficialAlert,
  severeWeather,
  weatherRisk,
  activeHazard,
  poorVisibility,
  extremeHeatOrCold,
  routeRisk,
  highExposure,
  highIsolation,
  petRestriction,
  petHeatRisk,
  staleData,
  missingCriticalData,
}

/// Evidence used by the route-readiness decision.
///
/// Unknown critical data defaults to an incomplete assessment. Callers must
/// explicitly set [missingCriticalData] to false only when the required inputs
/// have been checked. A missing source must never be interpreted as safe.
class RouteReadinessInput {
  const RouteReadinessInput({
    this.routeClosed = false,
    this.officialEvacuation = false,
    this.criticalOfficialAlert = false,
    this.severeWeather = false,
    this.highExposure = false,
    this.highIsolation = false,
    this.petRestricted = false,
    this.petHeatRisk = false,
    this.staleData = false,
    this.missingCriticalData = true,
    this.routeRiskLevel = 0,
    this.weatherRiskLevel = 0,
    this.hazardRiskLevel = 0,
    this.poorVisibility = false,
    this.extremeHeatOrCold = false,
  });

  final bool routeClosed;
  final bool officialEvacuation;
  final bool criticalOfficialAlert;
  final bool severeWeather;
  final bool highExposure;
  final bool highIsolation;
  final bool petRestricted;
  final bool petHeatRisk;
  final bool staleData;
  final bool missingCriticalData;

  /// Normalised risk scores: 0 (none) through 3 (critical).
  final int routeRiskLevel;
  final int weatherRiskLevel;
  final int hazardRiskLevel;
  final bool poorVisibility;
  final bool extremeHeatOrCold;

  bool get isValid =>
      _validScore(routeRiskLevel) &&
      _validScore(weatherRiskLevel) &&
      _validScore(hazardRiskLevel);

  static bool _validScore(int value) => value >= 0 && value <= 3;
}

class RouteReadinessResult {
  const RouteReadinessResult({
    required this.status,
    required this.reasons,
    this.factors = const [],
  });

  final RouteReadiness status;
  final List<String> reasons;
  final List<RouteReadinessFactor> factors;
}

/// Deterministic product policy for "¿PUEDO HACER ESTA RUTA HOY?".
///
/// This layer only evaluates supplied evidence. It does not fetch weather,
/// alerts or closures and cannot fabricate a safety assessment.
class RouteReadinessEngine {
  const RouteReadinessEngine();

  RouteReadinessResult evaluate(RouteReadinessInput input) {
    if (!input.isValid) {
      throw ArgumentError.value(
        input,
        'input',
        'Los factores de riesgo deben estar entre 0 y 3.',
      );
    }

    final reasons = <String>[];
    final factors = <RouteReadinessFactor>[];

    void add(RouteReadinessFactor factor, String reason) {
      factors.add(factor);
      reasons.add(reason);
    }

    if (input.routeClosed) {
      add(RouteReadinessFactor.officialClosure, 'La ruta figura como cerrada.');
    }
    if (input.officialEvacuation) {
      add(
        RouteReadinessFactor.officialEvacuation,
        'Existe una evacuación oficial activa.',
      );
    }
    if (input.criticalOfficialAlert) {
      add(
        RouteReadinessFactor.criticalOfficialAlert,
        'Existe una alerta oficial crítica aplicable a la zona.',
      );
    }
    if (input.weatherRiskLevel >= 1) {
      add(
        RouteReadinessFactor.weatherRisk,
        'La información meteorológica indica un nivel de riesgo relevante.',
      );
    }
    if (input.severeWeather) {
      add(
        RouteReadinessFactor.severeWeather,
        'Se han identificado condiciones meteorológicas adversas.',
      );
    }
    if (input.hazardRiskLevel >= 1) {
      add(
        RouteReadinessFactor.activeHazard,
        'Hay información de peligros que requiere precaución.',
      );
    }
    if (input.poorVisibility) {
      add(
        RouteReadinessFactor.poorVisibility,
        'La visibilidad disponible es desfavorable.',
      );
    }
    if (input.extremeHeatOrCold) {
      add(
        RouteReadinessFactor.extremeHeatOrCold,
        'Se han detectado temperaturas extremas o condiciones térmicas relevantes.',
      );
    }
    if (input.routeRiskLevel >= 1) {
      add(
        RouteReadinessFactor.routeRisk,
        'La propia ruta presenta factores de dificultad o riesgo que requieren atención.',
      );
    }
    if (input.highExposure) {
      add(
        RouteReadinessFactor.highExposure,
        'La ruta presenta exposición elevada.',
      );
    }
    if (input.highIsolation) {
      add(
        RouteReadinessFactor.highIsolation,
        'La ruta presenta aislamiento elevado.',
      );
    }
    if (input.petRestricted) {
      add(
        RouteReadinessFactor.petRestriction,
        'Existen restricciones aplicables a mascotas.',
      );
    }
    if (input.petHeatRisk) {
      add(
        RouteReadinessFactor.petHeatRisk,
        'Las condiciones térmicas elevan el riesgo para mascotas.',
      );
    }
    if (input.staleData) {
      add(
        RouteReadinessFactor.staleData,
        'Parte de la información disponible está desactualizada; comprueba las fuentes antes de salir.',
      );
    }
    if (input.missingCriticalData) {
      add(
        RouteReadinessFactor.missingCriticalData,
        'Faltan datos críticos para una evaluación completa.',
      );
    }

    final hardBlock = input.routeClosed ||
        input.officialEvacuation ||
        input.criticalOfficialAlert;
    final criticalRisk = input.routeRiskLevel >= 3 ||
        input.weatherRiskLevel >= 3 ||
        input.hazardRiskLevel >= 3;
    final combinedSevereRisk = input.severeWeather &&
        (input.routeRiskLevel >= 2 || input.hazardRiskLevel >= 2);

    final status = hardBlock || criticalRisk || combinedSevereRisk
        ? RouteReadiness.noRecomendado
        : reasons.isNotEmpty
            ? RouteReadiness.precaucion
            : RouteReadiness.apto;

    if (reasons.isEmpty) {
      reasons.add('No se han detectado impedimentos con los datos disponibles.');
    }

    return RouteReadinessResult(
      status: status,
      reasons: List.unmodifiable(reasons),
      factors: List.unmodifiable(factors),
    );
  }
}
