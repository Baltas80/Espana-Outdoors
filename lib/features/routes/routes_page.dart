import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/photo_atlas.dart';
import '../../core/gpx/gpx_import_service.dart';
import '../../core/storage/local_route_store.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  final _gpx = const GpxImportService();
  final _store = LocalRouteStore();

  ImportedTrack? _imported;
  String? _error;
  String _filter = 'Todas';

  @override
  void initState() {
    super.initState();
    _imported = _store.loadLatestImportedTrack();
  }

  Future<void> _importGpx() async {
    setState(() => _error = null);
    try {
      final imported = await _gpx.pickAndImport();
      if (!mounted || imported == null) return;
      await _store.saveImportedTrack(imported);
      if (!mounted) return;
      setState(() => _imported = imported);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas'),
        actions: [
          IconButton(
            tooltip: 'Filtrar',
            onPressed: () {},
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Importar GPX',
            onPressed: _importGpx,
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          const _SearchField(),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in const ['Todas', 'Senderismo', 'MTB', 'Cicloturismo'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(item),
                      selected: _filter == item,
                      onSelected: (_) => setState(() => _filter = item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutdoorImageCard(
            index: 1,
            height: 205,
            title: 'Lagos de Covadonga',
            subtitle: 'Picos de Europa · Asturias',
            meta: 'MODERADA · 12,4 km · ↑ 650 m · 4–5 h',
            onTap: () => context.push('/routes/planner'),
          ),
          const SizedBox(height: 12),
          OutdoorImageCard(
            index: 2,
            height: 205,
            title: 'Peñalara por la Cuerda Larga',
            subtitle: 'Sierra de Guadarrama · Madrid',
            meta: 'DIFÍCIL · 18,7 km · ↑ 1.320 m · 7–8 h',
            onTap: () => context.push('/routes/planner'),
          ),
          const SizedBox(height: 12),
          OutdoorImageCard(
            index: 3,
            height: 205,
            title: 'Ruta de los Acantilados',
            subtitle: 'Costa da Morte · Galicia',
            meta: 'FÁCIL · 8,3 km · ↑ 210 m · 2–3 h',
            onTap: () => context.push('/routes/planner'),
          ),
          const SizedBox(height: 18),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            ),
          if (_imported != null) ...[
            _ImportedTrackCard(
              track: _imported!,
              onOpen: () => context.push('/routes/detail', extra: _imported),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            onPressed: () => context.push('/routes/planner'),
            icon: const Icon(Icons.alt_route),
            label: const Text('Planificar una ruta'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _importGpx,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Importar GPX'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return const TextField(
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.search),
        hintText: 'Buscar rutas, refugios…',
      ),
    );
  }
}

class _ImportedTrackCard extends StatelessWidget {
  const _ImportedTrackCard({required this.track, required this.onOpen});

  final ImportedTrack track;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 8),
                Text(
                  'GPX importado y guardado',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(track.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onOpen,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ver ruta'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('${(track.distanceMeters / 1000).toStringAsFixed(1)} km'),
                Text('+${track.ascentMeters.toStringAsFixed(0)} m'),
                Text('-${track.descentMeters.toStringAsFixed(0)} m'),
                Text('${track.points.length} puntos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
