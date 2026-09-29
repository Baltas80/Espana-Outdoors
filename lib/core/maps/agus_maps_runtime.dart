import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

final class AgusMapsRuntime {
  AgusMapsRuntime._();
  static final AgusMapsRuntime instance = AgusMapsRuntime._();

  Future<void>? _initializing;
  agus.MwmStorage? _storage;
  String? _dataPath;
  int? _bundledVersion;
  bool _surfaceReady = false;

  agus.MwmStorage? get storage => _storage;
  String? get dataPath => _dataPath;
  int? get bundledVersion => _bundledVersion;
  bool get surfaceReady => _surfaceReady;

  Future<void> ensureInitialized() => _initializing ??= _initialize();

  Future<void> _initialize() async {
    _storage = await agus.MwmStorage.create();
    final dataPath = await agus.extractDataFiles();
    _dataPath = dataPath;
    await _copyAssetToDataPath('assets/maps/icudt75l.dat', dataPath);

    _bundledVersion = await _readBundledVersion(dataPath);
    if (_bundledVersion == null) {
      throw StateError('No se ha encontrado la versión MWM del SDK de Agus Maps.');
    }

    await _prepareBundledMap(
      'assets/maps/World.mwm',
      dataPath,
      _bundledVersion!,
    );
    await _prepareBundledMap(
      'assets/maps/WorldCoasts.mwm',
      dataPath,
      _bundledVersion!,
    );

    agus.initWithPaths(dataPath, dataPath);
    agus.setLocale(ui.PlatformDispatcher.instance.locale.toLanguageTag());
    await _cleanupPartialDownloads(dataPath);
  }

  Future<int?> _readBundledVersion(String dataPath) async {
    try {
      final marker = await rootBundle.loadString('assets/maps/.mwm_version');
      final parsed = int.tryParse(marker.trim());
      if (parsed != null) return parsed;
    } catch (_) {}

    final countries = File(dataPath + '/countries.txt');
    if (!await countries.exists()) return null;
    final contents = await countries.readAsString();
    final match = RegExp(r'"v"\s*:\s*(\d+)').firstMatch(contents);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  Future<void> _copyAssetToDataPath(String asset, String dataPath) async {
    final extractedPath = await agus.extractMap(asset);
    final source = File(extractedPath);
    final target = File(dataPath + '/' + source.uri.pathSegments.last);
    if (source.path == target.path) return;
    if (!await target.exists() || await source.length() != await target.length()) {
      await source.copy(target.path);
    }
  }

  Future<String> _prepareBundledMap(
    String asset,
    String dataPath,
    int version,
  ) async {
    final extractedPath = await agus.extractMap(asset);
    final source = File(extractedPath);
    final fileName = source.uri.pathSegments.last;
    final target = File(dataPath + '/' + fileName);

    if (!await target.exists() || await source.length() != await target.length()) {
      await source.copy(target.path);
    }

    await _storage?.upsert(
      agus.MwmMetadata(
        regionName: fileName.substring(0, fileName.length - 4),
        snapshotVersion: version.toString(),
        fileSize: await target.length(),
        downloadDate: DateTime.now(),
        filePath: target.path,
        isBundled: true,
      ),
    );
    return target.path;
  }

  Future<void> onMapReady() async {
    await ensureInitialized();
    _surfaceReady = true;
    await registerDownloadedMaps();
  }

  Future<void> registerDownloadedMaps() async {
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
    final roots = <Directory>[Directory(dataPath)];
    try {
      roots.add(await getApplicationDocumentsDirectory());
    } catch (_) {}

    for (final root in roots) {
      if (!await root.exists()) continue;
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.mwm.download')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }
}
