import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/contracts/routing_service.dart';

/// Thin provider adapter around the mature Valhalla HTTP engine.
/// Routing algorithms remain outside the application.
class ValhallaRoutingService implements RoutingService {
  ValhallaRoutingService({required Uri baseUri, http.Client? client})
      : _baseUri = baseUri,
        _client = client ?? http.Client();

  final Uri _baseUri;
  final http.Client _client;

  @override
  Future<RouteResult> route(RouteRequest request) async {
    if (request.points.length < 2) {
      throw ArgumentError('At least two route points are required.');
    }
    final response = await _post('route', {
      'locations': [
        for (final p in request.points) {'lat': p.latitude, 'lon': p.longitude}
      ],
      'costing': _costing(request.profile),
      'units': 'kilometers',
      'shape_format': 'geojson',
    });
    return _parseTrip(response);
  }

  @override
  Future<RouteResult> match(List<LatLng> track) async {
    if (track.length < 2) {
      throw ArgumentError('At least two track points are required.');
    }
    final response = await _post('trace_route', {
      'shape': [
        for (final p in track) {'lat': p.latitude, 'lon': p.longitude}
      ],
      'costing': 'pedestrian',
      'shape_match': 'map_snap',
      'units': 'kilometers',
      'shape_format': 'geojson',
    });
    return _parseTrip(response);
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      _baseUri.resolve(endpoint),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Valhalla $endpoint failed: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Invalid Valhalla response.');
    }
    return decoded;
  }

  RouteResult _parseTrip(Map<String, dynamic> json) {
    final trip = json['trip'];
    if (trip is! Map<String, dynamic>) {
      throw FormatException('Valhalla response does not contain a trip.');
    }
    final legs = trip['legs'];
    if (legs is! List) {
      throw FormatException('Valhalla trip does not contain legs.');
    }

    final points = <LatLng>[];
    var distanceKm = 0.0;
    var durationMinutes = 0.0;

    for (final item in legs) {
      if (item is! Map<String, dynamic>) continue;
      final summary = item['summary'];
      if (summary is Map<String, dynamic>) {
        distanceKm += (summary['length'] as num?)?.toDouble() ?? 0;
        durationMinutes += (summary['time'] as num?)?.toDouble() ?? 0;
      }
      final shape = item['shape'];
      if (shape is Map<String, dynamic>) {
        final coordinates = shape['coordinates'];
        if (coordinates is List) {
          for (final coordinate in coordinates) {
            if (coordinate is List && coordinate.length >= 2 &&
                coordinate[0] is num && coordinate[1] is num) {
              points.add(LatLng(
                (coordinate[1] as num).toDouble(),
                (coordinate[0] as num).toDouble(),
              ));
            }
          }
        }
      }
    }

    return RouteResult(
      points: points,
      distanceMeters: distanceKm * 1000,
      durationSeconds: durationMinutes * 60,
    );
  }

  String _costing(String profile) {
    switch (profile.toLowerCase()) {
      case 'cycling':
      case 'bike':
        return 'bicycle';
      case 'driving':
      case 'car':
        return 'auto';
      case 'hiking':
      case 'walking':
      default:
        return 'pedestrian';
    }
  }
}
