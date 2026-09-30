import 'dart:convert';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;

import '../offline/offline_region.dart';
import 'pmtiles_local_source.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');
const _directPmTilesUrl = String.fromEnvironment('MAP_PMTILES_URL');
const _styleUrl = String.fromEnvironment(
  'MAP_STYLE_URL',
  defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
);

Future<vt.Style> loadPmTilesStyle() async {
  String? localPath;
  late final String sourceUrl;

  if (_directPmTilesUrl.isNotEmpty) {
    sourceUrl = _directPmTilesUrl;
  } else {
    final region = await _loadCatalogRegion();
    final expectedFileName =
        '${region.id}-${region.sha256.substring(0, 12)}.pmtiles';
    localPath = await findValidLocalPmTiles(
      expectedFileName: expectedFileName,
      expectedSha256: region.sha256,
    );
    sourceUrl = region.downloadUrl.toString();
  }

  if (localPath == null && !sourceUrl.startsWith('https://')) {
    throw StateError('La fuente PMTiles debe usar HTTPS.');
  }

  final provider = await vt.PmTilesVectorTileProvider.open(
    localPath ?? sourceUrl,
    logger: const vt.Logger.console(),
  );

  return vt.StyleReader(
    uri: _styleUrl,
    resolveProvider: (sourceId) async =>
        sourceId == 'openmaptiles' ? provider : null,
    logger: const vt.Logger.console(),
  ).read();
}

Future<OfflineRegion> _loadCatalogRegion() async {
  if (_catalogUrl.isEmpty) {
    throw StateError(
      'No hay PMTiles configurado: falta MAP_PMTILES_URL y OFFLINE_CATALOG_URL.',
    );
  }

  final response = await http
      .get(Uri.parse(_catalogUrl))
      .timeout(const Duration(seconds: 20));

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
