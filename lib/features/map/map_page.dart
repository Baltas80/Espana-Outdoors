import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/map/maplibre_style_provider_io.dart';

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
          Positioned.fill(
            child: _OfflineVectorMap(position: location.position),
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

class _OfflineVectorMap extends StatefulWidget {
  const _OfflineVectorMap({required this.position});

  final Position? position;

  @override
  State<_OfflineVectorMap> createState() => _OfflineVectorMapState();
}

class _OfflineVectorMapState extends State<_OfflineVectorMap>
    with WidgetsBindingObserver {
  final MapController _mapController = MapController();

  vt.Style? _style;
  String? _error;
  String? _pmtilesPath;
  LatLng? _lastCenteredPosition;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadMap());
  }

  Future<void> _loadMap() async {
    try {
      final local = await findLatestLocalPmtiles();
      if (local == null) {
        throw StateError(
          'No hay ningún mapa offline descargado. Descarga España desde Mapas offline.',
        );
      }

      final style = await vt.StyleReader(
        uri: 'asset://assets/map/offline_vector_style.json',
        resolveProvider: (id) async {
          if (id != 'openmaptiles') return null;
          return vt.PmTilesVectorTileProvider.open(local);
        },
      ).read();

      if (!mounted) {
        style.dispose();
        return;
      }

      setState(() {
        _pmtilesPath = local;
        _style = style;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  void _recenterIfNeeded(Position? position) {
    if (position == null) return;
    final target = LatLng(position.latitude, position.longitude);
    final previous = _lastCenteredPosition;
    if (previous != null &&
        (previous.latitude - target.latitude).abs() < 0.00001 &&
        (previous.longitude - target.longitude).abs() < 0.00001) {
      return;
    }
    _lastCenteredPosition = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(target, math.max(14, _mapController.camera.zoom));
      } catch (_) {
        // MapController is not attached during the first frame.
      }
    });
  }

  @override
  void didUpdateWidget(covariant _OfflineVectorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.position != oldWidget.position) {
      _recenterIfNeeded(widget.position);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _style == null) {
      unawaited(_loadMap());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _style?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    if (_error != null) {
      return _MapError(message: _error!, onRetry: _loadMap);
    }
    if (style == null || _pmtilesPath == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final position = widget.position;
    final center = position == null
        ? const LatLng(40.4168, -3.7038)
        : LatLng(position.latitude, position.longitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: position == null ? 6.0 : 14.0,
        minZoom: 4.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        vt.VectorTileLayer(
          theme: style.theme,
          tileProviders: style.providers,
          rasterSources: style.rasterSources,
          sprites: style.sprites,
          showLabels: true,
          concurrency: 3,
          diskCacheMaximumSizeInBytes: 80 * 1024 * 1024,
          memoryCacheMaxBytes: 32 * 1024 * 1024,
          tileFadeDuration: const Duration(milliseconds: 120),
          labelFadeDuration: const Duration(milliseconds: 120),
          logger: const vt.Logger.console(),
        ),
        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: center,
                width: 32,
                height: 32,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(blurRadius: 5, color: Colors.black26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => unawaited(onRetry()),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
