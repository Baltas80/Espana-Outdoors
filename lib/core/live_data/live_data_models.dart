/// Normalized live-data envelope preserving provenance and freshness.
library;

enum FreshnessState { fresh, stale, unavailable, unknown }

class LiveDataProvenance {
  const LiveDataProvenance({
    required this.sourceId,
    required this.sourceName,
    required this.retrievedAt,
    required this.freshness,
    required this.confidence,
    this.sourceUrl,
    this.license,
    this.attribution,
    this.sourceUpdatedAt,
    this.validFrom,
    this.validUntil,
    this.adapterVersion,
  });

  final String sourceId;
  final String sourceName;
  final DateTime retrievedAt;
  final FreshnessState freshness;
  final double confidence;
  final String? sourceUrl;
  final String? license;
  final String? attribution;
  final DateTime? sourceUpdatedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? adapterVersion;

  bool get isFresh => freshness == FreshnessState.fresh;
}

class LiveDataEnvelope<T> {
  const LiveDataEnvelope({required this.data, required this.provenance});

  final T data;
  final LiveDataProvenance provenance;
}

abstract interface class LiveDataGateway {
  Future<LiveDataEnvelope<T>> get<T>(String resource, Map<String, String> query);
}
