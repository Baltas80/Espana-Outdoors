import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/features/pets/pet_safety.dart';

void main() {
  const engine = PetSafetyEngine();
  const pet = PetProfile(id: 'luna', name: 'Luna', size: 'mediano');

  test('flags heat without shade or water as high risk', () {
    final result = engine.assess(
      pet: pet,
      distanceKm: 8,
      elevationGainMeters: 300,
      temperatureC: 32,
      hasReliableWater: false,
      hasShade: false,
    );

    expect(result.level, OutdoorRiskLevel.high);
    expect(result.reasons, isNotEmpty);
  });

  test('keeps moderate route at caution under demanding conditions', () {
    final result = engine.assess(
      pet: pet,
      distanceKm: 10,
      elevationGainMeters: 800,
      temperatureC: 27,
      hasReliableWater: true,
      hasShade: true,
    );

    expect(result.level, OutdoorRiskLevel.caution);
  });
}
