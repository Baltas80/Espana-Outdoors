import '../../core/contracts/routing_service.dart';
import '../../domain/risk/route_risk.dart';

/// Adapts the real routing result to the risk engine.
///
/// The current route flow provides geometry and, when Valhalla supplies it,
/// distance/ascent. It does not yet provide route-scoped weather, official
/// alerts, closures, exposure or isolation evidence. Therefore completeness
/// deliberately remains 0 and the engine returns PRECAUCIÓN, never APTO.
final class RouteRiskAssessmentService {
  const RouteRiskAssessmentService({
    RouteRiskEngine engine = const RouteRiskEngine(),
  }) : _engine = engine;

  final RouteRiskEngine _engine;

  RouteRiskAssessment assess(RouteResult route, {DateTime? now}) {
    final distanceMeters = route.distanceMeters;
    final ascentMeters = route.ascentMeters;

    // Zero is only a required placeholder for unavailable metrics; with
    // completeness=0 it is never represented as verified terrain evidence.
    final distanceKm = distanceMeters != null &&
            distanceMeters.isFinite &&
            distanceMeters >= 0
        ? distanceMeters / 1000
        : 0.0;
    final elevationGainM = ascentMeters != null &&
            ascentMeters.isFinite &&
            ascentMeters >= 0
        ? ascentMeters
        : 0.0;

    return _engine.assess(
      RouteRiskInput(
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
        difficultyScore: 0,
        dataCompleteness: 0,
      ),
      now: now,
    );
  }
}
