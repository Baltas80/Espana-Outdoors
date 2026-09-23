import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../domain/outdoor_models.dart';
import '../storage/route_recording_store.dart';

final routeRecorderProvider =
    NotifierProvider<RouteRecorder, RouteRecordingState>(RouteRecorder.new);

class RouteRecordingState {
  const RouteRecordingState({
    this.isRecording = false,
    this.points = const [],
    this.distanceMeters = 0,
    this.startedAt,
    this.hasRecoverableSession = false,
    this.persistenceHealthy = true,
  });

  final bool isRecording;
  final List<GeoPoint> points;
  final double distanceMeters;
  final DateTime? startedAt;
  final bool hasRecoverableSession;
  final bool persistenceHealthy;

  RouteRecordingState copyWith({
    bool? isRecording,
    List<GeoPoint>? points,
    double? distanceMeters,
    DateTime? startedAt,
    bool? hasRecoverableSession,
    bool? persistenceHealthy,
  }) {
    return RouteRecordingState(
      isRecording: isRecording ?? this.isRecording,
      points: points ?? this.points,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      startedAt: startedAt ?? this.startedAt,
      hasRecoverableSession:
          hasRecoverableSession ?? this.hasRecoverableSession,
      persistenceHealthy: persistenceHealthy ?? this.persistenceHealthy,
    );
  }
}

class RouteRecorder extends Notifier<RouteRecordingState> {
  StreamSubscription<Position>? _subscription;
  final RouteRecordingStore _store = RouteRecordingStore();
  Future<void> _persistTail = Future<void>.value();
  bool _disposed = false;

  @override
  RouteRecordingState build() {
    ref.onDispose(() {
      _disposed = true;
      final subscription = _subscription;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
    });
    unawaited(_restore());
    return const RouteRecordingState();
  }

  Future<void> _restore() async {
    final session = _store.recover();
    if (_disposed || session == null) return;
    state = RouteRecordingState(
      points: session.points,
      distanceMeters: session.distanceMeters,
      startedAt: session.startedAt,
      hasRecoverableSession: true,
    );
  }

  Future<void> start() async {
    if (state.isRecording) return;
    await _ensureLocationPermission();
    await _persistTail;
    final startedAt = DateTime.now().toUtc();
    await _store.begin(startedAt: startedAt);
    state = RouteRecordingState(isRecording: true, startedAt: startedAt);
    _listenForPositions();
  }

  Future<void> resume() async {
    if (state.isRecording) return;
    await _ensureLocationPermission();
    final session = _store.recover();
    if (session == null) {
      await start();
      return;
    }
    state = RouteRecordingState(
      isRecording: true,
      points: session.points,
      distanceMeters: session.distanceMeters,
      startedAt: session.startedAt,
      hasRecoverableSession: true,
    );
    _listenForPositions();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await _persistTail;
    await _store.finish();
    state = state.copyWith(
      isRecording: false,
      hasRecoverableSession: false,
    );
  }

  Future<void> _ensureLocationPermission() async {
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
  }

  void _listenForPositions() {
    _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: _locationSettings(),
    ).listen(_onPosition);
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: Duration(seconds: 5),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'España Outdoor',
          notificationText: 'Grabando tu ruta en segundo plano.',
          notificationChannelName: 'Seguimiento GPS',
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return const AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
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
      points: <GeoPoint>[...state.points, point],
      distanceMeters: nextDistance,
      persistenceHealthy: true,
    );
    _persistTail = _persistTail.then<void>((_) async {
      try {
        await _store.append(
          point: point,
          distanceMeters: nextDistance,
        );
      } on Object {
        if (!_disposed) {
          state = state.copyWith(persistenceHealthy: false);
        }
      }
    });
  }
}