import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pmtiles/pmtiles.dart';

Future<String?> findLatestLocalPmtiles({LatLng? location}) async {
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

  if (location != null) {
    for (final file in files) {
      PmTilesArchive? archive;
      try {
        archive = await PmTilesArchive.from(file.path);
        final min = archive.minPosition;
        final max = archive.maxPosition;
        final contains = location.latitude >= min.latitude &&
            location.latitude <= max.latitude &&
            location.longitude >= min.longitude &&
            location.longitude <= max.longitude;
        if (contains) return file.path;
      } catch (_) {
        // Invalid archives are ignored; they must never become active.
      } finally {
        await archive?.close();
      }
    }
    // Do not activate an unrelated region when the current position is
    // outside every downloaded package.
    return null;
  }

  return files.first.path;
}