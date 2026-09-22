import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/route_recorder.dart';
import 'map_provider_config.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  static const _spainCenter = LatLng(40.4168, -3.7038);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationControllerProvider);
    final recording = ref.watch(routeRecorderProvider);
    final recorder = ref.read(routeRecorderProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: _spainCenter,
              initialZoom: 6.0,
            ),
            children: [
              TileLayer(
                urlTemplate: MapProviderConfig.openStreetMap.tileUrlTemplate,
                userAgentPackageName: MapProviderConfig.openStreetMap.userAgent,
              ),
              RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution(MapProviderConfig.openStreetMap.attribution),
                ],
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
                          : Icons.info_outline,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        recording.isRecording
                            ? 'Grabando ${_formatKm(recording.distanceMeters)} km'
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
                recording.isRecording
                    ? Icons.stop
                    : Icons.fiber_manual_record,
              ),
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

  String _formatKm(double meters) {
    return (meters / 1000).toStringAsFixed(2);
  }
}
