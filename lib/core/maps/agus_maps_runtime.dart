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
  bool _initialized = false;
  bool _surfaceReady = false;

  agus.MwmStorage? get storage => _storage;
  String? get dataPath => _dataPath;
  bool get surfaceReady => _surfaceReady;

  Future<void> ensureInitialized() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    if (_initialized) return;

    _storage = await agus.MwmStorage.create();
    if (await _storage!.hasOrphanedMetadata()) {
      await _storage!.pruneOrphaned();
    }

    final dataPath = await agus.extractDataFiles();
    _dataPath = dataPath;

    await agus.extractMap('assets/maps/icudt75l.dat');
    agus.initWithPaths(dataPath, dataPath);
    await _cleanupPartialDownloads(dataPath);
    _initialized = true;
  }

  Future<void> onMapReady() async {
    await ensureInitialized();
    _surfaceReady = true;
    await registerAllMaps();
  }

  Future<void> registerAllMaps() async {
    if (_storage == null || !_surfaceReady) return;

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
