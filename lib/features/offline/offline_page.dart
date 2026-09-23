import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/offline/offline_map_catalog.dart';
import '../../core/offline/offline_region_manager.dart';
import '../../core/offline/offline_region_store.dart';
import '../../core/offline/offline_runtime.dart';

class OfflinePage extends ConsumerStatefulWidget {
  const OfflinePage({super.key});

  @override
  ConsumerState<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends ConsumerState<OfflinePage> {
  OfflineRegionManager? _manager;
  OfflineRegionStore? _store;
  Future? _catalogFuture;

  @override
  void initState() {
    super.initState();
    try {
      _store = OfflineRegionStore();
    } on Object {
      _store = null;
    }
    if (!kIsWeb) {
      try {
        final manager = ref.read(offlineRegionManagerProvider);
        manager.addListener(_onManagerChanged);
        _manager = manager;
      } on Object {
        // Gateway may be unavailable during first-run configuration.
      }
    }
  }

  @override
  void dispose() {
    _manager?.removeListener(_onManagerChanged);
    super.dispose();
  }

  void _onManagerChanged() {
    if (mounted) setState(() {});
  }

  List<OfflineRegionRecord> get _regions => _store?.all() ?? const [];

  Future<void> _download(OfflineMapPackage package) async {
    final manager = _manager;
    if (manager == null) {
      _show(
        kIsWeb
            ? 'Las descargas MBTiles nativas no están disponibles en Web.'
            : 'Configura el catálogo offline para iniciar la descarga.',
      );
      return;
    }
    try {
      await manager.queue(package.region);
      await manager.prepare(package.id);
      if (mounted) _show('Mapa descargado y verificado: ${package.name}.');
    } on Object catch (error) {
      if (mounted) _show('No se pudo descargar ${package.name}: $error');
    }
  }

  Future<void> _pause(OfflineRegionRecord region) async {
    try {
      await _manager?.pause(region.region.id);
    } on Object catch (error) {
      _show('No se pudo pausar: $error');
    }
  }

  Future<void> _resume(OfflineRegionRecord region) async {
    try {
      await _manager?.resume(region.region.id);
    } on Object catch (error) {
      _show('No se pudo reanudar: $error');
    }
  }

  Future<void> _delete(OfflineRegionRecord region) async {
    try {
      await _manager?.delete(region.region.id);
    } on Object catch (error) {
      _show('No se pudo eliminar: $error');
    }
  }

  Future<void> _verify(OfflineRegionRecord region) async {
    try {
      await _manager?.prepare(region.region.id);
      if (mounted) _show('Zona verificada: ${region.region.name}.');
    } on Object catch (error) {
      if (mounted) _show('La verificación ha fallado: $error');
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(offlineCatalogServiceProvider);
    _catalogFuture ??= catalog?.packages();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapas offline'),
        actions: [
          IconButton(
            tooltip: 'Actualizar catálogo',
            onPressed: catalog == null
                ? null
                : () => setState(() => _catalogFuture = catalog.packages()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                  Expanded(
                    child: Text(
                      kIsWeb
                          ? 'Web tendrá una ruta offline independiente. Las descargas MBTiles se gestionan en plataformas nativas.'
                          : 'Descarga paquetes preparados y verificados antes de salir. La navegación básica puede continuar sin cobertura.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Tus zonas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (_regions.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Todavía no tienes ninguna zona offline instalada.'),
              ),
            )
          else
            ..._regions.map(
              (region) => _LocalRegionCard(
                region: region,
                onPause: region.status == OfflineRegionStatus.downloading ? () => _pause(region) : null,
                onResume: region.status == OfflineRegionStatus.paused || region.status == OfflineRegionStatus.failed ? () => _resume(region) : null,
                onVerify: region.status == OfflineRegionStatus.ready ? () => _verify(region) : null,
                onDelete: () => _delete(region),
              ),
            ),
          const SizedBox(height: 22),
          Text(
            'Paquetes disponibles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (catalog == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Catálogo offline no configurado. No se muestran paquetes ficticios.'),
              ),
            )
          else
            FutureBuilder(
              future: _catalogFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: LinearProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        'No se pudo cargar el catálogo. Comprueba la conexión y vuelve a intentarlo.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  );
                }
                final packages = snapshot.data?.data ?? const <OfflineMapPackage>[];
                if (packages.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text('No hay paquetes disponibles ahora mismo.'),
                    ),
                  );
                }
                return Column(
                  children: packages
                      .map(
                        (package) => _CatalogPackageCard(
                          package: package,
                          installed: _regions.any(
                            (item) =>
                                item.region.id == package.id &&
                                item.status == OfflineRegionStatus.ready,
                          ),
                          busy: _regions.any(
                            (item) =>
                                item.region.id == package.id &&
                                item.status == OfflineRegionStatus.downloading,
                          ),
                          onDownload: () => _download(package),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          const SizedBox(height: 20),
          Text(
            'Información crítica',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Los mapas offline llevan versión, proveedor, licencia, atribución e integridad verificable. La información dinámica conserva su frescura y no se presenta como actual si ha quedado obsoleta.',
          ),
        ],
      ),
    );
  }
}

class _LocalRegionCard extends StatelessWidget {
  const _LocalRegionCard({
    required this.region,
    required this.onDelete,
    this.onPause,
    this.onResume,
    this.onVerify,
  });

  final OfflineRegionRecord region;
  final VoidCallback onDelete;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onVerify;

  @override
  Widget build(BuildContext context) {
    final percent = (region.progress * 100).clamp(0, 100).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(region.status == OfflineRegionStatus.ready ? Icons.check_circle : Icons.map_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(region.region.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'pause':
                        onPause?.call();
                        break;
                      case 'resume':
                        onResume?.call();
                        break;
                      case 'verify':
                        onVerify?.call();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onPause != null) const PopupMenuItem(value: 'pause', child: Text('Pausar')),
                    if (onResume != null) const PopupMenuItem(value: 'resume', child: Text('Reanudar')),
                    if (onVerify != null) const PopupMenuItem(value: 'verify', child: Text('Verificar')),
                    const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${region.region.providerId} · ${region.region.styleVersion}'),
            if (region.bytesTotal > 0) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: region.progress),
              const SizedBox(height: 6),
              Text('${percent} %'),
            ],
            if (region.error != null) ...[
              const SizedBox(height: 8),
              Text(region.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogPackageCard extends StatelessWidget {
  const _CatalogPackageCard({
    required this.package,
    required this.installed,
    required this.busy,
    required this.onDownload,
  });

  final OfflineMapPackage package;
  final bool installed;
  final bool busy;
  final VoidCallback onDownload;

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.terrain_outlined),
        title: Text(package.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          '${_formatBytes(package.bytes)} · ${package.providerId} · detalle ${package.region.minZoom}-${package.region.maxZoom}',
        ),
        trailing: installed
            ? const Text('Listo')
            : busy
                ? const SizedBox(width: 92, child: LinearProgressIndicator())
                : FilledButton(onPressed: onDownload, child: const Text('Descargar')),
      ),
    );
  }
}
