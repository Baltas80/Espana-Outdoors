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
    this.turnApproachMeters = 60,
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

    if (safeAccuracy > poorGpsAccuracyMeters) {
      final nearest = _nearestPoint(route.points, position);
      return NavigationGuidance(
        status: NavigationGuidanceStatus.gpsPoor,
        distanceFromRouteMeters: nearest.distanceMeters,
        offRouteThresholdMeters: _threshold(safeAccuracy),
        nearestShapeIndex: nearest.index,
        progressFraction: nearest.index / (route.points.length - 1),
      );
    }

    final nearest = _nearestPoint(route.points, position);
    final threshold = _threshold(safeAccuracy);
    final progress = nearest.index / (route.points.length - 1);

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

    if (nearest.distanceMeters > threshold) {
      return NavigationGuidance(
        status: NavigationGuidanceStatus.offRoute,
        distanceFromRouteMeters: nearest.distanceMeters,
        offRouteThresholdMeters: threshold,
        nearestShapeIndex: nearest.index,
        nextStep: nextStep,
        distanceToNextStepMeters: distanceToStep,
        progressFraction: progress,
      );
    }

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

    return _NearestPoint(index: bestIndex, distanceMeters: bestDistance);
  }

  double _pathDistance(
    List<LatLng> points,
    int fromIndex,
    int toIndex,
  ) {
    final start = fromIndex.clamp(0, points.length - 1);
    final end = toIndex.clamp(0, points.length - 1);
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
