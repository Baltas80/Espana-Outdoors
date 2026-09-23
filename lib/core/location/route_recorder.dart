import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/outdoor_models.dart';
import '../gpx/gpx_import_service.dart';
import '../storage/local_route_store.dart';

final routeRecorderProvider =
    NotifierProvider<RouteRecorder, RouteRecordingState>(RouteRecorder.new);

class RouteRecordingState {
  const RouteRecordingState({
    this.isRecording = false,
    this.points = const [],
    this.distanceMeters = 0,
    this.startedAt,
  });

  final bool isRecording;
  final List<GeoPoint> points;
  final double distanceMeters;
  final DateTime? startedAt;

  RouteRecordingState copyWith({
    bool? isRecording,
    List<GeoPoint>? points,
    double? distanceMeters,
    DateTime? startedAt,
  }) {
    return RouteRecordingState(
      isRecording: isRecording ?? this.isRecording,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

class RouteRecorder extends Notifier<RouteRecordingState> {
  StreamSubscription<Position>? _subscription;
  final List<Position> _positions = <Position>[];

  @override
  RouteRecordingState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const RouteRecordingState();
  }

  Future<void> start() async {
    if (state.isRecording) return;

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Activa la ubicación del dispositivo para grabar.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('No hay permiso de ubicación para grabar la ruta.');
    }

    _positions.clear();
    state = RouteRecordingState(
      isRecording: true,
      startedAt: DateTime.now().toUtc(),
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  Future<ImportedTrack?> stop() async {
    await _subscription?.cancel();
    _subscription = null;

    final recorded = _buildTrack();
    if (recorded != null) {
      await LocalRouteStore().saveImportedTrack(recorded);
    }

    state = const RouteRecordingState();
    _positions.clear();
    return recorded;
  }

  void _onPosition(Position position) {
    _positions.add(position);

    final point = GeoPoint(
      latitude: position.latitude,
      longitude: position.longitude,
    );

    final previous = state.points.isEmpty ? null : state.points.last;
    final nextDistance = previous == null
        ? state.distanceMeters
        : state.distanceMeters +
            Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              point.latitude,
              point.longitude,
            );

    state = state.copyWith(
      points: [...state.points, point],
      distanceMeters: nextDistance,
    );
  }

  ImportedTrack? _buildTrack() {
    if (_positions.isEmpty || state.points.isEmpty) return null;

    final elevations = _positions
        .map<double?>(
          (position) =>
              position.altitude.isFinite ? position.altitude : null,
        )
        .toList(growable: false);
    final timestamps = _positions
        .map<DateTime?>((position) => position.timestamp.toUtc())
        .toList(growable: false);

    var ascentMeters = 0.0;
    var descentMeters = 0.0;
    for (var i = 1; i < elevations.length; i++) {
      final previous = elevations[i - 1];
      final current = elevations[i];
      if (previous == null || current == null) continue;
      final delta = current - previous;
      if (delta > 0) {
        ascentMeters += delta;
      } else {
        descentMeters -= delta;
      }
    }

    final validTimes = timestamps.whereType<DateTime>().toList(growable: false);
    return ImportedTrack(
      name: 'Ruta ${DateTime.now().toLocal().toString().substring(0, 16)}',
      points: List.unmodifiable(state.points),
      distanceMeters: state.distanceMeters,
      ascentMeters: ascentMeters,
      descentMeters: descentMeters,
      startedAt: validTimes.firstOrNull,
      endedAt: validTimes.lastOrNull,
      elevationsMeters: elevations,
      timestamps: timestamps,
    );
  }
}
