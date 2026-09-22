import 'dart:convert';

import 'package:http/http.dart' as http;

import 'elevation_models.dart';
import 'routing_models.dart';
import 'routing_service.dart';

class ValhallaElevationService implements ElevationService {
  ValhallaElevationService({required Uri baseUri, http.Client? client})
      : _baseUri = baseUri,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  String get providerId => 'valhalla-elevation';

  @override
  Future<ElevationProfile> profile(List<RouteWaypoint> points) async {
    if (points.isEmpty) {
      throw ArgumentError.value(
        points,
        'points',
        'debe contener al menos un punto',
      );
    }

    final response = await _client
        .post(
          _baseUri.resolve('/height'),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode({
            'range': true,
            'height_precision': 1,
            'shape': points
                .map((point) => {'lat': point.latitude, 'lon': point.longitude})
                .toList(growable: false),
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Valhalla elevation devolvió HTTP ${response.statusCode}.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Respuesta de elevación inválida.');
    }

    final raw = decoded['range_height'];
    if (raw is! List) {
      throw StateError('Respuesta de elevación sin range_height.');
    }

    final samples = raw.map<ElevationSample>((item) {
      if (item is! List || item.length < 2 || item[1] == null) {
        return const ElevationSample(meters: null);
      }
      final value = item[1];
      return ElevationSample(
        meters: value is num ? value.toDouble() : double.tryParse('$value'),
      );
    }).toList(growable: false);

    return ElevationProfile(
      samples: List.unmodifiable(samples),
      quality: samples.any((sample) => sample.meters != null)
          ? ElevationQuality.measured
          : ElevationQuality.unavailable,
      providerId: providerId,
      sourceTimestamp: DateTime.now().toUtc(),
    );
  }
}
