
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/alerts/alert_models.dart';
import '../../core/alerts/gateway_alert_service.dart';
import '../../core/live_data/gateway_config.dart';
import '../../core/live_data/live_data_gateway_client.dart';
import '../../core/location/location_controller.dart';

class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  List<OutdoorAlert> _alerts = const [];
  bool _loading = false;
  String? _error;

  Future<void> _load() async {
    final position = ref.read(locationControllerProvider).position;
    if (position == null) {
      _show('Obtén primero tu ubicación para consultar alertas cercanas.');
      return;
    }

    final baseUri = GatewayConfig.baseUri;
    if (baseUri == null) {
      _show(
        'Gateway no configurado. Compila con ESPANA_OUTDOOR_GATEWAY_URL '
        'para activar los datos vivos.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final gateway = HttpLiveDataGateway(baseUri: baseUri);
      final service = GatewayAlertService(gateway);
      final alerts = await service.alertsForPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        now: DateTime.now().toUtc(),
      );
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _severityText(AlertSeverity severity) => switch (severity) {
        AlertSeverity.information => 'Información',
        AlertSeverity.caution => 'Precaución',
        AlertSeverity.danger => 'Peligro',
        AlertSeverity.emergency => 'Emergencia',
      };

  IconData _icon(AlertType type) => switch (type) {
        AlertType.wildfire => Icons.local_fire_department_outlined,
        AlertType.flood => Icons.water_outlined,
        AlertType.storm => Icons.thunderstorm_outlined,
        AlertType.wind => Icons.air,
        AlertType.snow => Icons.ac_unit_outlined,
        AlertType.heat => Icons.wb_sunny_outlined,
        AlertType.cold => Icons.severe_cold,
        AlertType.earthquake => Icons.landslide_outlined,
        AlertType.tsunami => Icons.waves_outlined,
        AlertType.volcano => Icons.volcano_outlined,
        AlertType.landslide => Icons.terrain_outlined,
        AlertType.closure => Icons.block_outlined,
        AlertType.other => Icons.campaign_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationControllerProvider);
    final hasLocation = location.position != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Riesgos cercanos',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasLocation
                        ? 'Consulta señales activas alrededor de tu posición. '
                            'La fuente y vigencia se muestran en cada aviso.'
                        : 'Necesitas obtener tu ubicación antes de consultar alertas.',
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _loading
                        ? null
                        : () async {
                            if (!hasLocation) {
                              await ref
                                  .read(locationControllerProvider.notifier)
                                  .locate();
                            }
                            if (mounted) await _load();
                          },
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.warning_amber_outlined),
                    label: Text(_loading ? 'CONSULTANDO...' : 'CONSULTAR ALERTAS'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          if (!_loading && _error == null && _alerts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No hay avisos activos devueltos por la fuente configurada. '
                  'Esto no significa ausencia de riesgo fuera del alcance de esa fuente.',
                ),
              ),
            ),
          for (final alert in _alerts) ...[
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
                leading: CircleAvatar(child: Icon(_icon(alert.type))),
                title: Text(
                  alert.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_severityText(alert.severity)} · ${alert.sourceName}\n'
                    'Válido hasta ${alert.validUntil.toLocal()}',
                  ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(alert.title),
                    content: SingleChildScrollView(
                      child: Text(
                        '${alert.description ?? 'Sin descripción.'}\n\n'
                        'Fuente: ${alert.sourceName}\n'
                        'Publicado: ${alert.issuedAt.toLocal()}\n'
                        'Actualizado: ${alert.updatedAt.toLocal()}\n'
                        'Válido hasta: ${alert.validUntil.toLocal()}\n'
                        'Fuente: ${alert.sourceUrl}',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
