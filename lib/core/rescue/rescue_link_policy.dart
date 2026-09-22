enum RescueLinkState { idle, preparing, active, cancelled, expired }

enum RescueVisibility { anonymous, approximateLocation, preciseLocation }

class RescueLinkPolicy {
  const RescueLinkPolicy({
    this.radiusMeters = 3000,
    this.ttl = const Duration(minutes: 15),
    this.cooldown = const Duration(minutes: 10),
    this.maxResponders = 5,
    this.visibility = RescueVisibility.approximateLocation,
  });

  final double radiusMeters;
  final Duration ttl;
  final Duration cooldown;
  final int maxResponders;
  final RescueVisibility visibility;

  bool get isValid =>
      radiusMeters > 0 &&
      ttl.inMinutes >= 1 &&
      cooldown.inMinutes >= 1 &&
      maxResponders >= 1;
}

class RescueLinkAlert {
  const RescueLinkAlert({
    required this.id,
    required this.createdAt,
    required this.expiresAt,
    required this.policy,
    required this.latitude,
    required this.longitude,
    this.state = RescueLinkState.preparing,
  });

  final String id;
  final DateTime createdAt;
  final DateTime expiresAt;
  final RescueLinkPolicy policy;
  final double latitude;
  final double longitude;
  final RescueLinkState state;

  bool get expired => DateTime.now().isAfter(expiresAt);
}
