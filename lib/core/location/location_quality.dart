import 'package:geolocator/geolocator.dart';

/// Quality gate for outdoor tracking samples.
///
/// The recorder can use this policy before persisting a GPS point. It rejects
/// clearly unusable fixes while leaving normal hiking movement untouched.
class LocationQualityPolicy {
  const LocationQualityPolicy({
    this.maxHorizontalAccuracyMeters = 50,
    this.maxImpliedSpeedMps = 55,
    this.maxTimestampAge = const Duration(seconds: 30),
  });

  final double maxHorizontalAccuracyMeters;
  final double maxImpliedSpeedMps;
  final Duration maxTimestampAge;

  LocationQualityResult evaluate({
    required Position current,
    Position? previous,
    DateTime? now,
  }) {
    if (!current.latitude.isFinite ||
        !current.longitude.isFinite ||
        !current.accuracy.isFinite) {
      return const LocationQualityResult.reject('Coordenadas GPS inválidas.');
    }

    if (current.accuracy < 0 ||
        current.accuracy > maxHorizontalAccuracyMeters) {
      return LocationQualityResult.reject(
        'Precisión GPS insuficiente (${current.accuracy.toStringAsFixed(0)} m).',
      );
    }

    final referenceTime = now ?? DateTime.now();
    final age = referenceTime.difference(current.timestamp).abs();
    if (age > maxTimestampAge) {
      return LocationQualityResult.reject('Lectura GPS demasiado antigua.');
    }

    if (previous != null) {
      final seconds = current.timestamp
          .difference(previous.timestamp)
          .inMilliseconds /
          1000.0;
      if (seconds > 0) {
        final distance = Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          current.latitude,
          current.longitude,
        );
        final impliedSpeed = distance / seconds;
        if (impliedSpeed > maxImpliedSpeedMps) {
          return LocationQualityResult.reject(
            'Salto GPS incompatible con una ruta a pie.',
          );
        }
      }
    }

    return const LocationQualityResult.accept();
  }
}

class LocationQualityResult {
  const LocationQualityResult._(this.accepted, this.reason);

  const LocationQualityResult.accept() : this._(true, null);

  LocationQualityResult.reject(String reason) : this._(false, reason);

  final bool accepted;
  final String? reason;
}
