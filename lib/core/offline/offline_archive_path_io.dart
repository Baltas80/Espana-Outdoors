import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String> offlineArchivePath(String regionId) async {
  final root = await getApplicationSupportDirectory();
  final safeId = regionId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  final directory = Directory(
    '${root.path}${Platform.pathSeparator}offline_maps',
  );
  await directory.create(recursive: true);
  return '${directory.path}${Platform.pathSeparator}$safeId.mbtiles';
}