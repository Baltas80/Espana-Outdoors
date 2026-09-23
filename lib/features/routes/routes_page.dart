import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            tooltip: 'Importar GPX',
            onPressed: _importGpx,
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Planifica tu próxima salida',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rutas con contexto: distancia, desnivel, mascotas, agua y preparación offline.',
          ),
          const SizedBox(height: 20),
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
          const SizedBox(height: 20),
        ],
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
            Text(
              track.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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

