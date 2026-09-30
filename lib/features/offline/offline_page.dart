import 'package:flutter/material.dart';

import '../../app/outdoor_visuals.dart';
import '../../core/maps/pmtiles_local_source.dart';
import '../../core/offline/offline_region.dart';
import '../../core/offline/offline_region_catalog.dart';
import '../../core/offline/offline_region_downloader.dart';
import '../../core/offline/offline_region_store.dart';

const _catalogUrl = String.fromEnvironment('OFFLINE_CATALOG_URL');

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});
  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  late Future<List<OfflineRegion>> _catalogFuture;
  final Set<String> _readyIds = <String>{};
  bool _downloading = false;
  String _status = 'Preparando catálogo PMTiles…';

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  Future<List<OfflineRegion>> _loadCatalog() async {
    // A verified local package is enough to render and manage Spain offline.
    // Do not block the screen on remote catalog DNS/network when the archive
    // is already present and valid.
    if (await _hasVerifiedLocalSpain()) {
      if (mounted) {
        setState(() {
          _readyIds.add('spain');
          _status = 'España disponible sin conexión.';
        });
      }
      return const <OfflineRegion>[];
    }

    try {
      if (_catalogUrl.isEmpty) {
        throw StateError('OFFLINE_CATALOG_URL no está configurado.');
      }

      final regions = await OfflineRegionCatalog(
        endpoint: Uri.parse(_catalogUrl),
      ).fetch();

      await _refreshReady(regions);
      return regions;
    } on Object {
      // No local archive and no remote catalog: surface the actionable error.
      rethrow;
    }
  }

  Future<bool> _hasVerifiedLocalSpain() async {
    final record = OfflineRegionStore().get('spain');
    if (record == null || !record.hasValidArtifact) return false;

    final path = record.localPath?.trim();
    final sha256 = record.sha256?.trim().toLowerCase();
    if (path == null || path.isEmpty || sha256 == null || sha256.length != 64) {
      return false;
    }

    final fileName = path.split(RegExp(r'[/\\]')).last;
    return await findValidLocalPmTiles(
          expectedFileName: fileName,
          expectedSha256: sha256,
        ) !=
        null;
  }

  Future<void> _refreshReady(List<OfflineRegion> regions) async {
    final ready = <String>{};
    for (final region in regions) {
      final fileName =
          '${region.id}-${region.sha256.substring(0, 12)}.pmtiles';
      final path = await findValidLocalPmTiles(
        expectedFileName: fileName,
        expectedSha256: region.sha256,
      );
      if (path != null) ready.add(region.id);
    }
    if (mounted) {
      setState(() {
        _readyIds
          ..clear()
          ..addAll(ready);
      });
    }
  }

  Future<void> _downloadRegion(OfflineRegion region) async {
    if (_downloading) return;

    setState(() {
      _downloading = true;
      _status = 'Descargando ${region.name}…';
    });

    try {
      await const OfflineRegionDownloader().startAndVerify(region);
      await _refreshReady([region]);
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _status = '${region.name} descargada y verificada.';
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _status = 'Error: $error';
      });
    }
  }

  String _size(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Mapas offline')),
        body: SafeArea(
          child: FutureBuilder<List<OfflineRegion>>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _MapCatalogError(
                  message: snapshot.error.toString(),
                  onRetry: () =>
                      setState(() => _catalogFuture = _loadCatalog()),
                );
              }

              final regions = snapshot.data;
              if (regions == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  const OutdoorVisualHero(
                    asset: 'assets/visuals/hero_map.svg',
                    title: 'Mapas offline',
                    subtitle: 'Mapas PMTiles sin conexión y gestión de descargas.',
                  ),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.map_outlined, size: 46),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'España Outdoor utiliza PMTiles como fuente cartográfica. Las descargas offline se almacenan localmente y se verifican mediante SHA-256 antes de considerarse válidas.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (regions.isEmpty && _readyIds.contains('spain')) ...[
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline, size: 42),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'España está descargada, verificada y disponible sin conexión. No se necesita el catálogo remoto para utilizar el mapa local.',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (final region in regions) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(region.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Text(region.description),
                            const SizedBox(height: 4),
                            Text('${_size(region.sizeBytes)} · ${region.updatedAt.toLocal()}'),
                            const SizedBox(height: 4),
                            Text('SHA-256: ${region.sha256}'),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _downloading || _readyIds.contains(region.id) ? null : () => _downloadRegion(region),
                                icon: Icon(_readyIds.contains(region.id) ? Icons.check : Icons.download),
                                label: Text(_readyIds.contains(region.id) ? 'Disponible sin conexión' : 'Descargar mapa'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(_status, textAlign: TextAlign.center),
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
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52),
              const SizedBox(height: 14),
              Text('No se pudo obtener el catálogo de mapas', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
            ],
          ),
        ),
      );
}
