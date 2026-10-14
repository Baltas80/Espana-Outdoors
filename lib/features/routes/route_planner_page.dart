import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide RoutingConfig;
import 'package:latlong2/latlong.dart';

import '../../core/contracts/routing_service.dart';
import '../../core/location/location_controller.dart';
import '../../core/routing/routing_provider.dart';
import '../map/map_page.dart';
import 'destination_coordinate_input.dart';
import 'route_preview_card.dart';

class RoutePlannerPage extends ConsumerStatefulWidget {
  const RoutePlannerPage({super.key});

  @override
  ConsumerState<RoutePlannerPage> createState() => _RoutePlannerPageState();
}

class _RoutePlannerPageState extends ConsumerState<RoutePlannerPage> {
  LatLng? _destination;
  // Keep the request origin paired with its result as the live GPS can move.
  LatLng? _routeOrigin;
  RouteResult? _route;
  bool _busy = false;

  Future<void> _showDestinationDialog() async {
    final existing = _destination;
    final result = await showDialog<LatLng>(
      context: context,
      builder: (_) => _DestinationDialog(
        initialLatitude: existing?.latitude.toString() ?? '',
        initialLongitude: existing?.longitude.toString() ?? '',
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _destination = result;
      _routeOrigin = null;
      _route = null;
    });
  }

  Future<void> _calculate() async {
    if (_busy) return;

    final service = ref.read(routingServiceProvider);
    if (service == null) {
      _show('Routing no está configurado en esta instalación.');
      return;
    }

    final destination = _destination;
    if (destination == null) {
      _show('Selecciona primero un destino.');
      return;
    }

    setState(() => _busy = true);
    try {
      var location = ref.read(locationControllerProvider).position;
      if (location == null) {
        await ref.read(locationControllerProvider.notifier).locate();
        location = ref.read(locationControllerProvider).position;
      }
      if (location == null) {
        _show('Necesitamos tu ubicación para calcular la ruta.');
        return;
      }

      final origin = LatLng(location.latitude, location.longitude);
      final result = await service.route(
        RouteRequest(points: [origin, destination], profile: 'hiking'),
      );
      if (!mounted) return;
      setState(() {
        _routeOrigin = origin;
        _route = result;
      });
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

  String _coordinates(LatLng point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider).position;
    final destination = _destination;
    final center =
        destination ??
        (location == null
            ? const LatLng(40.4168, -3.7038)
            : LatLng(location.latitude, location.longitude));

    return Scaffold(
      appBar: AppBar(title: const Text('Planificar ruta')),
      body: Stack(
        children: [
          Positioned.fill(
            child: PmTilesMapViewport(
              key: ValueKey(
                '${center.latitude}:${center.longitude}:${_route?.points.length ?? 0}',
              ),
              initialCenter: center,
              initialZoom: destination == null ? 12 : 14,
              routePoints: _route?.points ?? const <LatLng>[],
              currentPosition: location == null
                  ? null
                  : LatLng(location.latitude, location.longitude),
              destination: destination,
              onTap: _busy
                  ? null
                  : (point) => setState(() {
                      _destination = point;
                      _routeOrigin = null;
                      _route = null;
                    }),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .45,
              ),
              child:
                  _route != null && _routeOrigin != null && destination != null
                  ? RoutePreviewCard(
                      origin: _routeOrigin!,
                      destination: destination,
                      route: _route!,
                    )
                  : Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Ruta de senderismo',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              destination == null
                                  ? 'Sin destino seleccionado.'
                                  : 'Destino: ${_coordinates(destination)}',
                            ),
                            if (destination == null)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Toca un punto del mapa para colocar el destino.',
                                ),
                              ),
                          ],
                        ),
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
                    onPressed: _busy || destination == null ? null : _calculate,
                    icon: const Icon(Icons.alt_route),
                    label: Text(_busy ? 'CALCULANDO…' : 'CALCULAR RUTA'),
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

class _DestinationDialog extends StatefulWidget {
  const _DestinationDialog({
    required this.initialLatitude,
    required this.initialLongitude,
  });

  final String initialLatitude;
  final String initialLongitude;

  @override
  State<_DestinationDialog> createState() => _DestinationDialogState();
}

class _DestinationDialogState extends State<_DestinationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(text: widget.initialLatitude);
    _longitudeController = TextEditingController(text: widget.initialLongitude);
  }

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    final latitude = validateDestinationCoordinate(
      _latitudeController.text,
      axis: DestinationCoordinateAxis.latitude,
    );
    final longitude = validateDestinationCoordinate(
      _longitudeController.text,
      axis: DestinationCoordinateAxis.longitude,
    );
    if (!latitude.isValid || !longitude.isValid) return;

    Navigator.pop(context, LatLng(latitude.value!, longitude.value!));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Destino'),
    content: SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Introduce coordenadas decimales. Puedes usar coma o punto.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.next,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Latitud'),
              validator: (value) => validateDestinationCoordinate(
                value,
                axis: DestinationCoordinateAxis.latitude,
              ).errorMessage,
            ),
            TextFormField(
              controller: _longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.done,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              decoration: const InputDecoration(labelText: 'Longitud'),
              validator: (value) => validateDestinationCoordinate(
                value,
                axis: DestinationCoordinateAxis.longitude,
              ).errorMessage,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Usar destino')),
    ],
  );
}
