import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/outdoor_models.dart';

class EmergencyService {
  const EmergencyService();

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

    return EmergencySnapshot(
      type: type,
      position: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      accuracyMeters: position.accuracy,
      capturedAt: DateTime.now(),
      batteryPercent: -1,
      altitudeMeters: position.altitude,
    );
  }

  Future<bool> callEmergencyServices() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }
}
