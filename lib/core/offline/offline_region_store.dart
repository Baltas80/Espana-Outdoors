import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../map/map_service.dart';

enum OfflineRegionStatus { queued, downloading, paused, ready, failed, deleting }

class OfflineRegionRecord {
  const OfflineRegionRecord({
    required this.region,
    required this.status,
    this.progress = 0,
    this.bytesDownloaded = 0,
    this.bytesTotal = 0,
    this.localPath,
    this.sha256,
    this.artifactVersion,
    this.updatedAt,
    this.error,
  });

  final OfflineMapRegion region;
  final OfflineRegionStatus status;
  final double progress;
  final int bytesDownloaded;
  final int bytesTotal;
  final String? localPath;
  final String? sha256;
  final String? artifactVersion;
  final DateTime? updatedAt;
  final String? error;

  bool get hasValidArtifact =>
      status == OfflineRegionStatus.ready &&
      localPath != null &&
      localPath!.trim().isNotEmpty &&
      artifactVersion != null &&
      artifactVersion!.trim().isNotEmpty &&
      bytesDownloaded > 0 &&
      (sha256 == null || RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256!));

  OfflineRegionRecord copyWith({
    OfflineRegionStatus? status,
    double? progress,
    int? bytesDownloaded,
    int? bytesTotal,
    String? localPath,
    String? sha256,
    String? artifactVersion,
    DateTime? updatedAt,
    String? error,
  }) {
    return OfflineRegionRecord(
      region: region,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      localPath: localPath ?? this.localPath,
      sha256: sha256 ?? this.sha256,
      artifactVersion: artifactVersion ?? this.artifactVersion,
      updatedAt: updatedAt ?? this.updatedAt,
      error: error,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': region.id,
        'name': region.name,
        'west': region.bounds.west,
        'south': region.bounds.south,
        'east': region.bounds.east,
        'north': region.bounds.north,
        'minZoom': region.minZoom,
        'maxZoom': region.maxZoom,
        'providerId': region.providerId,
        'styleVersion': region.styleVersion,
        'status': status.name,
        'progress': progress,
        'bytesDownloaded': bytesDownloaded,
        'bytesTotal': bytesTotal,
        'localPath': localPath,
        'sha256': sha256,
        'artifactVersion': artifactVersion,
        'updatedAt': updatedAt?.toIso8601String(),
        'error': error,
      };

  static OfflineRegionRecord? fromMap(Map<dynamic, dynamic> value) {
    final id = '${value['id'] ?? ''}';
    final name = '${value['name'] ?? ''}';
    final providerId = '${value['providerId'] ?? ''}';
    final styleVersion = '${value['styleVersion'] ?? ''}';
    final statusName = '${value['status'] ?? ''}';
    final status = OfflineRegionStatus.values.where((item) => item.name == statusName).firstOrNull;
    final region = OfflineMapRegion(
      id: id,
      name: name,
      bounds: MapBounds(
        west: _double(value['west']),
        south: _double(value['south']),
        east: _double(value['east']),
        north: _double(value['north']),
      ),
      minZoom: _int(value['minZoom']),
      maxZoom: _int(value['maxZoom']),
      providerId: providerId,
      styleVersion: styleVersion,
    );
    if (!region.isValid || status == null) return null;

    return OfflineRegionRecord(
      region: region,
      status: status,
      progress: _double(value['progress']),
      bytesDownloaded: _int(value['bytesDownloaded']),
      bytesTotal: _int(value['bytesTotal']),
      localPath: value['localPath']?.toString(),
      sha256: value['sha256']?.toString(),
      artifactVersion: value['artifactVersion']?.toString(),
      updatedAt: DateTime.tryParse('${value['updatedAt'] ?? ''}'),
      error: value['error']?.toString(),
    );
  }

  static double _double(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  static int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

class OfflineRegionStore {
  OfflineRegionStore({Box<Map<dynamic, dynamic>>? box}) : _box = box ?? Hive.box<Map<dynamic, dynamic>>(_boxName);

  static const _boxName = 'offline_regions';
  final Box<Map<dynamic, dynamic>> _box;

  List<OfflineRegionRecord> all() => _box.values
      .map(OfflineRegionRecord.fromMap)
      .whereType<OfflineRegionRecord>()
      .toList(growable: false);

  OfflineRegionRecord? get(String id) {
    final value = _box.get(id);
    return value == null ? null : OfflineRegionRecord.fromMap(value);
  }

  Future<void> put(OfflineRegionRecord record) => _box.put(record.region.id, record.toMap());

  Future<void> remove(String id) => _box.delete(id);
}
