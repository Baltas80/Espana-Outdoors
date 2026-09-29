import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../domain/outdoor_models.dart';

/// A timestamped GPS sample used for route analysis.
///
/// Kept separate from [GeoPoint] so existing persisted GPX/domain models do
/// not need a breaking change merely to gain richer live-route analytics.
class RouteSample {
  const RouteSample({
    required this.point,
    required this.capturedAt,
    this.accuracyMeters,
  });

  final GeoPoint point;
  final DateTime capturedAt;
  final double? accuracyMeters;
}

class RouteMetrics {
  const RouteMetrics({
    required this.distanceMeters,
    required this.elapsed,
    required this.moving,
    required this.stopped,
    required this.averageMovingSpeedMps,
    required this.maxSpeedMps,
    required this.stopCount,
  });

  final double distanceMeters;
  final Duration elapsed;
  final Duration moving;
  final Duration stopped;
  final double averageMovingSpeedMps;
  final double maxSpeedMps;
  final int stopCount;

  double get averageMovingSpeedKmh => averageMovingSpeedMps * 3.6;
  double get maxSpeedKmh => maxSpeedMps * 3.6;
}

/// Offline route analysis with conservative GPS filtering.
///
/// It deliberately does not modify the recorder. Callers can run this on a
/// completed or recovered track without changing the existing persistence
/// format.
class RouteMetricsAnalyzer {
  const RouteMetricsAnalyzer({
    this.maxAccuracyMeters = 75,
    this.maxPlausibleSpeedMps = 55,
    this.stopSpeedMps = 0.8,
    this.minimumStopDuration = const Duration(seconds: 45),
  });

  final double maxAccuracyMeters;
  final double maxPlausibleSpeedMps;
  final double stopSpeedMps;
  final Duration minimumStopDuration;

  List<RouteSample> filterSamples(Iterable<RouteSample> samples) {
    final accepted = <RouteSample>[];
    for (final sample in samples) {
      if (!_isValid(sample)) continue;
      if (accepted.isEmpty) {
        accepted.add(sample);
        continue;
      }

      final previous = accepted.last;
      final seconds = sample.capturedAt
          .difference(previous.capturedAt)
          .inMilliseconds /
          1000;
      if (seconds <= 0) continue;

      final distance = _distance(previous.point, sample.point);
      if (distance / seconds > maxPlausibleSpeedMps) continue;
      accepted.add(sample);
    }
    return List.unmodifiable(accepted);
  }

  RouteMetrics analyze(Iterable<RouteSample> samples) {
    final points = filterSamples(samples);
    if (points.length < 2) {
      return const RouteMetrics(
        distanceMeters: 0,
        elapsed: Duration.zero,
        moving: Duration.zero,
        stopped: Duration.zero,
        averageMovingSpeedMps: 0,
        maxSpeedMps: 0,
        stopCount: 0,
      );
    }

    var distanceMeters = 0.0;
    var movingSeconds = 0.0;
    var stoppedSeconds = 0.0;
    var maxSpeedMps = 0.0;
    var movingDistance = 0.0;
    var stopCount = 0;
    var inStop = false;

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final seconds = current.capturedAt
              .difference(previous.capturedAt)
              .inMilliseconds /
          1000;
      if (seconds <= 0) continue;

      final distance = _distance(previous.point, current.point);
      final speed = distance / seconds;
      distanceMeters += distance;
      maxSpeedMps = math.max(maxSpeedMps, speed);

      final stoppedSegment = speed <= stopSpeedMps;
      if (stoppedSegment) {
        stoppedSeconds += seconds;
        if (!inStop && seconds >= minimumStopDuration.inSeconds) {
          stopCount++;
          inStop = true;
        }
      } else {
        movingSeconds += seconds;
        movingDistance += distance;
        inStop = false;
      }
    }

    final elapsed = points.last.capturedAt.difference(points.first.capturedAt);
    return RouteMetrics(
      distanceMeters: distanceMeters,
      elapsed: elapsed.isNegative ? Duration.zero : elapsed,
      moving: Duration(seconds: movingSeconds.round()),
      stopped: Duration(seconds: stoppedSeconds.round()),
      averageMovingSpeedMps:
          movingSeconds <= 0 ? 0 : movingDistance / movingSeconds,
      maxSpeedMps: maxSpeedMps,
      stopCount: stopCount,
    );
  }

  bool _isValid(RouteSample sample) {
    final lat = sample.point.latitude;
    final lon = sample.point.longitude;
    if (!lat.isFinite || !lon.isFinite) return false;
    if (lat < -90 || lat > 90 || lon < -180 || lon > 180) return false;
    final accuracy = sample.accuracyMeters;
    if (accuracy != null &&
        (!accuracy.isFinite || accuracy < 0 || accuracy > maxAccuracyMeters)) {
      return false;
    }
    return true;
  }

  double _distance(GeoPoint a, GeoPoint b) {
    return Geolocator.distanceBetween(
      a.latitude,
      a.longitude,
      b.latitude,
      b.longitude,
    );
  }
}
