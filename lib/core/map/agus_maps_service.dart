import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;
import 'package:agus_maps_flutter/mirror_service.dart';
import 'package:agus_maps_flutter/mwm_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

final class AgusMapsService {
  AgusMapsService._();
  static final AgusMapsService instance = AgusMapsService._();

  final MirrorService _mirrorService = MirrorService();
  final ValueNotifier<double?> downloadProgress = ValueNotifier<double?>(null);
  final ValueNotifier<bool> spainInstalled = ValueNotifier<bool>(false);

  MwmStorage? _storage;
  String? _dataPath;
  int? _bundledVersion;
  final List<String> _bundledMapPaths = <String>[];
  Future<void>? _initialization;
  bool _initialized = false;
  bool _mapSurfaceReady = false;

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    if (_initialized) return;
    _storage = await MwmStorage.create();
    await _cleanupPartialDownloads();
    if (await _storage!.hasOrphanedMetadata()) {
      await _storage!.pruneOrphaned();
    }

    final worldPath = await agus.extractMap('assets/maps/World.mwm');
    final coastPath = await agus.extractMap('assets/maps/WorldCoasts.mwm');
    await agus.extractMap('assets/maps/icudt75l.dat');

    _bundledMapPaths..clear()..addAll([worldPath, coastPath]);

    await _storage!.upsert(MwmMetadata(
      regionName: 'World',
      snapshotVersion: 'bundled',
      fileSize: await File(worldPath).length(),
      downloadDate: DateTime.now(),
      filePath: worldPath,
      isBundled: true,
    ));
    await _storage!.upsert(MwmMetadata(
      regionName: 'WorldCoasts',
      snapshotVersion: 'bundled',
      fileSize: await File(coastPath).length(),
      downloadDate: DateTime.now(),
      filePath: coastPath,
      isBundled: true,
    ));

    _dataPath = await agus.extractDataFiles();
    _bundledVersion = await _readVersion(_dataPath!);
    agus.initWithPaths(_dataPath!, _dataPath!);

    final spain = _storage!.getByRegion('Spain');
    spainInstalled.value =
        spain != null && await File(spain.filePath).exists();
    _initialized = true;
  }

  Future<void> markMapSurfaceReady() async {
    await initialize();
    _mapSurfaceReady = true;
    await registerInstalledMaps();
  }

  Future<void> registerInstalledMaps() async {
    if (!_initialized || !_mapSurfaceReady) return;
    final version = _bundledVersion;

    for (final path in _bundledMapPaths) {
      if (version != null) {
        agus.registerSingleMapWithVersion(path, version);
      } else {
        agus.registerSingleMap(path);
      }
    }

    final storage = _storage;
    if (storage != null) {
      for (final metadata in storage.getAll()) {
        if (metadata.isBundled) continue;
        final file = File(metadata.filePath);
        if (!await file.exists()) continue;
        final mapVersion = int.tryParse(metadata.snapshotVersion);
        if (mapVersion != null) {
          agus.registerSingleMapWithVersion(metadata.filePath, mapVersion);
        } else {
          agus.registerSingleMap(metadata.filePath);
        }
      }
    }

    agus.invalidateMap();
    agus.forceRedraw();
  }

  Future<void> downloadSpain() async {
    await initialize();
    if (spainInstalled.value) {
      await registerInstalledMaps();
      return;
    }

    downloadProgress.value = 0.0;
    try {
      final discoveries = await _mirrorService.discoverMirrors();
      final operational = discoveries.where((item) => item.isOperational).toList();
      if (operational.isEmpty) {
        throw StateError('No hay servidores de mapas CoMaps disponibles.');
      }

      final selected = operational.first;
      final snapshot = selected.latestSnapshot!;
      final regions = await _mirrorService.getRegions(selected.mirror, snapshot);
      MwmRegion? spain;
      for (final region in regions) {
        if (region.fileName.toLowerCase() == 'spain.mwm' ||
            region.name.toLowerCase() == 'spain') {
          spain = region;
          break;
        }
      }
      if (spain == null) {
        throw StateError('El mapa de España no está disponible.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final mapsDir = Directory('${directory.path}/agus_maps_flutter/maps');
      await mapsDir.create(recursive: true);
      final filePath = '${mapsDir.path}/${spain.fileName}';
      final tempFile = File('$filePath.download');
      final targetFile = File(filePath);
      final url = _mirrorService.getDownloadUrl(
        selected.mirror,
        snapshot,
        spain,
      );

      final bytes = await _mirrorService.downloadToFile(
        url,
        tempFile,
        onProgress: (received, total) {
          if (total > 0) downloadProgress.value = received / total;
        },
      );

      if (bytes <= 0) {
        throw StateError('El archivo descargado está vacío.');
      }
      if (await targetFile.exists()) await targetFile.delete();
      await tempFile.rename(filePath);

      await _storage!.upsert(MwmMetadata(
        regionName: 'Spain',
        snapshotVersion: snapshot.version,
        fileSize: bytes,
        downloadDate: DateTime.now(),
        filePath: filePath,
        isBundled: false,
      ));

      spainInstalled.value = true;
      downloadProgress.value = 1.0;

      if (_mapSurfaceReady) {
        final version = int.tryParse(snapshot.version);
        if (version != null) {
          agus.registerSingleMapWithVersion(filePath, version);
        } else {
          agus.registerSingleMap(filePath);
        }
        agus.invalidateMap();
        agus.forceRedraw();
      }
    } finally {
      if (downloadProgress.value != 1.0) {
        downloadProgress.value = null;
      } else {
        scheduleMicrotask(() => downloadProgress.value = null);
      }
    }
  }

  Future<int?> _readVersion(String dataPath) async {
    try {
      final file = File('${dataPath}/countries.txt');
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map && decoded['v'] is num
          ? (decoded['v'] as num).toInt()
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _cleanupPartialDownloads() async {
    final directory = await getApplicationDocumentsDirectory();
    final dirs = <Directory>[
      directory,
      Directory('${directory.path}/agus_maps_flutter/maps'),
    ];
    for (final dir in dirs) {
      if (!await dir.exists()) continue;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.mwm.download')) {
          try {
            await entity.delete();
          } catch (_) {}
        }
      }
    }
  }

  MwmStorage? get storage => _storage;
}
