import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../app/eo_components.dart';
import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/maps/pmtiles_style_loader.dart';
import '../menu/menu_sheet.dart';

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
    _mapController.move(LatLng(position.latitude, position.longitude), 15);
  }
  void _openMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EOColors.night,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (_) => const MenuSheet(),
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
      backgroundColor: EOColors.night,
      appBar: EOAppBar(
        title: 'Mapa',
        actions: [
          EOIconButton(
            icon: Icons.menu,
            tooltip: 'Menú',
            onPressed: _openMenu,
            size: 44,
          ),
          const SizedBox(width: 4),
          EOIconButton(
            icon: Icons.download_outlined,
            tooltip: 'Mapas offline',
            onPressed: () => context.push('/offline'),
            size: 44,
          ),
          const SizedBox(width: 4),
          EOIconButton(
            icon: Icons.navigation_outlined,
            tooltip: 'Navegación GPS',
            onPressed: () => context.push('/navigation'),
            size: 44,
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
                  return _MapMessage(title: 'No se pudo cargar el mapa', message: snapshot.error.toString(), onRetry: _retry);
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return _PmTilesLayer(
                  style: snapshot.data!,
                  center: location.position == null
                      ? const LatLng(40.4168, -3.7038)
                      : LatLng(location.position!.latitude, location.position!.longitude),
                  zoom: location.position == null ? 6.2 : 15,
                  mapController: _mapController,
                  currentPosition: location.position == null
                      ? null
                      : LatLng(location.position!.latitude, location.position!.longitude),
                );
              },
            ),
          ),
          Positioned(
            left: EOSpacing.lg,
            right: EOSpacing.lg,
            top: EOSpacing.lg,
            child: EOMapPanel(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: EOSpacing.md, vertical: EOSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.map_outlined, color: EOColors.green),
                  const SizedBox(width: EOSpacing.sm),
                  Expanded(
                    child: Text(
                      recording.isRecording
                          ? 'Grabando ${(recording.distanceMeters / 1000).toStringAsFixed(2)} km'
                          : location.message,
                      style: EOTextStyles.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: EOSpacing.lg,
            bottom: EOSpacing.lg,
            child: EOMapPanel(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: EOSpacing.sm, vertical: 5),
              blur: false,
              child: const Text(_mapAttribution, style: EOTextStyles.label),
            ),
          ),
          Positioned(
            right: EOSpacing.lg,
            bottom: 88,
            child: EOIconButton(
              icon: recording.isRecording ? Icons.stop : Icons.fiber_manual_record,
              tooltip: recording.isRecording ? 'Detener grabación' : 'Grabar ruta',
              selected: recording.isRecording,
              danger: recording.isRecording,
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
            ),
          ),
          Positioned(
            right: EOSpacing.lg,
            bottom: 148,
            child: EOIconButton(
              icon: Icons.navigation_outlined,
              tooltip: 'Navegación GPS',
              onPressed: () => context.push('/navigation'),
            ),
          ),
          Positioned(
            right: EOSpacing.lg,
            bottom: EOSpacing.lg,
            child: EOIconButton(
              icon: Icons.my_location,
              tooltip: 'Usar mi ubicación',
              selected: location.position != null,
              onPressed: _useLocation,
            ),
          ),
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
        Marker(point: currentPosition!, width: 42, height: 42, child: Tooltip(message: 'Mi posición', child: DecoratedBox(decoration: const BoxDecoration(color: EOColors.green, shape: BoxShape.circle), child: const Icon(Icons.my_location, color: EOColors.night, size: 25)))),
      if (destination != null)
        Marker(point: destination!, width: 42, height: 48, child: Tooltip(message: 'Destino', child: DecoratedBox(decoration: const BoxDecoration(color: EOColors.orange, shape: BoxShape.circle), child: const Icon(Icons.place, color: EOColors.night, size: 27)))),
    ];

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: center, initialZoom: zoom, minZoom: 3, maxZoom: 18, onTap: onTap == null ? null : (_, point) => onTap!(point)),
      children: [
        vt.VectorTileLayer(theme: style.theme, tileProviders: style.providers, rasterSources: style.rasterSources, sprites: style.sprites, logger: const vt.Logger.console(), showLabels: true),
        if (routePoints.length >= 2)
          PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: EOColors.green)]),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );
  }
}

class PmTilesMapViewport extends StatefulWidget {
  const PmTilesMapViewport({super.key, this.initialCenter = const LatLng(40.4168, -3.7038), this.initialZoom = 7, this.routePoints = const <LatLng>[], this.currentPosition, this.destination, this.onTap});
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
      return _PmTilesLayer(style: snapshot.data!, center: widget.initialCenter, zoom: widget.initialZoom, mapController: _mapController, currentPosition: widget.currentPosition, destination: widget.destination, routePoints: widget.routePoints, onTap: widget.onTap);
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
      padding: const EdgeInsets.all(EOSpacing.xxxl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.map_outlined, size: 52, color: EOColors.textSecondary),
        const SizedBox(height: EOSpacing.md),
        Text(title, textAlign: TextAlign.center, style: EOTextStyles.title),
        const SizedBox(height: EOSpacing.sm),
        Text(message, textAlign: TextAlign.center, style: EOTextStyles.secondary),
        const SizedBox(height: EOSpacing.lg),
        EOButton(label: 'Reintentar', icon: Icons.refresh, onPressed: onRetry),
      ]),
    ),
  );
}
