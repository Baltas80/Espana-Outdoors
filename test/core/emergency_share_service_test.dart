import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/domain/outdoor_models.dart';
import 'package:espana_outdoors/core/emergency/emergency_share_service.dart';

void main() {
  EmergencySnapshot snapshot() => EmergencySnapshot(
        type: EmergencyType.lost,
        position: const GeoPoint(latitude: 40.412345, longitude: -3.712345),
        accuracyMeters: 8,
        capturedAt: DateTime.utc(2026, 9, 23, 12),
        batteryPercent: 42,
        connectivity: EmergencyConnectivity.offline,
      );

  test('share text never exposes exact coordinates', () {
    final payload = const EmergencyShareService().createPayload(
      snapshot: snapshot(),
    );
    final message =
        const EmergencyShareService().buildShareText(payload);

    expect(message, isNot(contains('40.412345')));
    expect(message, isNot(contains('-3.712345')));
    expect(message, contains('Ubicación aproximada'));
    expect(message, isNot(contains('42%')));
    expect(message, isNot(contains('offline')));
  });

  test('expired share payload cannot produce an active location message', () {
    final payload = EmergencySharePayload(
      snapshot: snapshot(),
      expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
      shareToken: 'test',
    );

    final message =
        const EmergencyShareService().buildShareText(payload);

    expect(payload.expired, isTrue);
    expect(message, contains('ha caducado'));
    expect(message, isNot(contains('40.41')));
  });
}
