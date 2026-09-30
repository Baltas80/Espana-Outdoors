import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/photo_atlas.dart';
import '../../app/outdoor_visuals.dart';
import '../../core/maps/agus_maps_runtime.dart';
import '../../core/maps/comaps_download_manager.dart';

class OfflinePage extends StatefulWidget {
  const OfflinePage({super.key});

  @override
  State<OfflinePage> createState() => _OfflinePageState();
}

class _OfflinePageState extends State<OfflinePage> {
  late Future<CoMapsSpainPlan> _planFuture;
  bool _downloading = false;
  double _progress = 0;
  String _status = 'Preparando catálogo CoMaps…';

  @override
  void initState() {
    super.initState();
    _planFuture = _loadPlan();
  }

  Future<CoMapsSpainPlan> _loadPlan() async {
    await AgusMapsRuntime.instance.ensureInitialized();
    return CoMapsDownloadManager.instance.resolveSpain();
  }

  Future<void> _downloadSpain(CoMapsSpainPlan plan) async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = 0;
      _status = 'Descargando España…';
    });
    try {
      await CoMapsDownloadManager.instance.downloadSpain(
        onProgress: (region, received, total, completed, count) {
          if (!mounted) return;
          setState(() {
            final current = total <= 0 ? 0.0 : received / total;
            _progress = count == 0
                ? 0.0
                : ((completed + current) / count).clamp(0.0, 1.0);
            final label = region?.displayName ?? 'España';
            _status = 'Descargando $label · ${(_progress * 100).toStringAsFixed(0)}%';
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _progress = 1;
        _status = 'España descargada y verificada.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapas offline')),
      body: SafeArea(
        child: FutureBuilder<CoMapsSpainPlan>(
          future: _planFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _MapCatalogError(
                message: snapshot.error.toString(),
                onRetry: () => setState(() => _planFuture = _loadPlan()),
              );
            }
            final plan = snapshot.data;
            if (plan == null) return const Center(child: CircularProgressIndicator());
            final installedMaps = AgusMapsRuntime.instance.storage?.getAll().where((map) => !map.isBundled).length ?? 0;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const OutdoorPhotoHero(index: 11, title: 'Offline', subtitle: 'Mapas sin conexión y gestión de descargas.'),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OutdoorAssetIcon(asset: 'assets/visuals/icons/offline.svg', size: 46),
                        const SizedBox(width: 14),
                        const Expanded(child: Text('Gestión de cartografía offline. El mapa principal de España Outdoor utiliza PMTiles; esta pantalla conserva compatibilidad con el catálogo heredado mientras completamos la migración del almacenamiento offline.')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('España', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${plan.label} · versión ${plan.snapshot.formattedDate}'),
                const SizedBox(height: 4),
                Text('${_size(plan.totalBytes)} · ${plan.leaves.length} archivos de región'),
                const SizedBox(height: 14),
                if (_downloading || _progress > 0) ...[
                  LinearProgressIndicator(value: _progress),
                  const SizedBox(height: 8),
                  Text(_status),
                ] else
                  Text(_status),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _downloading ? null : () => _downloadSpain(plan),
                  icon: const Icon(Icons.download_outlined),
                  label: Text(installedMaps == 0 ? 'Descargar España' : 'Actualizar / comprobar España'),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.storage_outlined),
                        const SizedBox(width: 12),
                        Expanded(child: Text(installedMaps == 0 ? 'Aún no hay regiones heredadas instaladas en el dispositivo.' : '$installedMaps regiones heredadas instaladas.')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Motor cartográfico', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                const Text('El mapa principal utiliza PMTiles con flutter_map_vector_tiles. Agus Maps queda solamente como compatibilidad heredada de esta pantalla y no participa en el renderizado principal.'),
              ],
            );
          },
        ),
      ),
    );
  }
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
              const Icon(Icons.cloud_off_outlined, size: 52),
              const SizedBox(height: 14),
              const Text('No se pudo obtener el catálogo de mapas', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
            ],
          ),
        ),
      );
}
