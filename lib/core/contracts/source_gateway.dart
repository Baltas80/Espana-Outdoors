enum SourceKind { official, community, derived }

enum SourceStatus { healthy, degraded, unavailable, stale }

class SourceSnapshot {
  const SourceSnapshot({
    required this.sourceId,
    required this.kind,
    required this.status,
    required this.observedAt,
    this.expiresAt,
    this.licenseUrl,
    this.attribution,
  });

  final String sourceId;
  final SourceKind kind;
  final SourceStatus status;
  final DateTime observedAt;
  final DateTime? expiresAt;
  final String? licenseUrl;
  final String? attribution;

  bool get isFresh =>
      status != SourceStatus.stale &&
      status != SourceStatus.unavailable &&
      (expiresAt == null || DateTime.now().toUtc().isBefore(expiresAt!));
}

final class SourceProvenance {
  const SourceProvenance({
    required this.source,
    required this.licenseUrl,
    required this.observedAt,
  });

  final String source;
  final String licenseUrl;
  final DateTime observedAt;
}

final class SourceFreshness {
  const SourceFreshness({
    required this.status,
    required this.fetchedAt,
  });

  final String status;
  final DateTime fetchedAt;
}

final class SourceDataSnapshot {
  const SourceDataSnapshot({
    required this.data,
    required this.provenance,
    required this.freshness,
  });

  final List<Map<String, Object?>> data;
  final SourceProvenance provenance;
  final SourceFreshness freshness;
}

/// Gateway for official and validated external feeds. Features consume normalized
/// records and never depend directly on AEMET/MITECO/IGN/Protección Civil APIs.
abstract interface class SourceGateway {
  Future<SourceSnapshot> health(String sourceId);
  Future<SourceDataSnapshot> fetch(
    String sourceId, {
    Map<String, Object?> parameters = const {},
  });
}
