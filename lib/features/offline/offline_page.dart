import 'package:flutter/material.dart';

class OfflinePage extends StatelessWidget {
  const OfflinePage({super.key});

  static const _packages = [
    ('Parque Nacional del Lago de Sanabria', 'Mapa + rutas + seguridad', '1.2 GB', true),
    ('Picos de Europa — zona seleccionada', 'Mapa + rutas', '860 MB', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapas offline')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_download_outlined, size: 30),
                  const SizedBox(width: 14),
                  Expanded(child: Text('Prepara tu zona antes de salir. Los datos descargados mantienen la navegación básica aunque pierdas cobertura.')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Tus zonas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ..._packages.map((package) => Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(package.$4 ? Icons.check_circle : Icons.cloud_download_outlined),
                  title: Text(package.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${package.$2}\n${package.$3}'),
                  isThreeLine: true,
                  trailing: package.$4 ? const Text('Listo') : FilledButton(onPressed: () {}, child: const Text('Descargar')),
                ),
              )),
          const SizedBox(height: 20),
          Text('Principio de seguridad', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('La aplicación muestra siempre cuándo la información dinámica no puede actualizarse. Un dato descargado no se presenta como una alerta actual si ha quedado obsoleto.'),
        ],
      ),
    );
  }
}
