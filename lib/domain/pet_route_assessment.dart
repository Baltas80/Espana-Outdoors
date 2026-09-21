enum PetRouteRisk { low, moderate, high, unknown }

class PetRouteAssessment {
  const PetRouteAssessment({
    required this.risk,
    required this.reasons,
  });

  final PetRouteRisk risk;
  final List<String> reasons;
}

PetRouteAssessment assessPetRoute({
  required double distanceKm,
  required int elevationGainM,
  required double temperatureC,
  required bool waterAvailable,
}) {
  final reasons = <String>[];
  var score = 0;

  if (distanceKm > 15) {
    score += 2;
    reasons.add('Distancia elevada para una salida con mascota.');
  } else if (distanceKm > 10) {
    score += 1;
    reasons.add('Distancia moderada-alta.');
  }

  if (elevationGainM > 800) {
    score += 2;
    reasons.add('Desnivel acumulado elevado.');
  } else if (elevationGainM > 500) {
    score += 1;
    reasons.add('Desnivel significativo.');
  }

  if (temperatureC >= 32) {
    score += 3;
    reasons.add('Temperatura potencialmente peligrosa para mascotas.');
  } else if (temperatureC >= 28) {
    score += 2;
    reasons.add('Temperatura elevada: priorizar sombra, pausas y agua.');
  }

  if (!waterAvailable) {
    score += 1;
    reasons.add('No consta disponibilidad de agua en la ruta.');
  }

  final risk = score >= 4
      ? PetRouteRisk.high
      : score >= 2
          ? PetRouteRisk.moderate
          : PetRouteRisk.low;

  return PetRouteAssessment(risk: risk, reasons: reasons);
}
