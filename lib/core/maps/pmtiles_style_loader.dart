import 'dart:convert';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;

import 'pmtiles_local_source.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');
const _styleUrl = String.fromEnvironment(
  'MAP_STYLE_URL',
  defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
);

Future<vt.Style> loadPmTilesStyle() async {
  if (_catalogUrl.isEmpty) {
    throw StateError('OFFLINE_CATALOG_URL no está configurado.');
  }

  final catalogResponse = await http
      .get(Uri.parse(_catalogUrl))
      .timeout(const Duration(seconds: 20));
  if (catalogResponse.statusCode != 200) {
    throw StateError(
      'No se pudo cargar el catálogo cartográfico (${catalogResponse.statusCode}).',
    );
  }

  final decoded = jsonDecode(catalogResponse.body);
  if (decoded is! Map<String, dynamic>) {
    throw StateError('El catálogo cartográfico no tiene un formato válido.');
  }

  final downloadUrl = decoded['downloadUrl'];
  if (downloadUrl is! String || !downloadUrl.startsWith('https://')) {
    throw StateError('El catálogo no contiene un downloadUrl HTTPS válido.');
  }

  final localPath = await findLocalPmTiles();
  final provider = await vt.PmTilesVectorTileProvider.open(
    localPath ?? downloadUrl,
    logger: const vt.Logger.console(),
  );

  return vt.StyleReader(
    uri: _styleUrl,
    resolveProvider: (sourceId) async =>
        sourceId == 'openmaptiles' ? provider : null,
    logger: const vt.Logger.console(),
  ).read();
}
