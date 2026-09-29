import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;

final class AgusMapsRuntime {
  AgusMapsRuntime._();

  static final AgusMapsRuntime instance = AgusMapsRuntime._();

  Future<void>? _initializing;
  agus.MwmStorage? _storage;
  String? _dataPath;
  bool _initialized = false;
  bool _surfaceReady = false;
  Future<void>? _registrationFuture;

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
    await agus.extractMap('assets/maps/World.mwm');
    await agus.extractMap('assets/maps/WorldCoasts.mwm');

    agus.initWithPaths(dataPath, dataPath);
    await _cleanupPartialDownloads(dataPath);
    _initialized = true;
  }

  Future<void> onMapReady() async {
    await ensureInitialized();
    if (_surfaceReady && _registrationFuture != null) return;

    _surfaceReady = true;
    _registrationFuture ??= _registerDownloadedMapsSafely();
    try {
      await _registrationFuture;
    } on Object catch (error, stackTrace) {
      debugPrint('[AgusMapsRuntime] map registration failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _registrationFuture = null;
    }
  }

  Future<void> _registerDownloadedMapsSafely() async {
    try {
      await registerAllMaps();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> registerAllMaps() async {
    if (_storage == null || !_surfaceReady) return;

    var registeredAny = false;

    for (final metadata in _storage!.getAll()) {
      if (metadata.isBundled) continue;

      final file = File(metadata.filePath);
      if (!await file.exists()) {
        await _storage!.remove(metadata.regionName);
        continue;
      }

      final version = int.tryParse(metadata.snapshotVersion);
      final result = version != null
          ? agus.registerSingleMapWithVersion(metadata.filePath, version)
          : agus.registerSingleMap(metadata.filePath);
      debugPrint(
        '[AgusMapsRuntime] downloaded map registration: '
        + metadata.regionName + ' result=' + result.toString(),
      );
      registeredAny = true;
      if (result != 0) {
        throw StateError(
          'Failed to register downloaded map ${metadata.regionName} '
          '(result $result).',
        );
      }
    }

    // Bundled World/WorldCoasts are discovered by CoMaps during Framework
    // startup. Only invalidate after an actual regional registration.
    if (registeredAny) {
      agus.invalidateMap();
    }
  }

  Future<int> registerDownloadedMap({
    required String filePath,
    required int version,
  }) async {
    await ensureInitialized();

    if (!_surfaceReady) return -1;

    final result = agus.registerSingleMapWithVersion(filePath, version);
    if (result != 0) {
      throw StateError(
        'Failed to register downloaded map ${File(filePath).uri.pathSegments.last} '
        '(result $result).',
      );
    }
    agus.invalidateMap();

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
