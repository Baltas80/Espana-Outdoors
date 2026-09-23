import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/offline/offline_region.dart';
import '../../core/offline/offline_region_catalog.dart';
import '../../core/offline/offline_region_downloader.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  final _downloader = const OfflineRegionDownloader();
  late Future<List<OfflineRegion>> _catalogFuture;
  final Map<String, Transfer> _transfers = {};

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  Future<List<OfflineRegion>> _loadCatalog() async {
    final endpoint = OfflineRegionCatalog.fromEnvironment();
    if (endpoint == null) return const [];
    return OfflineRegionCatalog(endpoint: endpoint).fetch();
  }

  Future<void> _download(OfflineRegion region) async {
    try {
      final transfer = await _downloader.start(region);
      if (!mounted) return;
      setState(() => _transfers[region.id] = transfer);
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapas offline')),
      body: SafeArea(
        child: ListView(
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
                        'Prepara una zona antes de salir. Los paquetes publicados por España Outdoor incluyen metadatos de versión y procedencia y pueden reanudarse cuando la plataforma lo permita.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Catálogo disponible',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<OfflineRegion>>(
              future: _catalogFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return _CatalogMessage(
                    icon: Icons.error_outline,
                    message: 'No se ha podido consultar el catálogo. Los mapas locales existentes siguen siendo utilizables.',
                  );
                }
                final regions = snapshot.data ?? const [];
                if (regions.isEmpty) {
                  return _CatalogMessage(
                    icon: Icons.cloud_off_outlined,
                    message: 'El catálogo de regiones todavía no está configurado o no ha publicado paquetes. No se muestran zonas ficticias.',
                  );
                }
                return Column(
                  children: [
                    for (final region in regions) _regionCard(region),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Principio de seguridad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'La aplicación diferencia datos descargados de información dinámica. Un paquete offline no se presenta como una alerta actual si su vigencia ha expirado.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _regionCard(OfflineRegion region) {
    final transfer = _transfers[region.id];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(region.name, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(region.description),
            const SizedBox(height: 4),
            Text('${_size(region.sizeBytes)} · actualizado ${region.updatedAt.toLocal()}'),
            if (transfer != null) ...[
              const SizedBox(height: 10),
              ValueListenableBuilder<double?>(
                valueListenable: transfer.progressNotifier,
                builder: (_, progress, __) => LinearProgressIndicator(value: progress),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<TaskStatus>(
                valueListenable: transfer.statusNotifier,
                builder: (_, status, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(status.name),
                    Row(
                      children: [
                        if (status == TaskStatus.running)
                          IconButton(
                            tooltip: 'Pausar',
                            onPressed: () => _downloader.pause(transfer),
                            icon: const Icon(Icons.pause),
                          ),
                        if (status == TaskStatus.paused)
                          IconButton(
                            tooltip: 'Reanudar',
                            onPressed: () => _downloader.resume(transfer),
                            icon: const Icon(Icons.play_arrow),
                          ),
                        IconButton(
                          tooltip: 'Cancelar',
                          onPressed: () => _downloader.cancel(transfer),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: kIsWeb ? null : () => _download(region),
                  icon: const Icon(Icons.download),
                  label: const Text('Descargar'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatalogMessage extends StatelessWidget {
  const _CatalogMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
