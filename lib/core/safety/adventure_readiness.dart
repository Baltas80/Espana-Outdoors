/// Conservative route-day readiness model.
///
/// This evaluator only acts on explicit, provider-backed signals. Missing data
/// never becomes an implicit "safe" result.
library;

enum AdventureReadiness {
  suitable,
  caution,
  notRecommended,
  insufficientData,
}

class RouteDayInputs {
  const RouteDayInputs({
    this.officialWarning = false,
    this.routeClosed = false,
    this.highWeatherRisk = false,
    this.routeProblem = false,
    this.petRestriction = false,
    this.missingCriticalData = false,
  });

  final bool officialWarning;
  final bool routeClosed;
  final bool highWeatherRisk;
  final bool routeProblem;
  final bool petRestriction;
  final bool missingCriticalData;
}

class AdventureReadinessResult {
  const AdventureReadinessResult({
    required this.status,
    required this.reasons,
  });

  final AdventureReadiness status;
  final List<String> reasons;
}

class AdventureReadinessEvaluator {
  const AdventureReadinessEvaluator();

  AdventureReadinessResult evaluate(RouteDayInputs inputs) {
    final reasons = <String>[];

    if (inputs.routeClosed) {
      reasons.add('La ruta figura como cerrada.');
    }
    if (inputs.officialWarning) {
      reasons.add('Existe un aviso oficial aplicable.');
    }
    if (inputs.highWeatherRisk) {
      reasons.add('Las condiciones meteorológicas disponibles elevan el riesgo.');
    }
    if (inputs.routeProblem) {
      reasons.add('Existe un problema conocido en la ruta.');
    }
    if (inputs.petRestriction) {
      reasons.add('Existe una restricción relevante para mascotas.');
    }

    if (inputs.routeClosed || inputs.officialWarning) {
      return AdventureReadinessResult(
        status: AdventureReadiness.notRecommended,
        reasons: List.unmodifiable(reasons),
      );
    }

    if (inputs.highWeatherRisk || inputs.routeProblem || inputs.petRestriction) {
      return AdventureReadinessResult(
        status: AdventureReadiness.caution,
        reasons: List.unmodifiable(reasons),
      );
    }

    if (inputs.missingCriticalData) {
      return const AdventureReadinessResult(
        status: AdventureReadiness.insufficientData,
        reasons: ['Faltan datos críticos para evaluar la salida.'],
      );
    }

    return const AdventureReadinessResult(
      status: AdventureReadiness.suitable,
      reasons: ['No se han detectado señales críticas con los datos disponibles.'],
    );
  }
}
