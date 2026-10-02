import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../contracts/routing_service.dart';
import '../domain/outdoor_models.dart';

enum NavigationGuidanceStatus {
  noRoute,
  gpsPoor,
  onRoute,
  approachingTurn,
  offRoute,
  arrived,
}

final class NavigationGuidance {
  const NavigationGuidance({
    required this.status,
    required this.distanceFromRouteMeters,
    required this.offRouteThresholdMeters,
    required this.nearestShapeIndex,
    this.nextStep,
    this.distanceToNextStepMeters,
    this.progressFraction = 0,
  });

  final NavigationGuidanceStatus status;
  final double distanceFromRouteMeters;
  final double offRouteThresholdMeters;
  final int nearestShapeIndex;
  final RouteStep? nextStep;
  final double? distanceToNextStepMeters;
  final double progressFraction;

  bool get isOffRoute => status == NavigationGuidanceStatus.offRoute;
}

final class NavigationGuidanceEngine {
  const NavigationGuidanceEngine({
    this.poorGpsAccuracyMeters = 100,
    this.minimumOffRouteMeters = 40,
    this.accuracyMultiplier = 2.5,
    this.turnApproachMeters = 50,
    this.arrivalMeters = 35,
  });

  final double poorGpsAccuracyMeters;
  final double minimumOffRouteMeters;
  final double accuracyMultiplier;
  final double turnApproachMeters;
  final double arrivalMeters;

  NavigationGuidance evaluate({
    required RouteResult route,
    required GeoPoint position,
    required double accuracyMeters,
  }) {
    if (route.points.length < 2) {
      return const NavigationGuidance(
        status: NavigationGuidanceStatus.noRoute,
        distanceFromRouteMeters: double.infinity,
        offRouteThresholdMeters: double.infinity,
        nearestShapeIndex: 0,
      );
    }

    final safeAccuracy = accuracyMeters.isFinite && accuracyMeters >= 0
        ? accuracyMeters
        : poorGpsAccuracyMeters;

    final nearest = _nearestPoint(route.points, position);
    final threshold = _threshold(safeAccuracy);
    final progress = nearest.index / (route.points.length - 1);

    if (safeAccuracy > poorGpsAccuracyMeters) {
      return NavigationGuidance(
        status: NavigationGuidanceStatus.gpsPoor,
        distanceFromRouteMeters: nearest.distanceMeters,
        offRouteThresholdMeters: threshold,
        nearestShapeIndex: nearest.index,
        progressFraction: progress,
      );
    }

    // Never report arrival while the trustworthy GPS fix is outside the route.
    // A fix near the route endpoint can otherwise satisfy the arrival distance
    // while still being materially separated from the route itself.
    if (nearest.distanceMeters > threshold) {
      return NavigationGuidance(
        status: NavigationGuidanceStatus.offRoute,
        distanceFromRouteMeters: nearest.distanceMeters,
        offRouteThresholdMeters: threshold,
        nearestShapeIndex: nearest.index,
        progressFraction: progress,
      );
    }

    final distanceToEnd = _pathDistance(
      route.points,
      nearest.index,
      route.points.length - 1,
    );
    if (distanceToEnd <= arrivalMeters) {
      return NavigationGuidance(
        status: NavigationGuidanceStatus.arrived,
        distanceFromRouteMeters: nearest.distanceMeters,
        offRouteThresholdMeters: threshold,
        nearestShapeIndex: nearest.index,
        progressFraction: progress,
      );
    }

    final nextStepIndex = _nextStepIndex(route.steps, nearest.index);
    final nextStep =
        nextStepIndex == null ? null : route.steps[nextStepIndex];
    final stepShapeIndex = nextStep?.beginShapeIndex;
    final distanceToStep = stepShapeIndex == null
        ? null
        : _pathDistance(
            route.points,
            nearest.index,
            stepShapeIndex.clamp(0, route.points.length - 1),
          );

    final status = distanceToStep != null &&
            distanceToStep <= turnApproachMeters
        ? NavigationGuidanceStatus.approachingTurn
        : NavigationGuidanceStatus.onRoute;

    return NavigationGuidance(
      status: status,
      distanceFromRouteMeters: nearest.distanceMeters,
      offRouteThresholdMeters: threshold,
      nearestShapeIndex: nearest.index,
      nextStep: nextStep,
      distanceToNextStepMeters: distanceToStep,
      progressFraction: progress,
    );
  }

  double _threshold(double accuracyMeters) =>
      math.max(minimumOffRouteMeters, accuracyMeters * accuracyMultiplier);

  _NearestPoint _nearestPoint(List<LatLng> points, GeoPoint position) {
    var bestDistance = double.infinity;
    var bestIndex = 0;

    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = index;
      }
    }

    // A GPS fix commonly lands between two route vertices. Use the closest
    // segment projection for off-route distance, while retaining the closest
    // vertex index for progress and step lookup compatibility.
    for (var index = 0; index < points.length - 1; index++) {
      final distance = _distanceToSegmentMeters(
        position,
        points[index],
        points[index + 1],
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        final toStart = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          points[index].latitude,
          points[index].longitude,
        );
        final toEnd = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          points[index + 1].latitude,
          points[index + 1].longitude,
        );
        bestIndex = toStart <= toEnd ? index : index + 1;
      }
    }

    return _NearestPoint(index: bestIndex, distanceMeters: bestDistance);
  }

  double _distanceToSegmentMeters(GeoPoint position, LatLng start, LatLng end) {
    const earthRadiusMeters = 6371008.8;
    final latitudeScale = math.pi / 180;
    final meanLatitude =
        ((start.latitude + end.latitude + position.latitude) / 3) * latitudeScale;
    final cosLatitude = math.cos(meanLatitude).clamp(0.01, 1.0);
    final toRadians = latitudeScale;

    final x = (position.longitude - start.longitude) * toRadians * cosLatitude;
    final y = (position.latitude - start.latitude) * toRadians;
    final dx = (end.longitude - start.longitude) * toRadians * cosLatitude;
    final dy = (end.latitude - start.latitude) * toRadians;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        start.latitude,
        start.longitude,
      );
    }

    final projection = ((x * dx) + (y * dy)) / lengthSquared;
    final t = projection.clamp(0.0, 1.0);
    final projectedX = t * dx;
    final projectedY = t * dy;
    return math.sqrt(
          math.pow(x - projectedX, 2) + math.pow(y - projectedY, 2),
        ) *
        earthRadiusMeters;
  }

  double _pathDistance(
    List<LatLng> points,
    int fromIndex,
    int toIndex,
  ) {
    final start = fromIndex.clamp(0, points.length - 1).toInt();
    final end = toIndex.clamp(0, points.length - 1).toInt();
    if (start == end) return 0;

    final low = math.min(start, end);
    final high = math.max(start, end);
    var total = 0.0;
    for (var index = low; index < high; index++) {
      final a = points[index];
      final b = points[index + 1];
      total += Geolocator.distanceBetween(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
    }
    return total;
  }

  int? _nextStepIndex(List<RouteStep> steps, int shapeIndex) {
    for (var index = 0; index < steps.length; index++) {
      final begin = steps[index].beginShapeIndex;
      if (begin == null || begin >= shapeIndex) return index;
    }
    return null;
  }
}

final class _NearestPoint {
  const _NearestPoint({
    required this.index,
    required this.distanceMeters,
  });

  final int index;
  final double distanceMeters;
}
