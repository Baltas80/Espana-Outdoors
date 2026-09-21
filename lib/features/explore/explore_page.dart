import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  static const _areas = [
    ('Rutas', Icons.route_outlined, 'Senderismo, trail y bicicleta'),
    ('Mascotas', Icons.pets_outlined, 'Rutas compatibles y riesgos'),
    ('Fauna', Icons.forest_outlined, 'Encuentros y conservación'),
    ('Meteorología', Icons.cloud_outlined, 'Condiciones para tu salida'),
    ('Incendios', Icons.local_fire_department_outlined, 'Situación y avisos'),
    ('Offline', Icons.download_for_offline_outlined, 'Prepara zonas sin conexión'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Elige cómo quieres salir', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('No solo buscamos rutas: te ayudamos a entender el entorno antes y durante la aventura.'),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _areas.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 260, mainAxisExtent: 132, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemBuilder: (context, index) {
              final item = _areas[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => item.$1 == 'Offline' ? context.go('/offline') : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(item.$2, size: 28),
                      const Spacer(),
                      Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(item.$3, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Abrir mapa'),
              subtitle: const Text('Explora el territorio y prepara tu recorrido.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/map'),
            ),
          ),
        ],
      ),
    );
  }
}
