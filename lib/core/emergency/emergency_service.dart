import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/outdoor_models.dart';

class EmergencyService {
  EmergencyService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  Future<EmergencySnapshot?> captureSnapshot({
    required EmergencyType type,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    final batteryPercent = await _readBattery();

    return EmergencySnapshot(
      type: type,
      position: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      accuracyMeters: position.accuracy,
      capturedAt: DateTime.now().toUtc(),
      batteryPercent: batteryPercent,
      altitudeMeters: position.altitude,
    );
  }

  Future<bool> callEmergencyServices() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
  Future<int> _readBattery() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1;
    }
  }
}
