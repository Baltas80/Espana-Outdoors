import 'alert_models.dart';

/// Provider-neutral contract for live risk information.
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
