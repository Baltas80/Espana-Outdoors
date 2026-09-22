import 'dart:convert';

import 'package:http/http.dart' as http;

import 'routing_models.dart';
import 'routing_service.dart';

class ValhallaRoutingService implements RoutingService {
  ValhallaRoutingService({
    required Uri baseUri,
    http.Client? client,
    this.timeout = const Duration(seconds: 20),
  })  : _baseUri = baseUri,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;
  final Duration timeout;

  @override
  String get providerId => 'valhalla';

  @override
  Future<RoutingResult> calculateRoute(RoutingRequest request) async {
    if (!request.isValid) {
      throw ArgumentError.value(request, 'request', 'routing request inválida');
    }

    final costing = switch (request.profile) {
      RoutingProfile.hiking ||
      RoutingProfile.walking ||
      RoutingProfile.trailRunning => 'pedestrian',
      RoutingProfile.cycling => 'bicycle',
    };

    final body = jsonEncode({
      'locations': request.waypoints
          .map((point) => {'lat': point.latitude, 'lon': point.longitude})
          .toList(growable: false),
      'costing': costing,
      'units': 'kilometers',
      'shape_format': 'polyline6',
      'language': 'es-ES',
      'narrative': true,
      'verbose': false,
    });

    final response = await _client
        .post(
          _baseUri.resolve('/route'),
          headers: const {'content-type': 'application/json'},
          body: body,
        )
        .timeout(timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Valhalla devolvió HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Respuesta Valhalla inválida.');
    }
    final trip = decoded['trip'];
    if (trip is! Map<String, dynamic>) {
      throw StateError('Respuesta Valhalla sin trip.');
    }
    final rawLegs = trip['legs'];
    if (rawLegs is! List || rawLegs.isEmpty) {
      throw StateError('Respuesta Valhalla sin legs.');
    }

    final legs = <RouteLeg>[];
    for (final rawLeg in rawLegs) {
      if (rawLeg is! Map<String, dynamic>) continue;
      final summary = rawLeg['summary'];
      final shape = rawLeg['shape'];
      if (summary is! Map<String, dynamic> ||
          shape is! String ||
          shape.isEmpty) {
        continue;
      }
      final lengthKm = (summary['length'] as num?)?.toDouble();
      final timeSeconds = (summary['time'] as num?)?.toDouble();
      if (lengthKm == null || timeSeconds == null) continue;
      legs.add(
        RouteLeg(
          distanceMeters: lengthKm * 1000,
          durationSeconds: timeSeconds,
          geometry: _decodePolyline6(shape),
        ),
      );
    }

    if (legs.isEmpty) {
      throw StateError('Valhalla no devolvió ninguna leg utilizable.');
    }
    return RoutingResult(
      legs: List.unmodifiable(legs),
      providerId: providerId,
      sourceTimestamp: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<double?>> sampleElevation(List<RouteWaypoint> points) {
    throw UnsupportedError('Use ValhallaElevationService para elevación.');
  }

  List<RouteWaypoint> _decodePolyline6(String encoded) {
    var index = 0;
    var latitude = 0;
    var longitude = 0;
    final result = <RouteWaypoint>[];

    int readValue() {
      var shift = 0;
      var value = 0;
      while (index < encoded.length) {
        final byte = encoded.codeUnitAt(index++) - 63;
        value |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }
      return (value & 1) == 1 ? ~(value >> 1) : (value >> 1);
    }

    while (index < encoded.length) {
      latitude += readValue();
      longitude += readValue();
      result.add(
        RouteWaypoint(
          latitude: latitude / 1e6,
          longitude: longitude / 1e6,
        ),
      );
    }
    return result;
  }
}
