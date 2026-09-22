import 'alert_models.dart';

/// Provider-neutral contract for live risk information.
///
/// Implementations may aggregate official and first-party sources, but the
/// domain layer must preserve authority, provenance and validity metadata.
abstract interface class AlertService {
  Future<List<OutdoorAlert>> alertsForRegion({
    required String regionId,
    required DateTime now,
  });

  Future<List<OutdoorAlert>> alertsForPoint({
    required double latitude,
    required double longitude,
    required DateTime now,
  });
}
