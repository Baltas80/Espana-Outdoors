import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'maplibre_style_provider_web.dart'
    if (dart.library.io) 'maplibre_style_provider_io.dart';

class MapLibreStyleProvider {
  const MapLibreStyleProvider();

  Future<String> load({String? localPmtilesPath}) async {
    const rawJson = String.fromEnvironment('MAP_STYLE_JSON');
    const styleUrl = String.fromEnvironment('MAP_STYLE_URL');
    const pmtilesUrl = String.fromEnvironment('MAP_PMTILES_URL');

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

    if (pmtilesUrl.isEmpty && localPmtilesPath == null) {
      throw StateError(
        'MAP_PMTILES_URL is not configured. Configure an España Outdoor-owned or approved PMTiles endpoint before starting the map.',
      );
    }

    final decoded = jsonDecode(json);
    final pmtilesValue = localPmtilesPath == null
        ? 'pmtiles://$pmtilesUrl'
        : 'pmtiles://file://${Uri.file(localPmtilesPath).path}';
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

  Future<String?> findLatestLocalRegion({LatLng? location}) =>
      findLatestLocalPmtiles(location: location);
}
