import 'package:geolocator/geolocator.dart';

/// Validates location samples before they are persisted into an outdoor track.
///
/// This is deliberately conservative: a bad point is ignored rather than
/// contaminating the recorded route or backtrack guidance.
class GpsQualityGate {
  const GpsQualityGate({
    this.maxAccuracyMeters = 100,
    this.maxAge = const Duration(seconds: 30),
    this.maxSpeedMps = 55,
  });

  final double maxAccuracyMeters;
  final Duration maxAge;
  final double maxSpeedMps;

  GpsQualityResult evaluate(
    Position position, {
    DateTime? now,
    Position? previous,
  }) {
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return const GpsQualityResult.reject('Coordenadas GPS no válidas.');
    }

    if (!position.accuracy.isFinite ||
        position.accuracy < 0 ||
        position.accuracy > maxAccuracyMeters) {
      return GpsQualityResult.reject(
        'Precisión GPS insuficiente (${position.accuracy.toStringAsFixed(0)} m).',
      );
    }

    final timestamp = position.timestamp;
    if (timestamp != null) {
      final reference = now ?? DateTime.now();
      if (reference.difference(timestamp).abs() > maxAge) {
        return const GpsQualityResult.reject('Lectura GPS demasiado antigua.');
      }
    }

    final speed = position.speed;
    if (speed.isFinite && speed >= 0 && speed > maxSpeedMps) {
      return const GpsQualityResult.reject('Velocidad GPS físicamente improbable.');
    }

    if (previous != null) {
      final previousTime = previous.timestamp;
      final currentTime = position.timestamp;
      if (previousTime != null && currentTime != null) {
        final seconds = currentTime.difference(previousTime).inMilliseconds / 1000;
        if (seconds > 0) {
          final distance = Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );
          if (distance / seconds > maxSpeedMps) {
            return const GpsQualityResult.reject(
              'Salto GPS incompatible con una velocidad razonable.',
            );
          }
        }
      }
    }

    return const GpsQualityResult.accept();
  }
}

class GpsQualityResult {
  const GpsQualityResult._(this.isUsable, this.reason);

  const GpsQualityResult.accept() : this._(true, null);

  const GpsQualityResult.reject(String reason) : this._(false, reason);

  final bool isUsable;
  final String? reason;
}
