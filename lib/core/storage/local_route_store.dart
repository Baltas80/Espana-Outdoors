import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../gpx/gpx_import_service.dart';
import '../domain/outdoor_models.dart';

class LocalRouteStore {
  LocalRouteStore({Box<Map<dynamic, dynamic>>? box})
      : _box = box ?? Hive.box<Map<dynamic, dynamic>>('route_records');

  static const _latestKey = 'latest_import';

  final Box<Map<dynamic, dynamic>> _box;

  Future<void> saveImportedTrack(ImportedTrack track) async {
    final record = <String, dynamic>{
      'name': track.name,
      'distanceMeters': track.distanceMeters,
      'ascentMeters': track.ascentMeters,
      'descentMeters': track.descentMeters,
      'startedAt': track.startedAt?.toIso8601String(),
      'endedAt': track.endedAt?.toIso8601String(),
      'elevationsMeters': track.elevationsMeters,
      'timestamps': track.timestamps?.map((value) => value?.toIso8601String()).toList(growable: false),
      'points': track.points
          .map((point) => {
                'latitude': point.latitude,
                'longitude': point.longitude,
              })
          .toList(growable: false),
    };
    await _box.put(_latestKey, record);
  }

  ImportedTrack? loadLatestImportedTrack() {
    final record = _box.get(_latestKey);
    if (record == null) return null;

    final rawPoints = record['points'];
    if (rawPoints is! List || rawPoints.isEmpty) return null;

    final points = <GeoPoint>[];
    for (final raw in rawPoints) {
      if (raw is! Map) continue;
      final lat = _asDouble(raw['latitude']);
      final lon = _asDouble(raw['longitude']);
      if (lat == null || lon == null) continue;
      points.add(GeoPoint(latitude: lat, longitude: lon));
    }

    if (points.isEmpty) return null;

    return ImportedTrack(
      name: record['name']?.toString() ?? 'Ruta importada',
      points: List.unmodifiable(points),
      distanceMeters: _asDouble(record['distanceMeters']) ?? 0,
      ascentMeters: _asDouble(record['ascentMeters']) ?? 0,
      descentMeters: _asDouble(record['descentMeters']) ?? 0,
      startedAt: _asDate(record['startedAt']),
      endedAt: _asDate(record['endedAt']),
      elevationsMeters: _asDoubleList(record['elevationsMeters']),
      timestamps: _asDateList(record['timestamps']),
    );
  }

  Future<void> clearLatestImportedTrack() => _box.delete(_latestKey);

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  DateTime? _asDate(Object? value) {
    final raw = value?.toString();
    return raw == null ? null : DateTime.tryParse(raw);
  }

  List<double?>? _asDoubleList(Object? value) {
    if (value is! List) return null;
    return value.map(_asDouble).toList(growable: false);
  }

  List<DateTime?>? _asDateList(Object? value) {
    if (value is! List) return null;
    return value.map(_asDate).toList(growable: false);
  }
}
