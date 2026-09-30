import 'dart:convert';
import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;

import '../offline/offline_package_verifier.dart';
import '../offline/offline_region.dart';
import '../offline/offline_region_store.dart';
import 'pmtiles_local_source.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');
const _directPmTilesUrl = String.fromEnvironment('MAP_PMTILES_URL');
const _styleUrl = String.fromEnvironment(
  'MAP_STYLE_URL',
  defaultValue: 'asset://assets/maps/offline_style.json',
);

Future<vt.Style> loadPmTilesStyle() async {
  // A verified archive already stored on the device is authoritative for
  // offline rendering. Do this before touching the remote catalog so loss of
  // connectivity cannot make an otherwise complete offline map unusable.
  final storedPath = await _findStoredVerifiedPmTiles();
  if (storedPath != null) return _readStyleFromLocal(storedPath);

  late final String sourceUrl;
  if (_directPmTilesUrl.isNotEmpty) {
    sourceUrl = _directPmTilesUrl;
  } else {
    final region = await _loadCatalogRegion();
    final expectedFileName =
        '${region.id}-${region.sha256.substring(0, 12)}.pmtiles';
    final verifiedPath = await findValidLocalPmTiles(
      expectedFileName: expectedFileName,
      expectedSha256: region.sha256,
    );
    if (verifiedPath != null) return _readStyleFromLocal(verifiedPath);
    sourceUrl = region.downloadUrl.toString();
  }

  if (!sourceUrl.startsWith('https://')) {
    throw StateError('La fuente PMTiles debe usar HTTPS.');
  }

  final provider = await vt.PmTilesVectorTileProvider.open(
    sourceUrl,
    logger: const vt.Logger.console(),
  );
  return _readStyleWithProvider(provider);
}

Future<vt.Style> _readStyleFromLocal(String path) async {
  final provider = await vt.PmTilesVectorTileProvider.open(
    path,
    logger: const vt.Logger.console(),
  );
  return _readStyleWithProvider(provider);
}

Future<vt.Style> _readStyleWithProvider(vt.VectorTileProvider provider) =>
    vt.StyleReader(
      uri: _styleUrl,
      resolveProvider: (sourceId) async =>
          sourceId == 'openmaptiles' ? provider : null,
      logger: const vt.Logger.console(),
    ).read();

Future<String?> _findStoredVerifiedPmTiles() async {
  final record = OfflineRegionStore().get('spain');
  if (record == null || !record.hasValidArtifact) return null;

  final path = record.localPath?.trim();
  final sha256 = record.sha256?.trim().toLowerCase();
  if (path == null || path.isEmpty ||
      sha256 == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
    return null;
  }

  final file = File(path);
  if (!await file.exists()) return null;

  try {
    await const OfflinePackageVerifier().verifyFile(
      file,
      expectedSha256: sha256,
    );
    return file.path;
  } on Object {
    return null;
  }
}

Future<OfflineRegion> _loadCatalogRegion() async {
  if (_catalogUrl.isEmpty) {
    throw StateError(
      'No hay PMTiles configurado: falta MAP_PMTILES_URL y OFFLINE_CATALOG_URL.',
    );
  }

  final response = await http
      .get(Uri.parse(_catalogUrl))
      .timeout(const Duration(seconds: 12));

  if (response.statusCode != 200) {
    throw StateError(
      'No se pudo cargar el catálogo cartográfico (${response.statusCode}).',
    );
  }

  final decoded = jsonDecode(response.body);
  Map<String, Object?>? raw;

  if (decoded is Map) {
    raw = Map<String, Object?>.from(decoded);
  } else if (decoded is List) {
    final entries = decoded
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
    for (final entry in entries) {
      if (entry['id']?.toString().toLowerCase() == 'spain') {
        raw = entry;
        break;
      }
    }
    raw ??= entries.isEmpty ? null : entries.first;
  }

  if (raw == null) {
    throw StateError('El catálogo cartográfico no tiene un formato válido.');
  }

  return OfflineRegion.fromJson(raw);
}
