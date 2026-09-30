import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');
const _mapAttribution = String.fromEnvironment(
  'MAP_ATTRIBUTION',
  defaultValue: '© OpenStreetMap contributors',
);

class MapPage extends ConsumerStatefulWidget {
  const MapPage({super.key});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  late Future<vt.Style> _styleFuture;

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyle();
  }

  Future<vt.Style> _loadStyle() async {
    if (_catalogUrl.isEmpty) {
      throw StateError('OFFLINE_CATALOG_URL no está configurado.');
    }

    final catalogResponse = await http.get(Uri.parse(_catalogUrl));
    if (catalogResponse.statusCode != 200) {
      throw StateError(
        'No se pudo cargar el catálogo cartográfico (${catalogResponse.statusCode}).',
      );
    }

    final decoded = jsonDecode(catalogResponse.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('El catálogo cartográfico no tiene un formato válido.');
    }

    final downloadUrl = decoded['downloadUrl'];
    if (downloadUrl is! String || !downloadUrl.startsWith('https://')) {
      throw StateError('El catálogo no contiene un downloadUrl HTTPS válido.');
    }

    final provider = await vt.PmTilesVectorTileProvider.open(
      downloadUrl,
      logger: const vt.Logger.console(),
    );

    // The visual style is independent from the tile storage. OpenFreeMap
    // provides the Liberty style/sprites/glyphs; our verified Spain PMTiles
    // archive supplies the actual vector tiles through HTTP Range Requests.
    return vt.StyleReader(
      uri: 'https://tiles.openfreemap.org/styles/liberty',
      resolveProvider: (sourceId) async {
        if (sourceId == 'openmaptiles') {
          return provider;
        }
        return null;
      },
      logger: const vt.Logger.console(),
    ).read();
  }

  @override
  void dispose() {
    _styleFuture.then((style) => style.dispose());
    super.dispose();
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
            child: FutureBuilder<vt.Style>(
              future: _styleFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MapMessage(
                    title: 'No se pudo cargar el mapa',
                    message: snapshot.error.toString(),
                    onRetry: () => setState(() {
                      _styleFuture = _loadStyle();
                    }),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final style = snapshot.data!;
                return FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(40.4168, -3.7038),
                    initialZoom: 6.2,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    vt.VectorTileLayer(
                      theme: style.theme,
                      tileProviders: style.providers,
                      rasterSources: style.rasterSources,
                      sprites: style.sprites,
                      logger: const vt.Logger.console(),
                    ),
                  ],
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
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.map_outlined),
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
            left: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Text(_mapAttribution, style: TextStyle(fontSize: 11)),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 88,
            child: FloatingActionButton(
              tooltip: recording.isRecording ? 'Detener grabación' : 'Grabar ruta',
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
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

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
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}


/// Reusable PMTiles viewport for secondary screens.
class PmTilesMapViewport extends StatefulWidget {
  const PmTilesMapViewport({
    super.key,
    this.initialCenter = const LatLng(40.4168, -3.7038),
    this.initialZoom = 7,
  });

  final LatLng initialCenter;
  final double initialZoom;

  @override
  State<PmTilesMapViewport> createState() => _PmTilesMapViewportState();
}

class _PmTilesMapViewportState extends State<PmTilesMapViewport> {
  late Future<vt.Style> _styleFuture;

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyle();
  }

  Future<vt.Style> _loadStyle() async {
    if (_catalogUrl.isEmpty) {
      throw StateError('OFFLINE_CATALOG_URL no está configurado.');
    }

    final response = await http.get(Uri.parse(_catalogUrl));
    if (response.statusCode != 200) {
      throw StateError(
        'No se pudo cargar el catálogo cartográfico: ' +
            response.statusCode.toString(),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('El catálogo cartográfico no tiene un formato válido.');
    }

    final downloadUrl = decoded['downloadUrl'];
    if (downloadUrl is! String || !downloadUrl.startsWith('https://')) {
      throw StateError('El catálogo no contiene un downloadUrl HTTPS válido.');
    }

    final provider = await vt.PmTilesVectorTileProvider.open(
      downloadUrl,
      logger: const vt.Logger.console(),
    );

    return vt.StyleReader(
      uri: 'https://tiles.openfreemap.org/styles/liberty',
      resolveProvider: (sourceId) async =>
          sourceId == 'openmaptiles' ? provider : null,
      logger: const vt.Logger.console(),
    ).read();
  }

  @override
  void dispose() {
    _styleFuture.then((style) => style.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<vt.Style>(
      future: _styleFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MapMessage(
            title: 'No se pudo cargar el mapa',
            message: snapshot.error.toString(),
            onRetry: () => setState(() {
              _styleFuture = _loadStyle();
            }),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final style = snapshot.data!;
        return FlutterMap(
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
            vt.VectorTileLayer(
              theme: style.theme,
              tileProviders: style.providers,
              rasterSources: style.rasterSources,
              sprites: style.sprites,
              logger: const vt.Logger.console(),
            ),
          ],
        );
      },
    );
  }
}
