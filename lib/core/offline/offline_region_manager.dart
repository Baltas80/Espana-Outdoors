import 'package:flutter/foundation.dart';

import '../map/map_service.dart';
import 'offline_region_store.dart';

/// Coordinates durable offline-region state with the provider-neutral map layer.
/// The concrete map provider owns tile/vector/raster transfer; this manager
/// owns lifecycle state so the UI does not depend on a vendor SDK.
class OfflineRegionManager extends ChangeNotifier {
  OfflineRegionManager({
    required OfflineRegionStore store,
    required MapService mapService,
  })  : _store = store,
        _mapService = mapService;

  final OfflineRegionStore _store;
  final MapService _mapService;
  bool _busy = false;

  List<OfflineRegionRecord> get regions => _store.all();
  bool get busy => _busy;

  Future<void> queue(OfflineMapRegion region) async {
    if (!region.isValid) {
      throw ArgumentError.value(region, 'region', 'Invalid offline map region');
    }
    await _store.put(OfflineRegionRecord(
      region: region,
      status: OfflineRegionStatus.queued,
      updatedAt: DateTime.now().toUtc(),
    ));
    notifyListeners();
  }

  Future<void> prepare(String regionId) async {
    final record = _store.get(regionId);
    if (record == null) return;
    _busy = true;
    await _store.put(record.copyWith(
      status: OfflineRegionStatus.downloading,
      updatedAt: DateTime.now().toUtc(),
      error: null,
    ));
    notifyListeners();
    try {
      await _mapService.prepareOfflineRegion(record.region);
      final current = _store.get(regionId);
      if (current != null) {
        await _store.put(current.copyWith(
          status: OfflineRegionStatus.ready,
          progress: 1,
          updatedAt: DateTime.now().toUtc(),
          error: null,
        ));
      }
    } catch (error) {
      final current = _store.get(regionId);
      if (current != null) {
        await _store.put(current.copyWith(
          status: OfflineRegionStatus.failed,
          updatedAt: DateTime.now().toUtc(),
          error: error.toString(),
        ));
      }
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> pause(String regionId) async {
    await _mapService.pauseOfflineRegion(regionId);
    final current = _store.get(regionId);
    if (current != null) {
      await _store.put(current.copyWith(
        status: OfflineRegionStatus.paused,
        updatedAt: DateTime.now().toUtc(),
      ));
      notifyListeners();
    }
  }

  Future<void> resume(String regionId) => prepare(regionId);

  Future<void> delete(String regionId) async {
    final current = _store.get(regionId);
    if (current != null) {
      await _store.put(current.copyWith(
        status: OfflineRegionStatus.deleting,
        updatedAt: DateTime.now().toUtc(),
      ));
    }
    notifyListeners();
    await _mapService.deleteOfflineRegion(regionId);
    await _store.remove(regionId);
    notifyListeners();
  }
}
