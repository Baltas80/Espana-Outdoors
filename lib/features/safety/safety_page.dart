import 'package:flutter/material.dart';

import '../../core/domain/outdoor_models.dart';
import '../../core/emergency/emergency_service.dart';

class SafetyPage extends StatefulWidget {
  const SafetyPage({super.key});

  @override
  State<SafetyPage> createState() => _SafetyPageState();
}

class _SafetyPageState extends State<SafetyPage> {
  final _emergency = const EmergencyService();
  bool _capturing = false;

  Future<void> _prepareEmergencyCall() async {
    setState(() => _capturing = true);
    final snapshot = await _emergency.captureSnapshot(type: EmergencyType.other);
    if (!mounted) return;
    setState(() => _capturing = false);

    if (snapshot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se ha podido obtener una ubicación precisa.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamar al 112'),
        content: Text(
          'Ubicación preparada con una precisión aproximada de ${snapshot.accuracyMeters.toStringAsFixed(0)} m. La llamada abrirá el marcador del dispositivo; comprueba los datos antes de comunicar tu situación.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Llamar')),
        ],
      ),
    );

    if (confirmed == true) {
      await _emergency.callEmergencyServices();
    }
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
                  Text('SOS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Prepara tu ubicación y abre el marcador de emergencias. España Outdoor no sustituye a los servicios profesionales.'),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 58,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                      onPressed: _capturing ? null : _prepareEmergencyCall,
                      icon: _capturing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.emergency),
                      label: Text(_capturing ? 'OBTENIENDO UBICACIÓN…' : 'PREPARAR SOS / 112'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SafetyTile(icon: Icons.contact_emergency_outlined, title: 'Contactos de confianza', subtitle: 'Prepara quién debe recibir tu alerta.'),
          const SizedBox(height: 10),
          const _SafetyTile(icon: Icons.campaign_outlined, title: 'Alertas y desastres', subtitle: 'Incendios, inundaciones, tormentas y otros riesgos.'),
          const SizedBox(height: 10),
          const _SafetyTile(icon: Icons.pets_outlined, title: 'Mascotas', subtitle: 'Riesgos de calor, agua, fauna y restricciones.'),
          const SizedBox(height: 10),
          const _SafetyTile(icon: Icons.volunteer_activism_outlined, title: 'Rescue Link', subtitle: 'Ayuda cercana con controles antiabuso y privacidad.'),
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
  Widget build(BuildContext context) => Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
