import 'package:flutter/material.dart';

import '../../app/outdoor_visuals.dart';
import '../../core/offline/offline_region.dart';
import '../../core/offline/offline_region_catalog.dart';
import '../../core/offline/offline_region_downloader.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  late Future<List<OfflineRegion>> _catalogFuture;
  bool _downloading = false;
  String _status = 'Preparando catálogo PMTiles…';

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  Future<List<OfflineRegion>> _loadCatalog() async {
    if (_catalogUrl.isEmpty) throw StateError('OFFLINE_CATALOG_URL no está configurado.');
    return OfflineRegionCatalog(endpoint: Uri.parse(_catalogUrl)).fetch();
  }

  Future<void> _downloadRegion(OfflineRegion region) async {
    if (_downloading) return;
    setState(() { _downloading = true; _status = 'Descargando ${region.name}…'; });
    try {
      await const OfflineRegionDownloader().startAndVerify(region);
      if (!mounted) return;
      setState(() { _downloading = false; _status = '${region.name} descargada y verificada.'; });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() { _downloading = false; _status = 'Error: $error'; });
    }
  }

  String _size(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) { value /= 1024; unit++; }
    return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mapas offline')),
    body: SafeArea(
      child: FutureBuilder<List<OfflineRegion>>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _MapCatalogError(message: snapshot.error.toString(), onRetry: () => setState(() => _catalogFuture = _loadCatalog()));
          final regions = snapshot.data;
          if (regions == null) return const Center(child: CircularProgressIndicator());
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              const OutdoorVisualHero(asset: 'assets/visuals/hero_map.svg', title: 'Offline', subtitle: 'Mapas PMTiles sin conexión y gestión de descargas.'),
              const SizedBox(height: 16),
              const Card(child: Padding(padding: EdgeInsets.all(18), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.map_outlined, size: 46),
                SizedBox(width: 14),
                Expanded(child: Text('España Outdoor utiliza PMTiles como fuente cartográfica. Las descargas offline se almacenan localmente y se verifican mediante SHA-256 antes de considerarse válidas.')),
              ]))),
              const SizedBox(height: 20),
              for (final region in regions) ...[
                Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(region.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(region.description),
                  const SizedBox(height: 4),
                  Text('${_size(region.sizeBytes)} · ${region.updatedAt.toLocal()}'),
                  const SizedBox(height: 4),
                  Text('SHA-256: ${region.sha256}'),
                  const SizedBox(height: 12),
                  if (_downloading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  FilledButton.icon(onPressed: _downloading ? null : () => _downloadRegion(region), icon: const Icon(Icons.download_outlined), label: Text('Descargar ${region.name}')),
                ]))),
                const SizedBox(height: 12),
              ],
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [const Icon(Icons.storage_outlined), const SizedBox(width: 12), Expanded(child: Text(_status))]))),
              const SizedBox(height: 18),
              Text('Motor cartográfico', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('El mapa principal utiliza PMTiles con flutter_map_vector_tiles.'),
            ],
          );
        },
      ),
    ),
  );
}

class _MapCatalogError extends StatelessWidget {
  const _MapCatalogError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.cloud_off_outlined, size: 52),
    const SizedBox(height: 14),
    const Text('No se pudo obtener el catálogo de mapas', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
    const SizedBox(height: 8),
    Text(message, textAlign: TextAlign.center),
    const SizedBox(height: 18),
    FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
  ])));
}
