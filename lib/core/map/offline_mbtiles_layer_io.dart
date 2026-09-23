import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_mbtiles/flutter_map_mbtiles.dart';
import 'package:latlong2/latlong.dart';

import '../offline/offline_archive_path.dart';
import '../offline/offline_region_store.dart';

class OfflineMbtilesLayer extends StatefulWidget {
  const OfflineMbtilesLayer({
    required this.anchor,
    super.key,
  });

  final LatLng anchor;

  @override
  State<OfflineMbtilesLayer> createState() => _OfflineMbtilesLayerState();
}

class _OfflineMbtilesLayerState extends State<OfflineMbtilesLayer> {
  Future<MbTilesTileProvider?>? _providerFuture;
  MbTilesTileProvider? _provider;

  @override
  void initState() {
    super.initState();
    _providerFuture = _openProvider(widget.anchor);
  }

  @override
  void didUpdateWidget(covariant OfflineMbtilesLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_movedEnough(oldWidget.anchor, widget.anchor)) {
      _providerFuture = _openProvider(widget.anchor);
      _provider?.dispose();
      _provider = null;
    }
  }

  bool _movedEnough(LatLng a, LatLng b) =>
      (a.latitude - b.latitude).abs() > 0.02 ||
      (a.longitude - b.longitude).abs() > 0.02;

  Future<MbTilesTileProvider?> _openProvider(LatLng anchor) async {
    final records = OfflineRegionStore().all().where(
          (item) => item.status == OfflineRegionStatus.ready,
        );

    for (final record in records) {
      final bounds = record.region.bounds;
      final contains = anchor.latitude >= bounds.south &&
          anchor.latitude <= bounds.north &&
          anchor.longitude >= bounds.west &&
          anchor.longitude <= bounds.east;
      if (!contains) continue;

      final path = await offlineArchivePath(record.region.id);
      if (!await File(path).exists()) continue;

      try {
        final provider = await MbTilesTileProvider.fromSource(path);
        if (!mounted) {
          provider.dispose();
          return null;
        }
        _provider = provider;
        return provider;
      } on Object {
        continue;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _provider?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MbTilesTileProvider?>(
      future: _providerFuture,
      builder: (context, snapshot) {
        final provider = snapshot.data;
        if (provider == null) return const SizedBox.shrink();
        return TileLayer(tileProvider: provider);
      },
    );
  }
}
