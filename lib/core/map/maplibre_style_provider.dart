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

    String json;
    if (rawJson.isNotEmpty) {
      json = rawJson;
    } else if (styleUrl.isNotEmpty) {
      final response = await http.get(Uri.parse(styleUrl));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('Map style request failed: ${response.statusCode}');
      }
      json = response.body;
    } else {
      json = await rootBundle.loadString('assets/map/default_style.json');
    }

    if (localPmtilesPath != null && localPmtilesPath.isNotEmpty) {
      final localUri = 'pmtiles://${Uri.file(localPmtilesPath)}';
      final decoded = jsonDecode(json);
      _replacePmtilesUrls(decoded, localUri);
      json = jsonEncode(decoded);
    }
    return json;
  }

  void _replacePmtilesUrls(dynamic value, String localUri) {
    if (value is Map) {
      for (final entry in value.entries.toList()) {
        if (entry.value is String && (entry.value as String).contains('__PMTILES_URL__')) {
          value[entry.key] = (entry.value as String).replaceAll('__PMTILES_URL__', localUri);
        } else {
          _replacePmtilesUrls(entry.value, localUri);
        }
      }
    } else if (value is List) {
      for (final item in value) {
        _replacePmtilesUrls(item, localUri);
      }
    }
  }

  Future<String?> findLocalRegion(String regionId) async {
    if (kIsWeb) return null;
    final directory = await getApplicationSupportDirectory();
    final file = File('${directory.path}/offline_regions/$regionId.pmtiles');
    return file.existsSync() ? file.path : null;
  }
}
