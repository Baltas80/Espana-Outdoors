/// Provider-neutral contract for official and product-generated safety alerts.
///
/// The UI and route-readiness logic must consume normalized alerts rather than
/// provider-specific payloads. Every alert carries provenance and freshness so
/// stale data cannot silently look current.
library;

enum AlertAuthority {
  official,
  espanaOutdoor,
}

enum AlertSeverity {
  information,
  caution,
  warning,
  severe,
  extreme,
}

enum AlertFreshness {
  current,
  stale,
  expired,
  unknown,
}

class OutdoorAlert {
  const OutdoorAlert({
    required this.id,
    required this.authority,
    required this.severity,
    required this.title,
    required this.source,
    required this.issuedAt,
    this.updatedAt,
    this.expiresAt,
    this.description,
  });

  final String id;
  final AlertAuthority authority;
  final AlertSeverity severity;
  final String title;
  final String source;
  final DateTime issuedAt;
  final DateTime? updatedAt;
  final DateTime? expiresAt;
  final String? description;

  AlertFreshness freshnessAt(DateTime now) {
    final expiry = expiresAt;
    if (expiry != null && !now.isBefore(expiry)) {
      return AlertFreshness.expired;
    }

    final reference = updatedAt ?? issuedAt;
    final age = now.difference(reference);
    if (age.isNegative) return AlertFreshness.unknown;

    // This is deliberately conservative for alerts without an explicit
    // provider expiry. The provider integration may impose a shorter TTL.
    return age <= const Duration(hours: 6)
        ? AlertFreshness.current
        : AlertFreshness.stale;
  }
}

abstract interface class AlertService {
  Future<List<OutdoorAlert>> alertsNear({
    required double latitude,
    required double longitude,
  });
}
