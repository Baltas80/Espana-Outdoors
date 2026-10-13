import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/contracts/routing_service.dart';

/// Presents the exact endpoints, totals, and directions returned for a route.
class RoutePreviewCard extends StatelessWidget {
  const RoutePreviewCard({
    required this.origin,
    required this.destination,
    required this.route,
    super.key,
  });

  final LatLng origin;
  final LatLng destination;
  final RouteResult route;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Vista previa de la ruta',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _EndpointRow(icon: Icons.trip_origin, label: 'Origen', point: origin),
          const SizedBox(height: 8),
          _EndpointRow(
            icon: Icons.place_outlined,
            label: 'Destino',
            point: destination,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RouteMetric(
                  label: 'Distancia',
                  value: formatRouteDistance(route.distanceMeters),
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RouteMetric(
                  label: 'Duración estimada',
                  value: formatRouteDuration(route.durationSeconds),
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Instrucciones (${route.steps.length})',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (route.steps.isEmpty)
            Text(
              'El servicio de rutas no devolvió instrucciones paso a paso.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            for (var index = 0; index < route.steps.length; index++)
              _InstructionRow(index: index + 1, step: route.steps[index]),
        ],
      ),
    ),
  );
}

class _EndpointRow extends StatelessWidget {
  const _EndpointRow({
    required this.icon,
    required this.label,
    required this.point,
  });

  final IconData icon;
  final String label;
  final LatLng point;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            Text(
              _formatCoordinates(point),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    ],
  );
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    ],
  );
}

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.index, required this.step});

  final int index;
  final RouteStep step;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (step.distanceMeters != null) formatRouteDistance(step.distanceMeters),
      if (step.durationSeconds != null)
        formatRouteDuration(step.durationSeconds),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(
              '$index',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.instruction),
                if (details.isNotEmpty)
                  Text(
                    details.join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCoordinates(LatLng point) =>
    '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';

String formatRouteDistance(double? meters) {
  if (meters == null || !meters.isFinite || meters < 0) {
    return 'No disponible';
  }
  if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km';
  final precision = meters % 1 == 0 ? 0 : 1;
  return '${meters.toStringAsFixed(precision)} m';
}

String formatRouteDuration(double? seconds) {
  if (seconds == null || !seconds.isFinite || seconds < 0) {
    return 'No disponible';
  }
  if (seconds == 0) return '0 min';

  final totalMinutes = (seconds / 60).round();
  if (totalMinutes == 0) return '<1 min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) return '$minutes min';
  return minutes == 0 ? '$hours h' : '$hours h $minutes min';
}
