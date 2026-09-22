import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/rescue/rescue_link_policy.dart';
import 'package:espana_outdoors/core/rescue/rescue_proximity.dart';

void main() {
  test('detects whether a responder is inside the configured radius', () {
    const proximity = RescueProximity();
    const policy = RescueLinkPolicy(radiusMeters: 3000);
    const alert = GeoPoint(latitude: 40.4168, longitude: -3.7038);
    const nearby = GeoPoint(latitude: 40.4175, longitude: -3.7038);
    const far = GeoPoint(latitude: 40.5, longitude: -3.7038);

    expect(proximity.isWithinRadius(alert: alert, responder: nearby, policy: policy), isTrue);
    expect(proximity.isWithinRadius(alert: alert, responder: far, policy: policy), isFalse);
  });
}
