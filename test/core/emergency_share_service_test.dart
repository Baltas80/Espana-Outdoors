import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/emergency/emergency_share_service.dart';

void main() {
  test('share text never exposes exact coordinates', () {
    final snapshot = EmergencySnapshot(
      type: EmergencyType.lost,
      position: GeoPoint(latitude: 40.412345, longitude: -3.712345),
      accuracyMeters: 8,
      capturedAt: DateTime.utc(2026, 9, 23, 12),
      batteryPercent: 42,
    );

    final payload = EmergencyShareService().createPayload(
      snapshot: snapshot,
    );
    final message =
        EmergencyShareService().buildShareText(payload);

    expect(message, isNot(contains('40.412345')));
    expect(message, isNot(contains('-3.712345')));
    expect(message, contains('Ubicación aproximada'));
  });
}
