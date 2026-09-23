import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/map/maplibre_style_provider.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    final recording = ref.watch(routeRecorderProvider);
    final recorder = ref.read(routeRecorderProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Navegación GPS',
            onPressed: () => context.push('/navigation'),
            icon: const Icon(Icons.navigation_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _MapLibreSurface()),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      recording.isRecording
                          ? Icons.fiber_manual_record
                          : Icons.map_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recording.isRecording
                            ? 'Grabando ${(recording.distanceMeters / 1000).toStringAsFixed(2)} km'
                            : location.message,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 88,
            child: FloatingActionButton(
              tooltip:
                  recording.isRecording ? 'Detener grabación' : 'Grabar ruta',
              onPressed: () async {
                try {
                  if (recording.isRecording) {
                    await recorder.stop();
                  } else {
                    await recorder.start();
                  }
                } on Object catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error.toString())),
                  );
                }
              },
              child: Icon(
                recording.isRecording
                    ? Icons.stop
                    : Icons.fiber_manual_record,
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 152,
            child: FloatingActionButton.small(
              tooltip: 'Navegación GPS',
              onPressed: () => context.push('/navigation'),
              child: const Icon(Icons.navigation_outlined),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              tooltip: 'Usar mi ubicación',
              onPressed: () =>
                  ref.read(locationControllerProvider.notifier).locate(),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLibreSurface extends StatefulWidget {
  const _MapLibreSurface();

  @override
  State<_MapLibreSurface> createState() => _MapLibreSurfaceState();
}

class _MapLibreSurfaceState extends State<_MapLibreSurface>
    with WidgetsBindingObserver {
  final _styles = const MapLibreStyleProvider();
  String? _style;
  String? _error;
  DateTime? _backgroundedAt;
  int _mapEpoch = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    try {
      final local = await _styles.findLatestLocalRegion();
      final location = null;
      final style = await _styles.load(localPmtilesPath: local);
      if (!mounted) return;
      setState(() {
        _style = style;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _backgroundedAt ??= DateTime.now();
    }
    if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!);
      _backgroundedAt = null;
      if (elapsed >= const Duration(minutes: 2)) {
        setState(() => _mapEpoch++);
        _loadStyle();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar el mapa: $_error'),
        ),
      );
    }

    final style = _style;
    if (style == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ml.MapLibreMap(
      key: ValueKey(_mapEpoch),
      styleString: style,
      initialCameraPosition: const ml.CameraPosition(
        target: ml.LatLng(40.4168, -3.7038),
        zoom: 6,
      ),
      myLocationEnabled: true,
      myLocationTrackingMode: ml.MyLocationTrackingMode.none,
      compassEnabled: true,
      attributionButtonMargins: const math.Point(12, 12),
    );
  }
}
