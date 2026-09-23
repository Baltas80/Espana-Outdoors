import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../core/gpx/gpx_export_service.dart';
import '../../core/gpx/gpx_import_service.dart';
import '../../core/map/maplibre_style_provider.dart';
import '../../core/models/route_summary.dart';

class RouteDetailPage extends StatefulWidget {
  const RouteDetailPage({super.key, this.route, this.track});

  final RouteSummary? route;
  final ImportedTrack? track;

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final _exporter = const GpxExportService();
  final _styles = const MapLibreStyleProvider();
  String? _style;
  String? _mapError;
  ml.MapLibreMapController? _mapController;
  bool _routeDrawn = false;

  List<ml.LatLng> get _points => widget.track?.points
          .map((point) => ml.LatLng(point.latitude, point.longitude))
          .toList(growable: false) ??
      const <ml.LatLng>[];

  @override
  void initState() {
    super.initState();
    _loadStyle();
  }

  Future<void> _loadStyle() async {
    try {
      final local = await _styles.findLatestLocalRegion();
      final style = await _styles.load(localPmtilesPath: local);
      if (!mounted) return;
      setState(() {
        _style = style;
        _mapError = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _mapError = error.toString());
    }
  }

  Future<void> _drawTrack() async {
    final controller = _mapController;
    final points = _points;
    if (controller == null || points.length < 2 || _routeDrawn) return;

    await controller.addLine(
      ml.LineOptions(
        geometry: points,
        lineWidth: 5,
        lineOpacity: 0.95,
        lineColor: '#2E7D32',
        lineJoin: 'round',
      ),
    );
    _routeDrawn = true;
  }

  Future<void> _exportTrack() async {
    final track = widget.track;
    if (track == null) return;
    try {
      final saved = await _exporter.saveTrack(track);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved == null ? 'Exportación cancelada.' : 'GPX guardado.')),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final route = widget.route;
    final title = track?.name ?? route?.name ?? 'Detalle de ruta';
    final points = _points;
    final center = points.isNotEmpty
        ? points[points.length ~/ 2]
        : const ml.LatLng(40.4168, -3.7038);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (track != null)
            IconButton(
              tooltip: 'Exportar GPX',
              onPressed: _exportTrack,
              icon: const Icon(Icons.file_download_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 300,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildMap(center, points),
            ),
          ),
          const SizedBox(height: 18),
          if (track != null) _TrackStats(track: track),
          if (route != null) _RouteStats(route: route),
        ],
      ),
    );
  }

  Widget _buildMap(ml.LatLng center, List<ml.LatLng> points) {
    if (_mapError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('No se pudo cargar el mapa: $_mapError'),
        ),
      );
    }

    final style = _style;
    if (style == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ml.MapLibreMap(
      styleString: style,
      initialCameraPosition: ml.CameraPosition(
        target: center,
        zoom: points.length > 1 ? 12 : 6,
      ),
      compassEnabled: true,
      attributionButtonMargins: const math.Point(12, 12),
      onMapCreated: (controller) => _mapController = controller,
      onStyleLoadedCallback: () {
        _routeDrawn = false;
        _drawTrack();
      },
    );
  }
}

class _TrackStats extends StatelessWidget {
  const _TrackStats({required this.track});
  final ImportedTrack track;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 20,
            runSpacing: 16,
            children: [
              _Stat(label: 'Distancia', value: '${(track.distanceMeters / 1000).toStringAsFixed(2)} km'),
              _Stat(label: 'Desnivel +', value: '+${track.ascentMeters.toStringAsFixed(0)} m'),
              _Stat(label: 'Desnivel -', value: '-${track.descentMeters.toStringAsFixed(0)} m'),
              _Stat(label: 'Puntos', value: '${track.points.length}'),
            ],
          ),
        ),
      );
}

class _RouteStats extends StatelessWidget {
  const _RouteStats({required this.route});
  final RouteSummary route;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 20,
            runSpacing: 16,
            children: [
              _Stat(label: 'Distancia', value: '${route.distanceKm.toStringAsFixed(1)} km'),
              _Stat(label: 'Desnivel +', value: '+${route.elevationGainM.toStringAsFixed(0)} m'),
              _Stat(label: 'Tiempo', value: '${route.durationMinutes} min'),
              _Stat(label: 'Dificultad', value: route.difficulty),
            ],
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 125,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      );
}