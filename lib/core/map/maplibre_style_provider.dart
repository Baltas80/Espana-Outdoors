import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MapLibreStyleProvider {
  const MapLibreStyleProvider();

  Future<String> load({String? localPmtilesPath}) async {
    const rawJson = String.fromEnvironment('MAP_STYLE_JSON');
    const styleUrl = String.fromEnvironment('MAP_STYLE_URL');
    const pmtilesUrl = String.fromEnvironment(
      'MAP_PMTILES_URL',
      defaultValue: 'https://pmtiles.io/protomaps(vector)ODbL_firenze.pmtiles',
    );

    String json;
    if (rawJson.isNotEmpty) {
      json = rawJson;
    } else if (styleUrl.isNotEmpty && localPmtilesPath == null) {
      final response = await http.get(Uri.parse(styleUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Map style request failed: ${response.statusCode}');
      }
      json = response.body;
    } else {
      json = await rootBundle.loadString('assets/map/default_style.json');
    }

    final decoded = jsonDecode(json);
    final pmtilesValue = localPmtilesPath == null
        ? 'pmtiles://$pmtilesUrl'
        : 'pmtiles://${Uri.file(localPmtilesPath)}';
    _replacePmtilesUrls(decoded, pmtilesValue);
    return jsonEncode(decoded);
  }

  void _replacePmtilesUrls(dynamic value, String pmtilesUrl) {
    if (value is Map) {
      for (final entry in value.entries.toList()) {
        if (entry.value is String &&
            (entry.value as String).contains('__PMTILES_URL__')) {
          value[entry.key] =
              (entry.value as String).replaceAll('__PMTILES_URL__', pmtilesUrl);
        } else {
          _replacePmtilesUrls(entry.value, pmtilesUrl);
        }
      }
    } else if (value is List) {
      for (final item in value) {
        _replacePmtilesUrls(item, pmtilesUrl);
      }
    }
  }

  Future<String?> findLatestLocalRegion() async {
    if (kIsWeb) return null;
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
}
