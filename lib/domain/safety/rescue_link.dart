enum RescueRole { official, trustedContact, volunteer, verifiedProfessional }

enum RescueSessionState { inactive, requesting, accepted, active, expired, cancelled }

final class RescueSharePolicy {
  const RescueSharePolicy({
    required this.approximateFirst,
    required this.expiresAt,
  });

  final bool approximateFirst;
  final DateTime expiresAt;
}

final class RescueSession {
  const RescueSession({
    required this.id,
    required this.state,
    required this.createdAt,
    required this.expiresAt,
    required this.minimumDisclosure,
  });

  final String id;
  final RescueSessionState state;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool minimumDisclosure;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}

/// Domain boundary for Rescue Link. Provider/network implementations belong
/// in infrastructure and must enforce the same authorization rules server-side.
abstract interface class RescueLinkService {
  Future<RescueSession> requestHelp({required String emergencyId});
  Future<void> acceptRequest({required String sessionId, required RescueRole role});
  Future<void> cancel({required String sessionId});
  Future<void> expire({required String sessionId});
}
