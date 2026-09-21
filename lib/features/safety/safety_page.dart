import 'package:flutter/material.dart';

class SafetyPage extends StatelessWidget {
  const SafetyPage({super.key});

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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('SOS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Acceso rápido a la llamada de emergencia y a tus contactos de confianza. La app no sustituye a los servicios profesionales.'),
                const SizedBox(height: 20),
                SizedBox(
                  height: 58,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('SOS preparado'),
                        content: const Text('El flujo de emergencia completo se activará cuando estén configurados permisos, contactos y servicios de comunicación. En una emergencia real, llama al 112.'),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
                      ),
                    ),
                    icon: const Icon(Icons.emergency),
                    label: const Text('ABRIR SOS'),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _SafetyTile(icon: Icons.contact_emergency_outlined, title: 'Contactos de confianza', subtitle: 'Prepara quién debe recibir tu alerta.'),
          const SizedBox(height: 10),
          _SafetyTile(icon: Icons.campaign_outlined, title: 'Alertas y desastres', subtitle: 'Incendios, inundaciones, tormentas y otros riesgos.'),
          const SizedBox(height: 10),
          _SafetyTile(icon: Icons.pets_outlined, title: 'Mascotas', subtitle: 'Riesgos de calor, agua, fauna y restricciones.'),
          const SizedBox(height: 10),
          _SafetyTile(icon: Icons.volunteer_activism_outlined, title: 'Rescue Link', subtitle: 'Concepto de ayuda cercana con controles antiabuso y privacidad.'),
        ],
      ),
    );
  }
}

class _SafetyTile extends StatelessWidget {
  const _SafetyTile({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8), leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right)));
}
