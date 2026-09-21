import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapas offline')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.download_for_offline_outlined, size: 34),
                const SizedBox(height: 12),
                Text('Prepara antes de salir', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Los paquetes offline permitirán conservar mapas y datos críticos cuando pierdas cobertura.'),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: null, icon: const Icon(Icons.add), label: const Text('Seleccionar zona')),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          const _PackageTile(title: 'Datos críticos', subtitle: 'Mapa, ruta activa y seguridad', size: 'Pendiente'),
          const _PackageTile(title: 'Recomendado', subtitle: 'Puntos de interés, fauna y restricciones', size: 'Pendiente'),
          const SizedBox(height: 16),
          const Text('Los datos descargados mostrarán siempre su fecha de actualización. Una copia antigua no se presentará como información en tiempo real.'),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.title, required this.subtitle, required this.size});
  final String title;
  final String subtitle;
  final String size;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6), leading: const Icon(Icons.map_outlined), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: Text(size)));
}
