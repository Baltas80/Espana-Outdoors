import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/location/location_controller.dart';
import '../../core/navigation/waypoint_controller.dart';

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
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(point.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(
                      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}'
                      '${point.elevationMeters == null ? '' : '\n${point.elevationMeters!.toStringAsFixed(0)} m'}',
                    ),
                    isThreeLine: point.elevationMeters != null,
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(waypointControllerProvider.notifier).remove(point.id),
                    ),
                  ),
                );
              },
            ),
    );
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
