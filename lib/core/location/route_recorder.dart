import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/outdoor_models.dart';

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

    state = RouteRecordingState(
      isRecording: true,
      startedAt: DateTime.now(),
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    state = state.copyWith(isRecording: false);
  }

  void _onPosition(Position position) {
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
}
