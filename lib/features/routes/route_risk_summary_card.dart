import 'package:flutter/material.dart';

import '../../domain/risk/route_risk.dart';

/// Honest risk summary shared by route planning and live navigation.
class RouteRiskSummaryCard extends StatelessWidget {
  const RouteRiskSummaryCard({
    required this.assessment,
    this.compact = false,
    super.key,
  });

  final RouteRiskAssessment assessment;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color statusColor;
    final IconData statusIcon;
    final String statusText;

    switch (assessment.readiness) {
      case RouteReadiness.apto:
        statusColor = theme.colorScheme.primary;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Sin factores de riesgo detectados en los datos evaluados.';
        break;
      case RouteReadiness.precaucion:
        statusColor = theme.colorScheme.tertiary;
        statusIcon = Icons.warning_amber_rounded;
        statusText = 'Evaluación parcial: no hay datos suficientes para recomendar la ruta.';
        break;
      case RouteReadiness.noRecomendado:
        statusColor = theme.colorScheme.error;
        statusIcon = Icons.do_not_disturb_on_outlined;
        statusText = 'No inicies la ruta mientras persista el factor de parada.';
        break;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Evaluación de riesgos · ${assessment.headline}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              statusText,
              style: theme.textTheme.bodyMedium,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              const Text(
                'Esta evaluación aún no recibe meteorología, alertas oficiales ni '
                'cierres geolocalizados asociados a esta ruta. La ausencia de '
                'datos no significa ausencia de peligro.',
              ),
              for (final reason in assessment.reasons)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $reason'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
