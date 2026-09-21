class OutdoorRoute {
  const OutdoorRoute({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
    required this.durationMinutes,
    required this.difficulty,
    this.petFriendly = false,
    this.offlineReady = false,
  });

  final String id;
  final String name;
  final double distanceKm;
  final int elevationGainM;
  final int durationMinutes;
  final String difficulty;
  final bool petFriendly;
  final bool offlineReady;
}
