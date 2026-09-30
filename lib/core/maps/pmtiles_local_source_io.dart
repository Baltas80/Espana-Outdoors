import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> findLocalPmTiles() async {
  final root = await getApplicationSupportDirectory();
  final directory = Directory('${root.path}${Platform.pathSeparator}offline_regions');
  if (!await directory.exists()) return null;

  final candidates = <File>[];
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.pmtiles')) {
      candidates.add(entity);
    }
  }

  candidates.sort((a, b) => a.path.compareTo(b.path));
  for (final file in candidates) {
    try {
      if (await file.length() > 0) return file.path;
    } on FileSystemException {
      // A concurrently removed/incomplete download is simply skipped.
    }
  }
  return null;
}
