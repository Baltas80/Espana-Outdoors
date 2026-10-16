import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:espana_outdoors/core/contracts/routing_service.dart';
import 'package:espana_outdoors/core/safety/route_risk_assessment_service.dart';
import 'package:espana_outdoors/domain/risk/route_risk.dart';

void main() {
  test('route flow is cautious while route-scoped risk sources are missing', () {
    const route = RouteResult(
      points: [
        LatLng(40.0, -3.0),
        LatLng(40.1, -3.1),
      ],
      distanceMeters: 8000,
      ascentMeters: 300,
    );

    final assessment = const RouteRiskAssessmentService().assess(
      route,
      now: DateTime.utc(2026, 10, 16, 12),
    );

    expect(assessment.readiness, RouteReadiness.precaucion);
    expect(assessment.confidence, 0);
    expect(
      assessment.reasons,
      contains('Información incompleta: revisa las fuentes antes de salir'),
    );
  });
}
