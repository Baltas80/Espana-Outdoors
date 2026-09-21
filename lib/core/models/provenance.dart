enum DataConfidence { official, verified, community, derived, estimated, aiAssisted }

enum Freshness { current, aging, stale, unknown }

class Provenance {
  const Provenance({
    required this.sourceId,
    required this.sourceName,
    required this.confidence,
    required this.retrievedAt,
    this.validUntil,
    this.license,
  });

  final String sourceId;
  final String sourceName;
  final DataConfidence confidence;
  final DateTime retrievedAt;
  final DateTime? validUntil;
  final String? license;

  Freshness get freshness {
    final expiry = validUntil;
    if (expiry == null) return Freshness.unknown;
    final now = DateTime.now();
    if (now.isAfter(expiry)) return Freshness.stale;
    if (expiry.difference(now).inHours < 24) return Freshness.aging;
    return Freshness.current;
  }
}
