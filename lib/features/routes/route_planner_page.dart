import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide RoutingConfig;
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;

import '../../core/contracts/routing_service.dart';
import '../../core/location/location_controller.dart';
import '../../core/map/maplibre_style_provider.dart';
import '../../core/routing/routing_config.dart';
import '../../infrastructure/routing/valhalla_routing_service.dart';

class RoutePlannerPage extends ConsumerStatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  ConsumerState<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends ConsumerState<RoutePlannerPage> {
  final _styles = const MapLibreStyleProvider();
  ml.MapLibreMapController? _controller;
  String? _style;
  String? _error;
  LatLng? _destination;
  RouteResult? _route;
  bool _busy = false;
  bool _styleReady = false;

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
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  Future<void> _onMapClick(math.Point<double> _, ml.LatLng coordinates) async {
    setState(() {
      _destination = LatLng(coordinates.latitude, coordinates.longitude);
      _route = null;
      _error = null;
    });
    final controller = _controller;
    if (controller != null && _styleReady) {
      await controller.clearCircles();
      await controller.addCircle(
        ml.CircleOptions(
          geometry: coordinates,
          circleRadius: 8,
          circleColor: '#D9A441',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ),
      );
    }
  }

  Future<void> _calculate() async {
    final destination = _destination;
    if (destination == null) {
      _show('Toca el mapa para elegir un destino.');
      return;
    }
    final location = ref.read(locationControllerProvider).position;
    if (location == null) {
      await ref.read(locationControllerProvider.notifier).locate();
    }
    final position = ref.read(locationControllerProvider).position;
    if (position == null) {
      _show('Necesitamos tu ubicación para calcular la ruta.');
      return;
    }

    final config = RoutingConfig.fromEnvironment();
    if (!config.isConfigured) {
      _show('Routing no está configurado en este entorno.');
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ValhallaRoutingService(baseUri: config.baseUri!);
      final result = await service.route(
        RouteRequest(
          points: [
            LatLng(position.latitude, position.longitude),
            destination,
          ],
          profile: 'hiking',
        ),
      );
      if (!mounted) return;
      setState(() => _route = result);
      if (_controller != null && _styleReady) {
        await _controller!.clearLines();
        await _controller!.addLine(
          ml.LineOptions(
            geometry: result.points
                .map((point) => ml.LatLng(point.latitude, point.longitude))
                .toList(growable: false),
            lineWidth: 6,
            lineOpacity: 0.95,
            lineColor: '#2E7D32',
            lineJoin: 'round',
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) _show(error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.replaceFirst('Exception: ', ''))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final center = ref.watch(locationControllerProvider).position;
    final initial = center == null
        ? const ml.LatLng(40.4168, -3.7038)
        : ml.LatLng(center.latitude, center.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Planificar ruta')),
      body: Stack(
        children: [
          Positioned.fill(
            child: _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('No se pudo cargar el mapa: $_error')))
                : style == null
                    ? const Center(child: CircularProgressIndicator())
                    : ml.MapLibreMap(
                        styleString: style,
                        initialCameraPosition: ml.CameraPosition(target: initial, zoom: 12),
                        myLocationEnabled: true,
                        compassEnabled: true,
                        attributionButtonMargins: const math.Point(12, 12),
                        onMapCreated: (controller) => _controller = controller,
                        onMapClick: _onMapClick,
                        onStyleLoadedCallback: () {
                          _styleReady = true;
                        },
                      ),
          ),
          Positioned(
            left: 16, right: 16, top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ruta de senderismo', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(_destination == null ? 'Toca el mapa para elegir destino.' : 'Destino seleccionado.'),
                  if (_route != null) ...[
                    const SizedBox(height: 6),
                    Text('${((_route!.distanceMeters ?? 0) / 1000).toStringAsFixed(1)} km · ${((_route!.durationSeconds ?? 0) / 60).round()} min'),
                  ],
                ]),
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 24,
            child: Column(children: [
              if (_route != null) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => context.push('/navigation', extra: _route),
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Iniciar navegación'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _calculate,
                  icon: const Icon(Icons.alt_route),
                  label: Text(_busy ? 'CALCULANDO…' : 'CALCULAR RUTA'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}