import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/contracts/routing_service.dart';

/// Thin provider adapter around the mature Valhalla HTTP engine.
/// Routing algorithms remain outside the application.
class ValhallaRoutingService implements RoutingService {
  ValhallaRoutingService({required Uri baseUri, http.Client? client})
      : _baseUri = _normalizeBaseUri(baseUri),
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
      'directions_options': {'units': 'kilometers', 'language': 'es-ES'},
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
    final response = await _client
        .post(
          _baseUri.resolve(endpoint),
          headers: const {'content-type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
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
    final steps = <RouteStep>[];
    var distanceKm = 0.0;
    var durationSeconds = 0.0;

    for (final item in legs) {
      if (item is! Map<String, dynamic>) continue;
      final summary = item['summary'];
      if (summary is Map<String, dynamic>) {
        distanceKm += (summary['length'] as num?)?.toDouble() ?? 0;
        // Valhalla reports summary.time in seconds, not minutes.
        durationSeconds += (summary['time'] as num?)?.toDouble() ?? 0;
      }

      final maneuvers = item['maneuvers'];
      if (maneuvers is List) {
        for (final maneuver in maneuvers) {
          if (maneuver is! Map<String, dynamic>) continue;
          final instruction = maneuver['instruction'];
          if (instruction is! String || instruction.trim().isEmpty) continue;
          steps.add(
            RouteStep(
              instruction: instruction,
              distanceMeters: _number(maneuver['length'], multiplier: 1000),
              durationSeconds: _number(maneuver['time']),
              beginShapeIndex: (maneuver['begin_shape_index'] as num?)?.toInt(),
              endShapeIndex: (maneuver['end_shape_index'] as num?)?.toInt(),
            ),
          );
        }
      }

      final shape = item['shape'];
      if (shape is Map<String, dynamic>) {
        final coordinates = shape['coordinates'];
        if (coordinates is List) {
          for (final coordinate in coordinates) {
            if (coordinate is List &&
                coordinate.length >= 2 &&
                coordinate[0] is num &&
                coordinate[1] is num) {
              points.add(LatLng(
                (coordinate[1] as num).toDouble(),
                (coordinate[0] as num).toDouble(),
              ));
            }
          }
        }
      }
    }

    if (points.length < 2) {
      throw FormatException('Valhalla route did not contain a usable shape.');
    }

    return RouteResult(
      points: points,
      distanceMeters: distanceKm * 1000,
      durationSeconds: durationSeconds,
      steps: List.unmodifiable(steps),
    );
  }

  static double? _number(Object? value, {double multiplier = 1}) {
    final number = value as num?;
    return number == null ? null : number.toDouble() * multiplier;
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

  static Uri _normalizeBaseUri(Uri uri) {
    final path = uri.path.endsWith('/') ? uri.path : '${uri.path}/';
    return uri.replace(path: path);
  }
}
