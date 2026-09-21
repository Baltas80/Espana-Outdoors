import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_controller.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  static const _spainCenter = LatLng(40.4168, -3.7038);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(initialCenter: _spainCenter, initialZoom: 6.0),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.espanaoutdoors.app',
              ),
              if (location.position != null)
                MarkerLayer(markers: [
                  Marker(
                    point: LatLng(location.position!.latitude, location.position!.longitude),
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.my_location, size: 34),
                  ),
                ]),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 10),
                  Expanded(child: Text(location.message)),
                ]),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              tooltip: 'Usar mi ubicación',
              onPressed: () => ref.read(locationControllerProvider.notifier).locate(),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
