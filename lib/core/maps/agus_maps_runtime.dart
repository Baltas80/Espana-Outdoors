import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;

final class AgusMapsRuntime {
  AgusMapsRuntime._();

  static final AgusMapsRuntime instance = AgusMapsRuntime._();

  Future<void>? _initializing;
  agus.MwmStorage? _storage;
  String? _dataPath;
  String? _worldPath;
  String? _worldCoastsPath;
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

    final dataPath = await _extractComapsDataSafely();
    _dataPath = dataPath;

    // CoMaps scans its writable directory while the native Framework is
    // created. Clean interrupted transfers before initWithPaths().
    await _cleanupPartialDownloads(dataPath);
    await _validatePersistedMaps();

    await agus.extractMap('assets/maps/icudt75l.dat');
    _worldPath = await _ensureBundledMap(
      assetPath: 'assets/maps/World.mwm',
      expectedSize: 53029018,
      expectedSha1: '7a588f8c9d81ae26eb509b4b00ac8f790b2f5054',
    );
    _worldCoastsPath = await _ensureBundledMap(
      assetPath: 'assets/maps/WorldCoasts.mwm',
      expectedSize: 8505665,
      expectedSha1: 'cfd2cce0526ca92cf03c1cc784e12d433bf590d9',
    );

    // initWithPaths() only prepares the native platform. The Android Agus
    // bridge creates the Framework when the SurfaceProducer surface exists.
    // At that point CoMaps scans this same writable directory and registers
    // World.mwm/WorldCoasts.mwm once. Do not register those bundled maps a
    // second time from Dart: duplicate RegisterMap calls are unnecessary and
    // can race the native renderer during its first frame.
    agus.initWithPaths(dataPath, dataPath);
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
    // Bundled MWM files are already visible to the native Framework when
    // AgusMap creates the Surface. Only maps added after startup need explicit
    // registration here.
    await registerAllMaps();

    // Registration of downloaded maps changes the datasource after the engine
    // exists. A lightweight viewport invalidation is sufficient and avoids the
    // heavier SetMapStyle()/forceRedraw path during initial map startup.
    if (_surfaceReady) {
      try {
        agus.invalidateMap();
      } on Object catch (error, stackTrace) {
        debugPrint('[AgusMapsRuntime] map invalidation failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
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

      final actualSha256 = await _sha256Hex(file);
      if (metadata.sha256 == null ||
          metadata.sha256!.toLowerCase() != actualSha256) {
        debugPrint(
          '[AgusMapsRuntime] refusing map with invalid SHA-256: ' +
              metadata.regionName,
        );
        try {
          await file.delete();
        } catch (_) {}
        await _storage!.remove(metadata.regionName);
        continue;
      }

      final version = int.tryParse(metadata.snapshotVersion);
      final result = version != null
          ? agus.registerSingleMapWithVersion(metadata.filePath, version)
          : agus.registerSingleMap(metadata.filePath);
      debugPrint(
        '[AgusMapsRuntime] downloaded map registration: ' +
            metadata.regionName + ' result=' + result.toString(),
      );
      registeredAny = true;
      if (result != 0) {
        throw StateError(
          'Failed to register downloaded map ${metadata.regionName} '
          '(result $result).',
        );
      }
    }

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

  Future<String> _ensureBundledMap({
    required String assetPath,
    required int expectedSize,
    required String expectedSha1,
  }) async {
    final initialPath = await agus.extractMap(assetPath);
    final initialFile = File(initialPath);

    if (await _matchesBundledMap(
      initialFile,
      expectedSize: expectedSize,
      expectedSha1: expectedSha1,
    )) {
      return initialPath;
    }

    debugPrint(
      '[AgusMapsRuntime] replacing stale/corrupt bundled map: ' +
          initialFile.path,
    );

    if (await initialFile.exists()) {
      await initialFile.delete();
    }

    final freshPath = await agus.extractMap(assetPath);
    final freshFile = File(freshPath);
    final valid = await _matchesBundledMap(
      freshFile,
      expectedSize: expectedSize,
      expectedSha1: expectedSha1,
    );
    if (!valid) {
      throw StateError(
        'Bundled map integrity check failed for ' + assetPath,
      );
    }

    return freshPath;
  }

  Future<bool> _matchesBundledMap(
    File file, {
    required int expectedSize,
    required String expectedSha1,
  }) async {
    if (!await file.exists()) return false;

    final size = await file.length();
    if (size != expectedSize) return false;

    final digest = await sha1.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expectedSha1;
  }

  Future<String> _extractComapsDataSafely() async {
    var dataPath = await agus.extractDataFiles();

    if (await _comapsDataComplete(dataPath)) {
      return dataPath;
    }

    final marker = File(dataPath + '/.comaps_data_extracted');
    try {
      if (await marker.exists()) {
        await marker.delete();
      }
    } catch (error) {
      debugPrint(
        '[AgusMapsRuntime] could not reset CoMaps data marker: ' +
            error.toString(),
      );
    }

    dataPath = await agus.extractDataFiles();

    if (!await _comapsDataComplete(dataPath)) {
      throw StateError(
        'CoMaps data assets are incomplete after re-extraction.',
      );
    }

    return dataPath;
  }

  Future<bool> _comapsDataComplete(String dataPath) async {
    final required = <String>[
      'fonts/unicode_blocks.txt',
      'localized_types/en.lproj/LocalizableTypes.strings',
      'categories_brands.txt',
      'sound-strings/en.json/localize.json',
    ];

    for (final relative in required) {
      if (!await File(dataPath + '/' + relative).exists()) {
        return false;
      }
    }

    final symbols = <({String path, int minBytes})>[
      (path: 'symbols/xxhdpi/light/symbols.png', minBytes: 100000),
      (path: 'symbols/xxhdpi/light/symbols.sdf', minBytes: 1000),
      (path: 'symbols/xxhdpi/dark/symbols.png', minBytes: 100000),
      (path: 'symbols/xxhdpi/dark/symbols.sdf', minBytes: 1000),
    ];

    for (final item in symbols) {
      final file = File(dataPath + '/' + item.path);
      if (!await file.exists()) return false;
      if (await file.length() < item.minBytes) return false;
    }

    return true;
  }

  Future<void> _validatePersistedMaps() async {
    final storage = _storage;
    if (storage == null) return;

    for (final metadata in List<agus.MwmMetadata>.from(storage.getAll())) {
      if (metadata.isBundled) continue;

      final file = File(metadata.filePath);
      if (!await file.exists()) {
        await storage.remove(metadata.regionName);
        continue;
      }

      final actualSize = await file.length();
      final actualSha256 = await _sha256Hex(file);
      final invalidSize = metadata.fileSize > 0 && actualSize != metadata.fileSize;
      final invalidHash = metadata.sha256 == null ||
          metadata.sha256!.toLowerCase() != actualSha256;

      if (invalidSize || invalidHash) {
        debugPrint(
          '[AgusMapsRuntime] removing invalid persisted map: ' +
              metadata.regionName,
        );
        try {
          await file.delete();
        } catch (_) {}
        await storage.remove(metadata.regionName);
      }
    }
  }

  Future<String> _sha256Hex(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  Future<void> _cleanupPartialDownloads(String dataPath) async {
    final documents = await getApplicationDocumentsDirectory();
    final roots = <Directory>[
      Directory(dataPath),
      documents,
      Directory(documents.path + '/agus_maps_flutter/maps'),
    ];

    final seen = <String>{};
    for (final root in roots) {
      final key = root.path;
      if (!seen.add(key) || !await root.exists()) continue;

      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.mwm.download')) {
          try {
            await entity.delete();
            debugPrint(
              '[AgusMapsRuntime] removed partial map: ' + entity.path,
            );
          } catch (error) {
            debugPrint(
              '[AgusMapsRuntime] could not remove partial map: ' +
                  entity.path + ': ' + error.toString(),
            );
          }
        }
      }
    }
  }
}
