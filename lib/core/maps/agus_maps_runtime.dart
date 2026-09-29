import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;

final class AgusMapsRuntime {
  AgusMapsRuntime._();

  static final AgusMapsRuntime instance = AgusMapsRuntime._();

  Future<void>? _initializing;
  agus.MwmStorage? _storage;
  String? _dataPath;
  int? _bundledVersion;
  final List<String> _bundledMapPaths = <String>[];
  bool _surfaceReady = false;

  agus.MwmStorage? get storage => _storage;
  String? get dataPath => _dataPath;
  bool get surfaceReady => _surfaceReady;

  Future<void> ensureInitialized() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (_storage != null) return;

    _storage = await agus.MwmStorage.create();
    if (await _storage!.hasOrphanedMetadata()) {
      await _storage!.pruneOrphaned();
    }

    final dataPath = await agus.extractDataFiles();
    _dataPath = dataPath;

    final worldPath = await agus.extractMap('assets/maps/World.mwm');
    final coastsPath = await agus.extractMap('assets/maps/WorldCoasts.mwm');
    await agus.extractMap('assets/maps/icudt75l.dat');

    _bundledMapPaths
      ..clear()
      ..addAll([worldPath, coastsPath]);

    _bundledVersion = await _readBundledVersion(dataPath);
    agus.initWithPaths(dataPath, dataPath);

    await _recordBundledMap('World', worldPath);
    await _recordBundledMap('WorldCoasts', coastsPath);
    await _cleanupPartialDownloads(dataPath);
  }

  Future<void> _recordBundledMap(String name, String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    if (_storage!.isDownloaded(name)) return;

    await _storage!.upsert(
      agus.MwmMetadata(
        regionName: name,
        snapshotVersion: 'bundled',
        fileSize: await file.length(),
        downloadDate: DateTime.now(),
        filePath: path,
        isBundled: true,
      ),
    );
  }

  Future<void> onMapReady() async {
    await ensureInitialized();
    _surfaceReady = true;
    await registerAllMaps();
  }

  Future<void> registerAllMaps() async {
    if (_storage == null || !_surfaceReady) return;

    final bundledVersion = _bundledVersion;
    for (final path in _bundledMapPaths) {
      if (bundledVersion != null) {
        agus.registerSingleMapWithVersion(path, bundledVersion);
      } else {
        agus.registerSingleMap(path);
      }
    }

    for (final metadata in _storage!.getAll()) {
      if (metadata.isBundled) continue;

      final file = File(metadata.filePath);
      if (!await file.exists()) {
        await _storage!.remove(metadata.regionName);
        continue;
      }

      final version = int.tryParse(metadata.snapshotVersion);
      if (version != null) {
        agus.registerSingleMapWithVersion(metadata.filePath, version);
      } else {
        agus.registerSingleMap(metadata.filePath);
      }
    }

    agus.invalidateMap();
    agus.forceRedraw();
  }

  Future<int> registerDownloadedMap({
    required String filePath,
    required int version,
  }) async {
    await ensureInitialized();

    if (!_surfaceReady) return -1;

    final result = agus.registerSingleMapWithVersion(filePath, version);
    agus.invalidateMap();
    agus.forceRedraw();

    return result;
  }

  Future<int?> _readBundledVersion(String dataPath) async {
    try {
      final file = File('${dataPath}/countries.txt');
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      if (json is Map && json['v'] is num) {
        return (json['v'] as num).toInt();
      }
    } catch (_) {}
    return null;
  }

  Future<void> _cleanupPartialDownloads(String dataPath) async {
    final root = Directory(dataPath);
    if (!await root.exists()) return;

    await for (final entity in root.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.endsWith('.mwm.download')) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }
}
