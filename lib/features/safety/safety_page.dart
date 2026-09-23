import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/outdoor_models.dart';
import '../../core/emergency/emergency_service.dart';
import '../../core/emergency/emergency_share_service.dart';
import '../../core/emergency/trusted_contact_store.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _emergency = EmergencyService();
  final _share = const EmergencyShareService();
  final _contacts = TrustedContactStore();
  bool _capturing = false;

  Future<void> _prepareEmergencyCall() async {
    setState(() => _capturing = true);
    final snapshot =
        await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);

    if (snapshot == null) {
      _show('No se ha podido obtener una ubicación precisa.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar al 112'),
        content: Text(
          'Ubicación preparada con una precisión aproximada de '
          '${snapshot.accuracyMeters.toStringAsFixed(0)} m.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Llamar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _emergency.callEmergencyServices();
    }
  }

  Future<void> _shareEmergency() async {
    setState(() => _capturing = true);
    final snapshot =
        await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);

    if (snapshot == null) {
      _show('No se ha podido obtener la ubicación.');
      return;
    }

    final payload = _share.createPayload(snapshot: snapshot);
    final contacts =
        _contacts.load().where((contact) => contact.enabled).toList();

    if (contacts.isEmpty) {
      await _share.copyShareText(payload);
      if (mounted) {
        _show(
          'Alerta copiada. Configura un contacto de confianza para enviarla directamente.',
        );
      }
      return;
    }

    final contact = contacts.first;
    final opened = await _share.openSms(payload, contact.phone);
    if (mounted) {
      _show(
        opened ? 'Mensaje de alerta preparado.' : 'No se pudo abrir el SMS.',
      );
    }
  }

  Future<void> _showMyPosition() async {
    setState(() => _capturing = true);
    final snapshot =
        await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);

    if (snapshot == null) {
      _show('No se ha podido obtener la ubicación.');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi posición'),
        content: SelectableText(
          'Latitud: ${snapshot.position.latitude}\n'
          'Longitud: ${snapshot.position.longitude}\n'
          'Precisión: ${snapshot.accuracyMeters.toStringAsFixed(0)} m\n'
          'Altitud: ${snapshot.altitudeMeters?.toStringAsFixed(0) ?? 'no disponible'} m\n'
          'Hora: ${snapshot.capturedAt.toLocal()}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Prepara tu ubicación para emergencias. '
                    'España Outdoor no sustituye a los servicios profesionales.',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _capturing ? null : _prepareEmergencyCall,
                      icon: const Icon(Icons.emergency),
                      label: Text(
                        _capturing
                            ? 'OBTENIENDO UBICACIÓN…'
                            : 'PREPARAR SOS / 112',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _capturing ? null : _shareEmergency,
                    icon: const Icon(Icons.share_location_outlined),
                    label: const Text('ENVIAR ALERTA A CONTACTO'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _capturing ? null : _showMyPosition,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('MI POSICIÓN'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SafetyTile(
            icon: Icons.route_outlined,
            title: 'Plan de ruta',
            subtitle:
                'Salida, regreso previsto y participantes.',
            onTap: () => context.go('/safety/plan'),
          ),
          const SizedBox(height: 10),
          _SafetyTile(
            icon: Icons.contact_emergency_outlined,
            title: 'Contactos de confianza',
            subtitle:
                'Destinatarios para alertas temporales de emergencia.',
            onTap: () => context.go('/safety/contacts'),
          ),
          const SizedBox(height: 10),
          _SafetyTile(
            icon: Icons.campaign_outlined,
            title: 'Alertas y desastres',
            subtitle:
                'Incendios, inundaciones, tormentas y otros riesgos.',
            onTap: () => context.go('/safety/alerts'),
          ),
          const SizedBox(height: 10),
          _SafetyTile(
            icon: Icons.pets_outlined,
            title: 'Mascotas',
            subtitle: 'Riesgos de calor, agua, fauna y restricciones.',
            onTap: () => context.go('/pets'),
          ),
          const SizedBox(height: 10),
          const _SafetyTile(
            icon: Icons.volunteer_activism_outlined,
            title: 'Rescue Link',
            subtitle:
                'Ayuda cercana con controles antiabuso y privacidad.',
          ),
        ],
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
