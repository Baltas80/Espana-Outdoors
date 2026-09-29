import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_controller.dart';
import '../../core/navigation/waypoint.dart';
import '../../core/navigation/waypoint_controller.dart';
import '../../core/navigation/waypoint_navigation.dart';

class WaypointsPage extends ConsumerWidget {
  const WaypointsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waypoints = ref.watch(waypointControllerProvider);
    final location = ref.watch(locationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Puntos guardados')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: location.position == null
            ? () => ref.read(locationControllerProvider.notifier).locate()
            : () => _addCurrentPosition(context, ref),
        icon: Icon(location.position == null ? Icons.my_location : Icons.add_location_alt),
        label: Text(location.position == null ? 'Obtener ubicación' : 'Guardar ubicación'),
      ),
      body: waypoints.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 12),
                    const Text('Todavía no tienes puntos guardados', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Guarda refugios, vehículos, campamentos, fuentes, lugares de interés o cualquier punto útil durante una salida.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: waypoints.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final point = waypoints[index];
                final snapshot = location.position == null
                    ? null
                    : calculateWaypointNavigation(position: location.position!, waypoint: point);
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(_subtitle(point, snapshot)),
                    isThreeLine: snapshot != null || point.elevationMeters != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (snapshot != null)
                          IconButton(
                            tooltip: snapshot.arrived ? 'Llegada' : 'Dirección al punto',
                            icon: Icon(snapshot.arrived ? Icons.flag : Icons.navigation_outlined),
                            onPressed: () => _showNavigation(context, point, snapshot),
                          ),
                        IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(waypointControllerProvider.notifier).remove(point.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _subtitle(OutdoorWaypoint point, WaypointNavigationSnapshot? snapshot) {
    final coordinates = '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    final elevation = point.elevationMeters == null ? '' : '\n${point.elevationMeters!.toStringAsFixed(0)} m';
    if (snapshot == null) return '$coordinates$elevation';
    final distance = snapshot.distanceMeters < 1000
        ? '${snapshot.distanceMeters.toStringAsFixed(0)} m'
        : '${(snapshot.distanceMeters / 1000).toStringAsFixed(2)} km';
    return '$coordinates\n$distance · rumbo ${snapshot.bearingDegrees.toStringAsFixed(0)}°';
  }

  void _showNavigation(BuildContext context, OutdoorWaypoint point, WaypointNavigationSnapshot snapshot) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.navigation_outlined, size: 42),
              const SizedBox(height: 8),
              Text(point.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(snapshot.arrived ? 'Estás dentro de 20 m del punto.' : '${(snapshot.distanceMeters / 1000).toStringAsFixed(2)} km'),
              const SizedBox(height: 4),
              Text('Rumbo ${snapshot.bearingDegrees.toStringAsFixed(0)}° · ${_relativeText(snapshot.relativeBearingDegrees)}'),
              const SizedBox(height: 12),
              const Text('Dirección directa al waypoint. No sustituye el routing por senderos o carreteras.'),
            ],
          ),
        ),
      ),
    );
  }

  String _relativeText(double degrees) {
    if (degrees.abs() < 15) return 'seguir recto';
    return degrees > 0 ? 'girar ${degrees.toStringAsFixed(0)}° a la derecha' : 'girar ${degrees.abs().toStringAsFixed(0)}° a la izquierda';
  }

  Future<void> _addCurrentPosition(BuildContext context, WidgetRef ref) async {
    final position = ref.read(locationControllerProvider).position;
    if (position == null) return;

    final controller = TextEditingController(text: 'Punto guardado');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar punto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nombre'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
        ],
      ),
    );
    controller.dispose();
    if (name == null) return;

    await ref.read(waypointControllerProvider.notifier).add(
          name: name,
          latitude: position.latitude,
          longitude: position.longitude,
          elevationMeters: position.altitude,
        );
  }
}
