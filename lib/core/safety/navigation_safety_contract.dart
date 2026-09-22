/// Safety boundary between navigation, routing and emergency UX.
library;

import '../domain/outdoor_models.dart';

enum NavigationSafetyState { ready, navigating, degraded, offRoute, emergency }

enum RouteLiveStatus { normal, caution, problems, closed }

class NavigationSafetySnapshot {
  const NavigationSafetySnapshot({required this.state, required this.status, this.reason});
  final NavigationSafetyState state;
  final RouteLiveStatus status;
  final String? reason;
}

abstract interface class NavigationSafetyPolicy {
  NavigationSafetySnapshot evaluate({
    required GeoPoint position,
    required double accuracyMeters,
    required bool routeAvailableOffline,
    required List<OutdoorRisk> risks,
  });
}
