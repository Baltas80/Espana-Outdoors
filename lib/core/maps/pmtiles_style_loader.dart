import 'dart:convert';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;

import 'pmtiles_local_source.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');
const _directPmTilesUrl = String.fromEnvironment('MAP_PMTILES_URL');
const _styleUrl = String.fromEnvironment(
  'MAP_STYLE_URL',
  defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
);

Future<vt.Style> loadPmTilesStyle() async {
  // A verified local region is authoritative when present. This is what makes
  // a downloaded region usable without the catalog endpoint or tile network.
  final localPath = await findLocalPmTiles();
  String? remoteUrl;

  if (localPath == null) {
    if (_directPmTilesUrl.isNotEmpty) {
      remoteUrl = _directPmTilesUrl;
    } else {
      if (_catalogUrl.isEmpty) {
        throw StateError(
          'No hay PMTiles configurado: falta MAP_PMTILES_URL y OFFLINE_CATALOG_URL.',
        );
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
      remoteUrl = downloadUrl;
    }

    if (!remoteUrl.startsWith('https://')) {
      throw StateError('La fuente PMTiles debe usar HTTPS.');
    }
  }

  final provider = await vt.PmTilesVectorTileProvider.open(
    localPath ?? remoteUrl!,
    logger: const vt.Logger.console(),
  );

  return vt.StyleReader(
    uri: _styleUrl,
    resolveProvider: (sourceId) async =>
        sourceId == 'openmaptiles' ? provider : null,
    logger: const vt.Logger.console(),
  ).read();
}
