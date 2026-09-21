import '../../core/domain/outdoor_models.dart';

class PetRouteAssessment {
  const PetRouteAssessment({
    required this.level,
    required this.reasons,
    required this.checklist,
  });

  final OutdoorRiskLevel level;
  final List<String> reasons;
  final List<String> checklist;
}

class PetSafetyEngine {
  const PetSafetyEngine();

  PetRouteAssessment assess({
    required PetProfile pet,
    required double distanceKm,
    required double elevationGainMeters,
    required double temperatureC,
    required bool hasReliableWater,
    required bool hasShade,
  }) {
    final reasons = <String>[];
    final checklist = <String>[
      'Agua suficiente para la mascota',
      'Correa y elementos de control',
      'Protección frente a calor o frío',
      'Comprobar restricciones oficiales antes de salir',
    ];

    var level = OutdoorRiskLevel.low;
    if (temperatureC >= 30 && (!hasShade || !hasReliableWater)) {
      level = OutdoorRiskLevel.high;
      reasons.add('Calor elevado con sombra o agua insuficiente.');
    } else if (temperatureC >= 27 || elevationGainMeters >= 1000 || distanceKm >= 20) {
      level = OutdoorRiskLevel.caution;
      reasons.add('La combinación de condiciones puede aumentar la exigencia.');
    }

    if (pet.size.toLowerCase() == 'pequeño' && elevationGainMeters >= 700) {
      level = level.index > OutdoorRiskLevel.caution.index
          ? level
          : OutdoorRiskLevel.caution;
      reasons.add('Desnivel relevante para una mascota pequeña.');
    }

    return PetRouteAssessment(
      level: level,
      reasons: reasons,
      checklist: checklist,
    );
  }
}
