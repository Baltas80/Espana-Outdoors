enum RouteReadiness {
  apto,
  precaucion,
  noRecomendado,
}

/// Evidence used by the route-readiness decision. Null means that the source
/// has not supplied a value; it must never be interpreted as "safe".
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
    this.missingCriticalData = false,
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
}

class RouteReadinessResult {
  const RouteReadinessResult({
    required this.status,
    required this.reasons,
  });

  final RouteReadiness status;
  final List<String> reasons;
}

/// Deterministic product policy for "¿PUEDO HACER ESTA RUTA HOY?".
///
/// This layer only evaluates supplied evidence. It does not fetch weather,
/// alerts or closures and therefore cannot fabricate a safety assessment.
class RouteReadinessEngine {
  const RouteReadinessEngine();

  RouteReadinessResult evaluate(RouteReadinessInput input) {
    final reasons = <String>[];

    if (input.routeClosed) {
      reasons.add('La ruta figura como cerrada.');
    }
    if (input.officialEvacuation) {
      reasons.add('Existe una evacuación oficial activa.');
    }
    if (input.criticalOfficialAlert) {
      reasons.add('Existe una alerta oficial crítica aplicable a la zona.');
    }

    if (reasons.isNotEmpty) {
      return RouteReadinessResult(
        status: RouteReadiness.noRecomendado,
        reasons: List.unmodifiable(reasons),
      );
    }

    if (input.severeWeather) {
      reasons.add('Las condiciones meteorológicas requieren precaución.');
    }
    if (input.highExposure) {
      reasons.add('La ruta presenta exposición elevada.');
    }
    if (input.highIsolation) {
      reasons.add('La ruta presenta aislamiento elevado.');
    }
    if (input.petRestricted) {
      reasons.add('Existen restricciones aplicables a mascotas.');
    }
    if (input.petHeatRisk) {
      reasons.add('Las condiciones térmicas elevan el riesgo para mascotas.');
    }
    if (input.staleData) {
      reasons.add('Parte de la información disponible está desactualizada.');
    }
    if (input.missingCriticalData) {
      reasons.add('Faltan datos críticos para una evaluación completa.');
    }

    if (reasons.isNotEmpty) {
      return RouteReadinessResult(
        status: RouteReadiness.precaucion,
        reasons: List.unmodifiable(reasons),
      );
    }

    return const RouteReadinessResult(
      status: RouteReadiness.apto,
      reasons: ['No se han detectado impedimentos con los datos disponibles.'],
    );
  }
}
