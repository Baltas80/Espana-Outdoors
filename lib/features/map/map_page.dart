import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import '../../core/map/maplibre_style_provider.dart';
import 'map_provider_config.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  bool get _mapLibreSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    final recording = ref.watch(routeRecorderProvider);
    final recorder = ref.read(routeRecorderProvider.notifier);
    final provider = MapProviderConfig.fromEnvironment();

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
            child: _mapLibreSupported
                ? _MapLibreSurface(
                    location: location.position == null
                        ? null
                        : LatLng(
                            location.position!.latitude,
                            location.position!.longitude,
                          ),
                  )
                : _DesktopFlutterMap(
                    provider: provider,
                    location: location,
                    recording: recording,
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
  const _MapLibreSurface({this.location});

  final LatLng? location;

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
      final local = await _styles.findLatestLocalRegion(location: widget.location);
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
  void didUpdateWidget(covariant _MapLibreSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLocation = oldWidget.location;
    final newLocation = widget.location;
    if (oldLocation?.latitude != newLocation?.latitude ||
        oldLocation?.longitude != newLocation?.longitude) {
      _loadStyle();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
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
      attributionButtonMargins: const Point(12, 12),
    );
  }
}

class _DesktopFlutterMap extends StatelessWidget {
  const _DesktopFlutterMap({
    required this.provider,
    required this.location,
    required this.recording,
  });

  final MapProviderConfig provider;
  final LocationState location;
  final RouteRecorderState recording;

  @override
  Widget build(BuildContext context) {
    if (!provider.isConfigured) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'MapLibre está disponible en Android, iOS y Web. Para escritorio se mantiene el renderer GIS de respaldo hasta disponer de soporte MapLibre nativo estable.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(40.4168, -3.7038),
        initialZoom: 6,
      ),
      children: [
        TileLayer(
          urlTemplate: provider.tileUrlTemplate,
          userAgentPackageName: provider.userAgent,
        ),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [TextSourceAttribution(provider.attribution)],
        ),
        if (recording.points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: recording.points
                    .map((point) => LatLng(point.latitude, point.longitude))
                    .toList(growable: false),
                strokeWidth: 5,
              ),
            ],
          ),
        if (location.position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(
                  location.position!.latitude,
                  location.position!.longitude,
                ),
                width: 48,
                height: 48,
                child: const Icon(Icons.my_location, size: 34),
              ),
            ],
          ),
      ],
    );
  }
}
