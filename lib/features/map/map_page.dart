import 'dart:async';

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/maps/agus_maps_runtime.dart';

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final agus.AgusMapController _controller = agus.AgusMapController();
  Future<void>? _runtimeFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _runtimeFuture = AgusMapsRuntime.instance.ensureInitialized();
      });
    });
  }

  void _onMapReady(Position? position) {
    // The widget already receives the initial viewport through initialLat/
    // initialLon. Avoid issuing an immediate native camera mutation while the
    // SurfaceTexture/CoMaps framework is settling on Android.
    unawaited(AgusMapsRuntime.instance.onMapReady());
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final recording = ref.watch(routeRecorderProvider);
    final recorder = ref.read(routeRecorderProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        actions: [
          IconButton(
            tooltip: 'Mapas offline',
            onPressed: () => context.push('/offline'),
            icon: const Icon(Icons.download_outlined),
          ),
          IconButton(
            tooltip: 'Navegación GPS',
            onPressed: () => context.push('/navigation'),
            icon: const Icon(Icons.navigation_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _runtimeFuture,
              builder: (context, snapshot) {
                if (_runtimeFuture == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MapMessage(
                    title: 'No se puede iniciar la cartografía',
                    message: snapshot.error.toString(),
                    actionLabel: 'Mapas offline',
                    onAction: () => context.push('/offline'),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final position = location.position;
                return agus.AgusMap(
                  controller: _controller,
                  initialLat: position?.latitude ?? 40.4168,
                  initialLon: position?.longitude ?? -3.7038,
                  initialZoom: position == null ? 7 : 14,
                  onMapReady: () => _onMapReady(position),
                  userScale: 1.0,
                  isVisible: true,
                );
              },
            ),
          ),
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
                recording.isRecording ? Icons.stop : Icons.fiber_manual_record,
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
              onPressed: () async {
                await ref.read(locationControllerProvider.notifier).locate();
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.download_outlined),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
