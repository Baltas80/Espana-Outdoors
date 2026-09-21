import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:gpx/gpx.dart';

import '../domain/outdoor_models.dart';

class ImportedTrack {
  const ImportedTrack({
    required this.name,
    required this.points,
    required this.distanceMeters,
    required this.ascentMeters,
    required this.descentMeters,
    this.startedAt,
    this.endedAt,
  });

  final String name;
  final List<GeoPoint> points;
  final double distanceMeters;
  final double ascentMeters;
  final double descentMeters;
  final DateTime? startedAt;
  final DateTime? endedAt;
}

class GpxImportService {
  const GpxImportService();

  Future<ImportedTrack?> pickAndImport() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['gpx'],
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final xml = utf8.decode(bytes, allowMalformed: false);
    return importString(xml, fallbackName: file.name);
  }

  ImportedTrack importString(String xml, {String fallbackName = 'Ruta importada'}) {
    final gpx = GpxReader().fromString(xml);
    final points = <GeoPoint>[];
    final elevations = <double?>[];
    final times = <DateTime?>[];

    for (final track in gpx.trks) {
      for (final segment in track.trksegs) {
        for (final point in segment.trkpts) {
          final lat = point.lat;
          final lon = point.lon;
          if (lat == null || lon == null) continue;
          if (lat < -90 || lat > 90 || lon < -180 || lon > 180) continue;
          points.add(GeoPoint(latitude: lat, longitude: lon));
          elevations.add(point.ele);
          times.add(point.time);
        }
      }
    }

    if (points.isEmpty) {
      throw const FormatException('El GPX no contiene puntos de track utilizables.');
    }

    final distanceMeters = _distance(points);
    var ascentMeters = 0.0;
    var descentMeters = 0.0;
    for (var i = 1; i < elevations.length; i++) {
      final previous = elevations[i - 1];
      final current = elevations[i];
      if (previous == null || current == null) continue;
      final delta = current - previous;
      if (delta > 0) {
        ascentMeters += delta;
      } else {
        descentMeters -= delta;
      }
    }

    DateTime? startedAt;
    DateTime? endedAt;
    for (final time in times) {
      if (time == null) continue;
      startedAt ??= time;
      endedAt = time;
    }

    final trackName = gpx.trks
            .map((track) => track.name)
            .whereType<String>()
            .map((name) => name.trim())
            .firstWhere((name) => name.isNotEmpty, orElse: () => fallbackName);

    return ImportedTrack(
      name: trackName,
      points: List.unmodifiable(points),
      distanceMeters: distanceMeters,
      ascentMeters: ascentMeters,
      descentMeters: descentMeters,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  double _distance(List<GeoPoint> points) {
    const earthRadiusMeters = 6371008.8;
    var total = 0.0;

    double radians(double degrees) => degrees * 3.141592653589793 / 180;

    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final dLat = radians(current.latitude - previous.latitude);
      final dLon = radians(current.longitude - previous.longitude);
      final lat1 = radians(previous.latitude);
      final lat2 = radians(current.latitude);

      final a = (Math.sin(dLat / 2) * Math.sin(dLat / 2)) +
          Math.cos(lat1) * Math.cos(lat2) *
              Math.sin(dLon / 2) * Math.sin(dLon / 2);
      final c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      total += earthRadiusMeters * c;
    }
    return total;
  }
}

class Math {
  static double sin(double value) => _sin(value);
  static double cos(double value) => _cos(value);
  static double sqrt(double value) => value.sqrt;
  static double atan2(double y, double x) => y.atan2(x);
}

extension on double {
  double get sqrt => this < 0 ? double.nan : _sqrt(this);
  double atan2(double x) => _atan2(this, x);
}

external double _sin(double value);
external double _cos(double value);
external double _sqrt(double value);
external double _atan2(double y, double x);
