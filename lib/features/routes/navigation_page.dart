
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/gpx/gpx_import_service.dart';
import '../../core/navigation/navigation_models.dart';
import '../../core/routing/offline_navigation_engine.dart';
import '../../core/routing/routing_models.dart';
import '../map/map_page.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({required this.track, super.key});

  final ImportedTrack track;

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage> {
  final _engine = const OfflineNavigationEngine();
  StreamSubscription<Position>? _subscription;
  Position? _position;
  NavigationSnapshot? _snapshot;
  String? _error;
  bool _running = false;

  late final RoutingResult _route;

  @override
  void initState() {
    super.initState();
    final geometry = widget.track.points
        .map(
          (point) => RouteWaypoint(
            latitude: point.latitude,
            longitude: point.longitude,
          ),
        )
        .toList(growable: false);

    _route = RoutingResult(
      legs: [
        RouteLeg(
          distanceMeters: widget.track.distanceMeters,
          durationSeconds: 0,
          geometry: geometry,
          elevationGainMeters: widget.track.ascentMeters,
          elevationLossMeters: widget.track.descentMeters,
        ),
      ],
      providerId: 'gpx-import',
      sourceTimestamp: DateTime.now().toUtc(),
    );

    _start();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _error = null;
    });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Activa el servicio de ubicación para navegar.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('No hay permiso de ubicación para la navegación.');
      }

      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _apply(first);

      _subscription?.cancel();
      _subscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(_apply);

      if (mounted) setState(() => _running = true);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _running = false;
        _error = error.toString();
      });
    }
  }

  void _apply(Position position) {
    final snapshot = _engine.update(
      route: _route,
      position: RouteWaypoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
    if (!mounted) return;
    setState(() {
      _position = position;
      _snapshot = snapshot;
    });
  }

  Future<void> _stop() async {
    await _subscription?.cancel();
    _subscription = null;
    if (mounted) setState(() => _running = false);
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '—';
    if (meters < 1000) return meters.toStringAsFixed(0) + ' m';
    return (meters / 1000).toStringAsFixed(2) + ' km';
  }

  String _stateLabel(NavigationState state) => switch (state) {
        NavigationState.navigating => 'EN RUTA',
        NavigationState.completed => 'LLEGADA',
        NavigationState.offRoute => 'FUERA DE RUTA',
        NavigationState.paused => 'PAUSADA',
        NavigationState.idle => 'LISTA',
      };

  IconData _instructionIcon(NavigationInstructionKind kind) =>
      switch (kind) {
        NavigationInstructionKind.continueStraight => Icons.straight,
        NavigationInstructionKind.turnLeft => Icons.turn_left,
        NavigationInstructionKind.turnRight => Icons.turn_right,
        NavigationInstructionKind.arrive => Icons.flag_outlined,
        NavigationInstructionKind.offRoute => Icons.warning_amber_outlined,
        NavigationInstructionKind.warning => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Navegación'),
        actions: [
          IconButton(
            tooltip: _running ? 'Pausar navegación' : 'Reanudar navegación',
            onPressed: _running ? _stop : _start,
            icon: Icon(_running ? Icons.pause : Icons.play_arrow),
          ),
        ],
      ),
      body: SafeArea(
        child: snapshot == null
            ? _WaitingState(error: _error, onRetry: _start)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Card(
                    color: snapshot.offRoute
                        ? scheme.errorContainer
                        : scheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _stateLabel(snapshot.state),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Icon(
                            _instructionIcon(
                              snapshot.effectiveInstruction.kind,
                            ),
                            size: 56,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            snapshot.effectiveInstruction.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatDistance(
                              snapshot.effectiveInstruction.distanceMeters,
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Restante',
                          value: _formatDistance(
                            snapshot.distanceRemainingMeters,
                          ),
                          icon: Icons.route_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Metric(
                          label: 'Fuera de ruta',
                          value: _formatDistance(
                            snapshot.distanceOffRouteMeters,
                          ),
                          icon: Icons.gps_fixed_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Posición'),
                          subtitle: Text(
                            _position == null
                                ? 'Sin posición'
                                : _position!.latitude.toStringAsFixed(6) +
                                    ', ' +
                                    _position!.longitude.toStringAsFixed(6),
                          ),
                        ),
                        if (_position != null)
                          ListTile(
                            leading: const Icon(Icons.gps_not_fixed_outlined),
                            title: const Text('Precisión'),
                            subtitle: Text(
                              _position!.accuracy.toStringAsFixed(0) + ' m',
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.map_outlined),
                      title: const Text('Mapa'),
                      subtitle: const Text(
                        'La ruta permanece disponible mientras continúas navegando.',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MapPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'La navegación de este modo es local: no necesita red para '
                    'calcular distancia y detectar salida de ruta. No sustituye '
                    'señalización, criterio sobre el terreno ni servicios de emergencia.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}

class _WaitingState extends StatelessWidget {
  const _WaitingState({this.error, required this.onRetry});

  final String? error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.navigation_outlined, size: 60),
            const SizedBox(height: 16),
            Text(
              error ?? 'Preparando navegación…',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('REINTENTAR'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
