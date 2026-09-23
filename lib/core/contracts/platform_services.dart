/// Stable compatibility contracts around mature infrastructure providers.
///
/// New product code should prefer the focused contracts under core/map,
/// routing, auth, rescue and subscriptions plus the canonical domain models.
library;

import '../domain/outdoor_models.dart' as domain;

typedef GeoPoint = domain.GeoPoint;

enum LocationPrivacy { exact, approximate, private, temporary, shared }

enum LegacyDataConfidence { official, confirmed, community, stale, unknown }

class RouteRequest {
  const RouteRequest({required this.origin, required this.destination});
  final GeoPoint origin;
  final GeoPoint destination;
}

class RouteResult {
  const RouteResult({required this.geometry, required this.distanceMeters});
  final List<GeoPoint> geometry;
  final double distanceMeters;
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.observedAt,
    required this.expiresAt,
    required this.confidence,
    this.summary,
  });

  final DateTime observedAt;
  final DateTime expiresAt;
  final LegacyDataConfidence confidence;
  final String? summary;
}

abstract interface class MapService {
  Future<void> prepareOfflineRegion(String regionId);
  Future<void> removeOfflineRegion(String regionId);
  Future<bool> hasOfflineRegion(String regionId);
}

abstract interface class RoutingService {
  Future<RouteResult> route(RouteRequest request);
  Future<RouteResult> matchTrack(List<GeoPoint> points);
}

abstract interface class WeatherService {
  Future<WeatherSnapshot> forecastAt(GeoPoint point);
}

abstract interface class AuthService {
  Future<bool> signIn();
  Future<void> signOut();
  Future<String?> currentSubject();
}

abstract interface class StorageService {
  Future<void> put(String key, Object value);
  Future<Object?> get(String key);
  Future<void> remove(String key);
}

abstract interface class EmergencyService {
  Future<void> callEmergencyServices();
  Future<void> shareLocation({
    required GeoPoint point,
    required LocationPrivacy privacy,
  });
}

abstract interface class AlertService {
  Future<List<Object>> activeAlertsFor(GeoPoint point);
}

abstract interface class AIService {
  Future<String> answer(String query);
}

abstract interface class SubscriptionService {
  Future<Set<String>> activeEntitlements();
  Future<void> restorePurchases();
}