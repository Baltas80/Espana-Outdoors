import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<String?> findLatestLocalPmtiles() async {
  final directory = await getApplicationSupportDirectory();
  final regions = Directory('${directory.path}/offline_regions');
  if (!regions.existsSync()) return null;

  final files = regions
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.pmtiles'))
      .toList();
  if (files.isEmpty) return null;

  files.sort(
    (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
  );
  return files.first.path;
}
