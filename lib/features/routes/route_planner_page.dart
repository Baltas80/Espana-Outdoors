import 'dart:async';

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide RoutingConfig;
import 'package:latlong2/latlong.dart';

import '../../core/contracts/routing_service.dart';
import '../../core/location/location_controller.dart';
import '../../core/maps/agus_maps_runtime.dart';
import '../../core/routing/routing_config.dart';
import '../../infrastructure/routing/valhalla_routing_service.dart';

class RoutePlannerPage extends ConsumerStatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  ConsumerState<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends ConsumerState<RoutePlannerPage> {
  final _controller = agus.AgusMapController();
  late final Future<void> _runtimeFuture;

  LatLng? _destination;
  RouteResult? _route;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _runtimeFuture = AgusMapsRuntime.instance.ensureInitialized();
  }

  Future<void> _showDestinationDialog() async {
    final existing = _destination;
    final latController = TextEditingController(
      text: existing?.latitude.toStringAsFixed(6) ?? '',
    );
    final lonController = TextEditingController(
      text: existing?.longitude.toStringAsFixed(6) ?? '',
    );

    final destination = await showDialog<LatLng>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Destino'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Introduce las coordenadas WGS84 del destino.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: latController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Latitud'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lonController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(labelText: 'Longitud'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final lat =
                  double.tryParse(latController.text.replaceAll(',', '.'));
              final lon =
                  double.tryParse(lonController.text.replaceAll(',', '.'));
              if (lat == null ||
                  lon == null ||
                  lat.abs() > 90 ||
                  lon.abs() > 180) {
                return;
              }
              Navigator.pop(context, LatLng(lat, lon));
            },
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );

    latController.dispose();
    lonController.dispose();

    if (destination == null || !mounted) return;
    setState(() {
      _destination = destination;
      _route = null;
    });
    _controller.moveToLocation(
      destination.latitude,
      destination.longitude,
      14,
    );
  }

  Future<void> _calculate() async {
    final destination = _destination;
    if (destination == null) {
      _show('Selecciona primero un destino.');
      return;
    }

    var location = ref.read(locationControllerProvider).position;
    if (location == null) {
      await ref.read(locationControllerProvider.notifier).locate();
      location = ref.read(locationControllerProvider).position;
    }
    if (location == null) {
      _show('Necesitamos tu ubicación para calcular la ruta.');
      return;
    }

    final config = RoutingConfig.fromEnvironment();
    if (!config.isConfigured) {
      _show('Routing no está configurado en este APK.');
      return;
    }

    setState(() => _busy = true);
    try {
      final service = ValhallaRoutingService(baseUri: config.baseUri!);
      final result = await service.route(
        RouteRequest(
          points: [
            LatLng(location.latitude, location.longitude),
            destination,
          ],
          profile: 'hiking',
        ),
      );
      if (!mounted) return;
      setState(() => _route = result);
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
    final location = ref.watch(locationControllerProvider).position;
    final destination = _destination;
    final center = destination ??
        (location == null
            ? const LatLng(40.4168, -3.7038)
            : LatLng(location.latitude, location.longitude));

    final destinationLabel = destination == null
        ? 'Sin destino seleccionado.'
        : 'Destino: ${destination.latitude.toStringAsFixed(5)}, ${destination.longitude.toStringAsFixed(5)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Planificar ruta')),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _runtimeFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No se pudo iniciar la cartografía: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                return agus.AgusMap(
                  controller: _controller,
                  initialLat: center.latitude,
                  initialLon: center.longitude,
                  initialZoom: destination == null ? 12 : 14,
                  onMapReady: () =>
                      unawaited(AgusMapsRuntime.instance.onMapReady()),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ruta de senderismo',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(destinationLabel),
                    if (_route != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${((_route!.distanceMeters ?? 0) / 1000).toStringAsFixed(1)} km · ${((_route!.durationSeconds ?? 0) / 60).round()} min',
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _showDestinationDialog,
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('SELECCIONAR DESTINO'),
                  ),
                ),
                const SizedBox(height: 8),
                if (_route != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => context.push('/navigation', extra: _route),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text('Iniciar navegación'),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _busy || destination == null ? null : _calculate,
                    icon: const Icon(Icons.alt_route),
                    label: Text(
                      _busy ? 'CALCULANDO…' : 'CALCULAR RUTA',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
