import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

/// Lightweight offline analysis of a recorded GPS track.
///
/// The analyzer consumes the existing location stream and does not replace
/// the route recorder or routing engine.
class TrackAnalysis {
  const TrackAnalysis({
    required this.distanceMeters,
    required this.movingDistanceMeters,
    required this.movingTime,
    required this.stoppedTime,
    required this.averageMovingSpeedMps,
    required this.maximumSpeedMps,
    required this.stopCount,
  });

  final double distanceMeters;
  final double movingDistanceMeters;
  final Duration movingTime;
  final Duration stoppedTime;
  final double averageMovingSpeedMps;
  final double maximumSpeedMps;
  final int stopCount;

  Duration get totalTime => movingTime + stoppedTime;
}

TrackAnalysis analyzeTrack(
  List<Position> positions, {
  double movingSpeedThresholdMps = 0.8,
  Duration stopThreshold = const Duration(minutes: 2),
}) {
  if (positions.length < 2) {
    return const TrackAnalysis(
      distanceMeters: 0,
      movingDistanceMeters: 0,
      movingTime: Duration.zero,
      stoppedTime: Duration.zero,
      averageMovingSpeedMps: 0,
      maximumSpeedMps: 0,
      stopCount: 0,
    );
  }

  var distance = 0.0;
  var movingDistance = 0.0;
  var movingSeconds = 0.0;
  var stoppedSeconds = 0.0;
  var maximumSpeed = 0.0;
  var stopCount = 0;
  DateTime? stoppedSince;
  var previous = positions.first;

  for (final current in positions.skip(1)) {
    final seconds = current.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
    if (seconds <= 0 || seconds > 300) {
      previous = current;
      continue;
    }

    final segment = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
    final measuredSpeed = segment / seconds;
    final reportedSpeed = current.speed.isFinite && current.speed >= 0
        ? current.speed
        : measuredSpeed;
    final speed = math.max(0.0, reportedSpeed);

    distance += segment;
    maximumSpeed = math.max(maximumSpeed, speed);

    if (speed >= movingSpeedThresholdMps) {
      movingDistance += segment;
      movingSeconds += seconds;
      if (stoppedSince != null) {
        final stoppedDuration = current.timestamp.difference(stoppedSince!);
        if (stoppedDuration >= stopThreshold) stopCount++;
        stoppedSeconds += stoppedDuration.inMilliseconds / 1000;
        stoppedSince = null;
      }
    } else if (stoppedSince == null) {
      stoppedSince = previous.timestamp;
    }

    previous = current;
  }

  if (stoppedSince != null) {
    final stoppedDuration = previous.timestamp.difference(stoppedSince!);
    if (stoppedDuration >= stopThreshold) stopCount++;
    stoppedSeconds += stoppedDuration.inMilliseconds / 1000;
  }

  final movingTime = Duration(milliseconds: (movingSeconds * 1000).round());
  final stoppedTime = Duration(milliseconds: (stoppedSeconds * 1000).round());

  return TrackAnalysis(
    distanceMeters: distance,
    movingDistanceMeters: movingDistance,
    movingTime: movingTime,
    stoppedTime: stoppedTime,
    averageMovingSpeedMps: movingSeconds > 0 ? movingDistance / movingSeconds : 0,
    maximumSpeedMps: maximumSpeed,
    stopCount: stopCount,
  );
}
