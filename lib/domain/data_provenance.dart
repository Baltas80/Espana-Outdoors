enum DataConfidence { official, verified, community, derived, estimated, aiAssisted }

enum FreshnessState { current, aging, stale, unknown }

class DataProvenance {
  const DataProvenance({
    required this.sourceId,
    required this.sourceName,
    required this.confidence,
    required this.retrievedAt,
    this.issuedAt,
    this.validUntil,
    this.license,
  });

  final String sourceId;
  final String sourceName;
  final DataConfidence confidence;
  final DateTime retrievedAt;
  final DateTime? issuedAt;
  final DateTime? validUntil;
  final String? license;

  FreshnessState get freshness {
    if (validUntil == null) return FreshnessState.unknown;
    final now = DateTime.now().toUtc();
    if (now.isBefore(validUntil!)) return FreshnessState.current;
    if (now.difference(validUntil!).inHours <= 24) return FreshnessState.aging;
    return FreshnessState.stale;
  }
}
