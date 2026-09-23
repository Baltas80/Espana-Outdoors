enum SourceKind { official, community, derived }

enum SourceStatus { healthy, degraded, unavailable, stale }

class SourceSnapshot {
  const SourceSnapshot({required this.sourceId, required this.kind, required this.status, required this.observedAt, this.expiresAt, this.licenseUrl, this.attribution});

  final String sourceId;
  final SourceKind kind;
  final SourceStatus status;
  final DateTime observedAt;
  final DateTime? expiresAt;
  final String? licenseUrl;
  final String? attribution;

  bool get isFresh => expiresAt == null || DateTime.now().toUtc().isBefore(expiresAt!);
}

/// Gateway for official and validated external feeds. Features consume normalized
/// records and never depend directly on AEMET/MITECO/IGN/Protección Civil APIs.
abstract interface class SourceGateway {
  Future<SourceSnapshot> health(String sourceId);
  Future<List<Map<String, Object?>>> fetch(String sourceId, {Map<String, Object?> parameters = const {}});
}
