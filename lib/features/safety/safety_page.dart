import 'package:flutter/material.dart';
import '../../app/photo_atlas.dart';
import 'package:go_router/go_router.dart';

import '../../core/domain/outdoor_models.dart';
import '../../core/emergency/emergency_service.dart';
import '../../core/emergency/emergency_contact_directory.dart';
import '../../core/emergency/emergency_share_service.dart';
import '../../core/emergency/trusted_contact_store.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _emergency = const EmergencyService();
  final _share = const EmergencyShareService();
  final _contacts = TrustedContactStore();
  bool _capturing = false;

  Future<void> _prepareEmergencyCall() async {
    setState(() => _capturing = true);
    final snapshot = await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);
    if (snapshot == null) {
      _show('No se ha podido obtener una ubicación precisa.');
      return;
    }
    final contact = await EmergencyContactDirectory.instance.spain();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Llamar al ' + contact.general),
        content: Text('Ubicación preparada con una precisión aproximada de ${snapshot.accuracyMeters.toStringAsFixed(0)} m.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Llamar')),
        ],
      ),
    );
    if (confirmed == true) {
      await _emergency.callEmergencyServices(number: contact.general);
    }
  }

  Future<void> _shareEmergency() async {
    setState(() => _capturing = true);
    final snapshot = await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);
    if (snapshot == null) {
      _show('No se ha podido obtener la ubicación.');
      return;
    }
    final payload = _share.createPayload(snapshot: snapshot);
    final contacts = _contacts.load().where((contact) => contact.enabled).toList();
    if (contacts.isEmpty) {
      await _share.copyShareText(payload);
      if (mounted) _show('Alerta copiada. Configura un contacto de confianza para enviarla directamente.');
      return;
    }
    final contact = contacts.first;
    final opened = await _share.openSms(payload, contact.phone);
    if (mounted) _show(opened ? 'Mensaje de alerta preparado.' : 'No se pudo abrir el SMS.');
  }

  void _show(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seguridad')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.42,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const OutdoorPhotoTile(
                    index: 4,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SOS / Emergencia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Llamada y ubicación en tiempo real',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 54,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: _capturing ? null : _prepareEmergencyCall,
                  icon: const Icon(Icons.phone),
                  label: Text(
                    _capturing ? 'OBTENIENDO UBICACIÓN…' : 'ACTIVAR SOS',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Usa el SOS solo cuando necesites asistencia. España Outdoor no sustituye a los servicios profesionales.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SafetyTile(
                  icon: Icons.location_on_outlined,
                  title: 'Mi ubicación',
                  subtitle: 'Compartir en tiempo real',
                  onTap: _shareEmergency,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SafetyTile(
                  icon: Icons.contact_emergency_outlined,
                  title: 'Contactos',
                  subtitle: 'Contactos de emergencia',
                  onTap: () => context.go('/safety/contacts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SafetyTile(
                  icon: Icons.security_outlined,
                  title: 'Seguridad',
                  subtitle: 'Consejos y protocolos',
                  onTap: () => context.go('/alerts'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SafetyTile(
                  icon: Icons.cell_tower_outlined,
                  title: 'Cobertura',
                  subtitle: 'Señal y comunicación',
                  onTap: () => context.go('/map'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Información de seguridad',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _SafetyInfoRow(
            index: 5,
            title: 'Fauna y flora',
            subtitle: 'Respeta la naturaleza y anticipa riesgos.',
            onTap: () => context.go('/wildlife'),
          ),
          const SizedBox(height: 8),
          _SafetyInfoRow(
            index: 10,
            title: 'Mascotas',
            subtitle: 'Calor, agua, normativa y preparación.',
            onTap: () => context.go('/pets'),
          ),
          const SizedBox(height: 8),
          _SafetyInfoRow(
            index: 6,
            title: 'NATURA PROTECT',
            subtitle: 'Espacios sensibles y navegación responsable.',
            onTap: () => context.go('/natura'),
          ),
        ],
      )
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}


class _SafetyInfoRow extends StatelessWidget {
  const _SafetyInfoRow({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            OutdoorPhotoTile(
              index: index,
              width: 92,
              height: 76,
              borderRadius: 0,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(subtitle),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}
