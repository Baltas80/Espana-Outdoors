import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';

Future<TileProvider> openOfflineMbTiles(String path) async {
  if (path.trim().isEmpty) {
    throw ArgumentError.value(path, 'path', 'no puede estar vacío');
  }
  return MbTilesTileProvider.fromSource(path);
}
