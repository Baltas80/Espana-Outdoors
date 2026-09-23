/// Deterministic domain model for the "¿Puedo hacer esta ruta hoy?" decision.
///
/// This layer deliberately contains no network, UI or AI dependencies. It only
/// evaluates facts already supplied by trusted adapters and labels estimates
/// as such. It is not a guarantee of safety.
library;

enum RouteReadinessDecision { apto, precaucion, noRecomendado }

enum RouteReadinessFactor {
  officialClosure,
  officialEmergencyAlert,
  weatherRisk,
  severeWeather,
  activeHazard,
  poorVisibility,
  extremeHeatOrCold,
  routeRisk,
  petRestriction,
  staleInformation,
}

class RouteReadinessInput {
  const RouteReadinessInput({
    this.routeRiskLevel = 0,
    this.weatherRiskLevel = 0,
    this.hazardRiskLevel = 0,
    this.petCompatible = true,
    this.petRestriction = false,
    this.officialClosure = false,
    this.officialEmergencyAlert = false,
    this.severeWeather = false,
    this.poorVisibility = false,
    this.extremeHeatOrCold = false,
    this.informationStale = false,
  });

  /// Normalised scores from 0 (none) to 3 (extreme/critical).
  final int routeRiskLevel;
  final int weatherRiskLevel;
  final int hazardRiskLevel;
  final bool petCompatible;
  final bool petRestriction;
  final bool officialClosure;
  final bool officialEmergencyAlert;
  final bool severeWeather;
  final bool poorVisibility;
  final bool extremeHeatOrCold;
  final bool informationStale;

  bool get isValid =>
      _validScore(routeRiskLevel) &&
      _validScore(weatherRiskLevel) &&
      _validScore(hazardRiskLevel);

  static bool _validScore(int value) => value >= 0 && value <= 3;
}

class RouteReadinessResult {
  const RouteReadinessResult({
    required this.decision,
    required this.factors,
    required this.reasons,
  });

  final RouteReadinessDecision decision;
  final List<RouteReadinessFactor> factors;
  final List<String> reasons;

  bool get isActionable => reasons.isNotEmpty;
}
