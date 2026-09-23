import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/rescue/rescue_link_policy.dart';
import 'package:espana_outdoors/core/rescue/rescue_link_service.dart';
import 'package:espana_outdoors/core/contracts/platform_services.dart';

void main() {
  group('Rescue Link', () {
    test('creates an expiring alert with privacy defaults', () {
      const policy = RescueLinkPolicy();
      final alert = const RescueLinkService().createAlert(
        position: GeoPoint(latitude: 40.4, longitude: -3.7),
        policy: policy,
      );

      expect(alert.id, isNotEmpty);
      expect(alert.policy.initialVisibility, LocationPrivacy.approximate);
      expect(alert.expiredAt(DateTime.now()), isFalse);
      expect(alert.state, RescueLinkState.preparing);
    });

    test('rejects invalid policy', () {
      expect(
        () => const RescueLinkService().createAlert(
          position: GeoPoint(latitude: 40.4, longitude: -3.7),
          policy: const RescueLinkPolicy(radiusMeters: 0),
        ),
        throwsArgumentError,
      );
    });
  });
}
