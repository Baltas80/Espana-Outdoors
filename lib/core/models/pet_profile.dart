enum PetSize { small, medium, large }

class PetProfile {
  const PetProfile({
    required this.id,
    required this.name,
    required this.size,
    this.ageYears,
    this.needsFrequentWater = false,
    this.heatSensitive = false,
  });

  final String id;
  final String name;
  final PetSize size;
  final int? ageYears;
  final bool needsFrequentWater;
  final bool heatSensitive;
}
