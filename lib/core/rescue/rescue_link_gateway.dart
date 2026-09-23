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

abstract interface class RescueLinkGateway {
  Future<RescueLinkRemoteSession> create(RescueLinkCreateRequest request);
  Future<void> revoke(String id);
  Future<RescueLinkRemoteSession> accept({
    required String id,
    required String role,
  });
}
