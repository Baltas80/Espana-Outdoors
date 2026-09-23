import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

final locationControllerProvider =
    NotifierProvider<LocationController, LocationState>(LocationController.new);

class LocationState {
  const LocationState({
    this.position,
    this.message = 'Pulsa el botón para usar tu ubicación.',
  });

  final Position? position;
  final String message;

  LocationState copyWith({Position? position, String? message}) => LocationState(
        position: position ?? this.position,
        message: message ?? this.message,
      );
}

class LocationController extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  Future<void> locate() async {
    state = const LocationState(message: 'Obteniendo ubicación…');
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = const LocationState(
          message: 'Activa la ubicación del dispositivo para continuar.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        state = const LocationState(
          message: 'Permiso de ubicación no disponible.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      state = LocationState(
        position: position,
        message: 'Ubicación obtenida.',
      );
    } catch (_) {
      state = const LocationState(
        message: 'No se ha podido obtener la ubicación. Comprueba el GPS e inténtalo de nuevo.',
      );
    }
  }
}