import 'offline_region.dart';

/// Parses the public map catalog for the Spain basemap only.
///
/// A catalog may also contain regional packages. Those must never be used as
/// a silent fallback for the national basemap when the Spain entry is absent.
OfflineRegion parseSpainCatalogEntry(Object? decoded) {
  Map<String, Object?>? spainEntry;

  if (decoded is Map) {
    final entry = Map<String, Object?>.from(decoded);
    if (entry['id']?.toString().trim().toLowerCase() == 'spain') {
      spainEntry = entry;
    }
  } else if (decoded is List) {
    for (final item in decoded) {
      if (item is! Map) continue;
      final entry = Map<String, Object?>.from(item);
      if (entry['id']?.toString().trim().toLowerCase() == 'spain') {
        spainEntry = entry;
        break;
      }
    }
  } else {
    throw const FormatException(
      'Offline map catalog must be a JSON object or array.',
    );
  }

  if (spainEntry == null) {
    throw const FormatException(
      'Offline map catalog must contain a Spain entry with id "spain".',
    );
  }

  return OfflineRegion.fromJson(spainEntry);
}
