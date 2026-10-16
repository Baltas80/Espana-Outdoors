import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Online forecast entry point for the Ulule demo.
///
/// This deliberately opens meteoblue in the system browser instead of embedding
/// its website/widget in a WebView. The published widget terms do not clearly
/// grant in-app embedding rights for a crowdfunding project.
class WeatherForecastPage extends StatelessWidget {
  const WeatherForecastPage({super.key});

  static final Uri _forecastUri = Uri.parse(
    'https://www.meteoblue.com/es/tiempo/semana',
  );

  Future<void> _openForecast(BuildContext context) async {
    final opened = await launchUrl(
      _forecastUri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'No se ha podido abrir la previsión. Comprueba la conexión e inténtalo de nuevo.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Previsión meteorológica')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Previsión online',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Consulta la previsión actualizada de meteoblue. '
                    'Se abrirá en el navegador para conservar la atribución '
                    'del proveedor y evitar una incrustación no autorizada.',
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openForecast(context),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Abrir previsión de meteoblue'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Requiere conexión a internet. Esta pantalla no guarda '
                    'previsiones ni ofrece funcionamiento meteorológico offline.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.thunderstorm_outlined),
              title: const Text(
                'Distancia de tormenta',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Herramienta local para estimar la distancia de un rayo.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/weather/lightning'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aviso de seguridad',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Una previsión general no sustituye los avisos oficiales ni la '
            'evaluación de las condiciones sobre el terreno. Antes de salir '
            'a montaña, consulta los avisos de AEMET y las autoridades locales. '
            'No uses esta pantalla como sistema de alerta de emergencia.',
          ),
        ],
      ),
    );
  }
}
