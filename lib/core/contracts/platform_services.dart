/// Stable application contracts around mature infrastructure providers.
///
/// Product code depends on these contracts rather than directly depending on
/// Valhalla, Keycloak, AEMET, RevenueCat, MapLibre or a particular backend.
/// Provider adapters live outside the domain layer.
library;

enum DataConfidence { official, confirmed, community, stale, unknown }

enum LocationPrivacy { exact, approximate, private, temporary, shared }

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

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
  const WeatherSnapshot({required this.observedAt, required this.expiresAt, required this.confidence, this.summary});
  final DateTime observedAt;
  final DateTime expiresAt;
  final DataConfidence confidence;
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
  Future<void> shareLocation({required GeoPoint point, required LocationPrivacy privacy});
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
