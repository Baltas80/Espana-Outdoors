import '../domain/outdoor_models.dart';

final class RescueLinkCreateRequest {
  const RescueLinkCreateRequest({
    required this.position,
    required this.accuracyMeters,
    required this.type,
    required this.expiresAt,
  });

  final GeoPoint position;
  final double accuracyMeters;
  final EmergencyType type;
  final DateTime expiresAt;
}

final class RescueLinkRemoteSession {
  const RescueLinkRemoteSession({
    required this.id,
    required this.shareToken,
    required this.shareUrl,
    required this.expiresAt,
  });

  final String id;
  final String shareToken;
  final Uri shareUrl;
  final DateTime expiresAt;
}

final class RescueLinkLocation {
  const RescueLinkLocation({
    required this.position,
    required this.accuracyMeters,
    required this.capturedAt,
    required this.type,
    required this.exact,
  });

  final GeoPoint position;
  final double accuracyMeters;
  final DateTime capturedAt;
  final EmergencyType type;
  final bool exact;
}

final class RescueLinkAcceptedSession {
  const RescueLinkAcceptedSession({
    required this.id,
    required this.capabilityToken,
    required this.expiresAt,
    required this.location,
  });

  final String id;
  final String capabilityToken;
  final DateTime expiresAt;
  final RescueLinkLocation location;
}

abstract interface class RescueLinkGateway {
  Future<RescueLinkRemoteSession> create(RescueLinkCreateRequest request);
  Future<void> revoke(String id);
  Future<RescueLinkAcceptedSession> accept({
    required String id,
    required String shareToken,
  });
}