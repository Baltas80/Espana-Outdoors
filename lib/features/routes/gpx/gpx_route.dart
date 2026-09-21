import '../../../core/domain/outdoor_models.dart';

class GpxTrackPoint {
  const GpxTrackPoint({
    required this.position,
    this.elevationMeters,
    this.timestamp,
  });

  final GeoPoint position;
  final double? elevationMeters;
  final DateTime? timestamp;
}

class GpxRoute {
  const GpxRoute({
    required this.name,
    required this.points,
  });

  final String name;
  final List<GpxTrackPoint> points;

  bool get isEmpty => points.isEmpty;
  int get pointCount => points.length;
}
