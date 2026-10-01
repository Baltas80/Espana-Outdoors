import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/maps/pmtiles_style_loader.dart';

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
  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    _styleFuture = loadPmTilesStyle();
  }
  void _retry() => setState(() => _styleFuture = loadPmTilesStyle());
  Future<void> _useLocation() async {
    await ref.read(locationControllerProvider.notifier).locate();
    if (!mounted) return;
    final position = ref.read(locationControllerProvider).position;
    if (position == null) return;
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      15,
    );
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
          IconButton(tooltip: 'Mapas offline', onPressed: () => context.push('/offline'), icon: const Icon(Icons.download_outlined)),
          IconButton(tooltip: 'Navegación GPS', onPressed: () => context.push('/navigation'), icon: const Icon(Icons.navigation_outlined)),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<vt.Style>(
              future: _styleFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _MapMessage(title: 'No se pudo cargar el mapa', message: snapshot.error.toString(), onRetry: _retry);
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return _PmTilesLayer(
                  style: snapshot.data!,
                  center: const LatLng(40.4168, -3.7038),
                  zoom: 6.2,
                  mapController: _mapController,
                  currentPosition: location.position == null
                      ? null
                      : LatLng(
                          location.position!.latitude,
                          location.position!.longitude,
                        ),
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
                child: Row(children: [
                  const Icon(Icons.map_outlined),
                  const SizedBox(width: 10),
                  Expanded(child: Text(recording.isRecording ? 'Grabando ${(recording.distanceMeters / 1000).toStringAsFixed(2)} km' : location.message)),
                ]),
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface.withValues(alpha: .92), borderRadius: BorderRadius.circular(8)),
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5), child: Text(_mapAttribution, style: TextStyle(fontSize: 11))),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: Icon(recording.isRecording ? Icons.stop : Icons.fiber_manual_record),
            ),
          ),
          Positioned(right: 16, bottom: 152, child: FloatingActionButton.small(tooltip: 'Navegación GPS', onPressed: () => context.push('/navigation'), child: const Icon(Icons.navigation_outlined))),
          Positioned(right: 16, bottom: 24, child: FloatingActionButton(tooltip: 'Usar mi ubicación', onPressed: _useLocation, child: const Icon(Icons.my_location))),
        ],
      ),
    );
  }
}

class _PmTilesLayer extends StatelessWidget {
  const _PmTilesLayer({
    required this.style,
    required this.center,
    required this.zoom,
    this.mapController,
    this.currentPosition,
    this.destination,
    this.routePoints = const <LatLng>[],
    this.onTap,
  });
  final vt.Style style;
  final LatLng center;
  final double zoom;
  final MapController? mapController;
  final LatLng? currentPosition;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final ValueChanged<LatLng>? onTap;
  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (currentPosition != null)
        Marker(
          point: currentPosition!,
          width: 42,
          height: 42,
          child: Tooltip(
            message: 'Mi posición',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.my_location, color: Colors.black, size: 25),
            ),
          ),
        ),
      if (destination != null)
        Marker(
          point: destination!,
          width: 42,
          height: 48,
          child: Tooltip(
            message: 'Destino',
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.place, color: Colors.black, size: 27),
            ),
          ),
        ),
    ];

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 3,
        maxZoom: 18,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        vt.VectorTileLayer(
          theme: style.theme,
          tileProviders: style.providers,
          rasterSources: style.rasterSources,
          sprites: style.sprites,
          logger: const vt.Logger.console(),
        ),
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 5,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}

class PmTilesMapViewport extends StatefulWidget {
  const PmTilesMapViewport({
    super.key,
    this.initialCenter = const LatLng(40.4168, -3.7038),
    this.initialZoom = 7,
    this.routePoints = const <LatLng>[],
    this.currentPosition,
    this.destination,
    this.onTap,
  });
  final LatLng initialCenter;
  final double initialZoom;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;
  final LatLng? destination;
  final ValueChanged<LatLng>? onTap;
  @override
  State<PmTilesMapViewport> createState() => _PmTilesMapViewportState();
}

class _PmTilesMapViewportState extends State<PmTilesMapViewport> {
  late Future<vt.Style> _styleFuture;
  final MapController _mapController = MapController();
  @override
  void initState() {
    super.initState();
    _styleFuture = loadPmTilesStyle();
  }
  @override
  void dispose() {
    _styleFuture.then((style) => style.dispose());
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FutureBuilder<vt.Style>(
    future: _styleFuture,
    builder: (context, snapshot) {
      if (snapshot.hasError) return _MapMessage(title: 'No se pudo cargar el mapa', message: snapshot.error.toString(), onRetry: () => setState(() => _styleFuture = loadPmTilesStyle()));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      return _PmTilesLayer(
        style: snapshot.data!,
        center: widget.initialCenter,
        zoom: widget.initialZoom,
        mapController: _mapController,
        currentPosition: widget.currentPosition,
        destination: widget.destination,
        routePoints: widget.routePoints,
        onTap: widget.onTap,
      );
    },
  );
}

class _MapMessage extends StatelessWidget {
  const _MapMessage({required this.title, required this.message, required this.onRetry});
  final String title;
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.map_outlined, size: 52),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
      ]),
    ),
  );
}
