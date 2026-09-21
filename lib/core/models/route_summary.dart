class RouteSummary {
  const RouteSummary({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
    required this.durationMinutes,
    required this.difficulty,
    this.petFriendly = false,
    this.waterAvailable = false,
    this.offlineReady = false,
  });

  final String id;
  final String name;
  final double distanceKm;
  final double elevationGainM;
  final int durationMinutes;
  final String difficulty;
  final bool petFriendly;
  final bool waterAvailable;
  final bool offlineReady;
}
