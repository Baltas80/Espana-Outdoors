import '../contracts/platform_services.dart';

enum RescueLinkState { idle, preparing, active, accepted, cancelled, expired }

enum RescueRole { officialService, trustedContact, volunteer, verifiedProfessional }

/// Privacy policy for Rescue Link. Discovery starts with approximate location;
/// exact/temporary location is bounded by an explicit accepted session.
final class RescueLinkPolicy {
  const RescueLinkPolicy({
    this.radiusMeters = 3000,
    this.ttl = const Duration(minutes: 15),
    this.cooldown = const Duration(minutes: 10),
    this.maxResponders = 5,
    this.initialVisibility = LocationPrivacy.approximate,
  });

  final double radiusMeters;
  final Duration ttl;
  final Duration cooldown;
  final int maxResponders;
  final LocationPrivacy initialVisibility;

  bool get isValid =>
      radiusMeters > 0 &&
      ttl.inMinutes >= 1 &&
      cooldown.inMinutes >= 1 &&
      maxResponders >= 1 &&
      initialVisibility == LocationPrivacy.approximate;

  bool canOfferVolunteer({
    required bool inFireZone,
    required bool underEvacuation,
    required bool routeClosed,
    required bool severeOfficialAlert,
  }) =>
      !inFireZone && !underEvacuation && !routeClosed && !severeOfficialAlert;

  LocationPrivacy visibilityAfterAcceptance(RescueRole role) => switch (role) {
        RescueRole.officialService => LocationPrivacy.exact,
        RescueRole.trustedContact => LocationPrivacy.temporary,
        RescueRole.verifiedProfessional => LocationPrivacy.temporary,
        RescueRole.volunteer => LocationPrivacy.approximate,
      };
}

final class RescueLinkAlert {
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

  bool expiredAt(DateTime now) => !now.isBefore(expiresAt);
}
