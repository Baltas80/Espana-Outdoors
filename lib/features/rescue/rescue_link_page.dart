import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/outdoor_models.dart';
import '../../core/location/location_controller.dart';
import '../../core/rescue/rescue_link_policy.dart';
import '../../core/rescue/rescue_link_service.dart';

class RescueLinkPage extends ConsumerStatefulWidget {
  const RescueLinkPage({super.key});

  @override
  ConsumerState<RescueLinkPage> createState() => _RescueLinkPageState();
}

class _RescueLinkPageState extends ConsumerState<RescueLinkPage> {
  final _service = const RescueLinkService();
  RescueLinkAlert? _alert;
  bool _busy = false;

  Future<void> _prepare() async {
    setState(() => _busy = true);
    await ref.read(locationControllerProvider.notifier).locate();
    final position = ref.read(locationControllerProvider).position;
    if (!mounted) return;
    setState(() => _busy = false);

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitamos una ubicación antes de preparar Rescue Link.')),
      );
      return;
    }

    final policy = const RescueLinkPolicy();
    final alert = _service.createAlert(
      position: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      policy: policy,
    );
    setState(() => _alert = alert);
  }

  @override
  Widget build(BuildContext context) {
    final alert = _alert;
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue Link')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.link_outlined,
                      size: 34, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Ayuda sin crear otra víctima',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          )),
                  const SizedBox(height: 8),
                  const Text(
                    'La primera señal usa ubicación aproximada. La ubicación temporal más precisa solo se comparte dentro de una sesión autorizada.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const _RoleTile(
            icon: Icons.emergency_outlined,
            title: '1. Servicios oficiales',
            subtitle: '112 y servicios competentes tienen prioridad.',
          ),
          const _RoleTile(
            icon: Icons.contact_emergency_outlined,
            title: '2. Contactos de confianza',
            subtitle: 'Personas elegidas por el usuario.',
          ),
          const _RoleTile(
            icon: Icons.volunteer_activism_outlined,
            title: '3. Voluntarios autorizados',
            subtitle: 'Solo cuando el escenario sea apto y con controles de riesgo.',
          ),
          const SizedBox(height: 16),
          if (alert == null)
            FilledButton.icon(
              onPressed: _busy ? null : _prepare,
              icon: const Icon(Icons.location_searching),
              label: Text(_busy ? 'OBTENIENDO UBICACIÓN…' : 'PREPARAR RESCUE LINK'),
            )
          else ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Sesión preparada',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  'Caduca ${alert.expiresAt.toLocal().hour.toString().padLeft(2, '0')}:${alert.expiresAt.toLocal().minute.toString().padLeft(2, '0')}. '
                  'La publicación a terceros requiere una capa de backend autorizada.',
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => setState(() => _alert = null),
              child: const Text('CANCELAR SESIÓN'),
            ),
          ],
          const SizedBox(height: 18),
          Text(
            'Nunca se ofrecerán voluntarios dentro de incendios, evacuaciones, cierres o alertas oficiales graves. Rescue Link no sustituye al 112.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      );
}
