import 'route_readiness.dart';

/// Evaluates route readiness from supplied evidence.
///
/// Safety-critical overrides are intentionally conservative:
/// an official closure or official emergency alert always yields
/// `noRecomendado`. The engine never claims that a route is safe.
class RouteReadinessEngine {
  const RouteReadinessEngine();

  RouteReadinessResult evaluate(RouteReadinessInput input) {
    if (!input.isValid) {
      throw ArgumentError.value(input, 'input', 'Factores de riesgo inválidos.');
    }

    final factors = <RouteReadinessFactor>[];
    final reasons = <String>[];

    if (input.officialClosure) {
      factors.add(RouteReadinessFactor.officialClosure);
      reasons.add('Existe un cierre oficial vigente.');
    }

    if (input.officialEmergencyAlert) {
      factors.add(RouteReadinessFactor.officialEmergencyAlert);
      reasons.add('Existe una alerta oficial de emergencia aplicable.');
    }

    if (input.severeWeather) {
      factors.add(RouteReadinessFactor.severeWeather);
      reasons.add('Se han identificado condiciones meteorológicas adversas.');
    }

    if (input.hazardRiskLevel >= 2) {
      factors.add(RouteReadinessFactor.activeHazard);
      reasons.add('Hay peligros activos con riesgo relevante.');
    }

    if (input.poorVisibility) {
      factors.add(RouteReadinessFactor.poorVisibility);
      reasons.add('La visibilidad disponible es desfavorable.');
    }

    if (input.extremeHeatOrCold) {
      factors.add(RouteReadinessFactor.extremeHeatOrCold);
      reasons.add('Se han detectado temperaturas extremas o condiciones térmicas relevantes.');
    }

    if (input.routeRiskLevel >= 2) {
      factors.add(RouteReadinessFactor.routeRisk);
      reasons.add('La propia ruta presenta un nivel de riesgo elevado.');
    }

    if (input.petRestriction || !input.petCompatible) {
      factors.add(RouteReadinessFactor.petRestriction);
      reasons.add('La ruta no es compatible con el perfil o las restricciones de la mascota seleccionada.');
    }

    if (input.informationStale) {
      factors.add(RouteReadinessFactor.staleInformation);
      reasons.add('Parte de la información disponible está desactualizada; comprueba las fuentes antes de salir.');
    }

    if (input.officialClosure || input.officialEmergencyAlert) {
      return RouteReadinessResult(
        decision: RouteReadinessDecision.noRecomendado,
        factors: List.unmodifiable(factors),
        reasons: List.unmodifiable(reasons),
      );
    }

    final criticalConditions = input.hazardRiskLevel >= 3 ||
        input.weatherRiskLevel >= 3 ||
        input.routeRiskLevel >= 3;

    if (criticalConditions ||
        (input.severeWeather && input.routeRiskLevel >= 2) ||
        (input.severeWeather && input.hazardRiskLevel >= 2)) {
      return RouteReadinessResult(
        decision: RouteReadinessDecision.noRecomendado,
        factors: List.unmodifiable(factors),
        reasons: List.unmodifiable(reasons),
      );
    }

    final cautionConditions = input.weatherRiskLevel >= 1 ||
        input.hazardRiskLevel >= 1 ||
        input.routeRiskLevel >= 1 ||
        input.severeWeather ||
        input.poorVisibility ||
        input.extremeHeatOrCold ||
        input.petRestriction ||
        !input.petCompatible ||
        input.informationStale;

    return RouteReadinessResult(
      decision: cautionConditions
          ? RouteReadinessDecision.precaucion
          : RouteReadinessDecision.apto,
      factors: List.unmodifiable(factors),
      reasons: List.unmodifiable(reasons),
    );
  }
}
