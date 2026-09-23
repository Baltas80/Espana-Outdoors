import 'package:flutter/foundation.dart';

import '../map/map_service.dart';
import 'offline_region_store.dart';

class OfflineRegionManager extends ChangeNotifier {
  OfflineRegionManager({
    required OfflineRegionStore store,
    required MapService mapService,
  })  : _store = store,
        _mapService = mapService;

  final OfflineRegionStore _store;
  final MapService _mapService;
  final Set<String> _busyRegions = <String>{};

  List<OfflineRegionRecord> get regions => _store.all();
  bool get busy => _busyRegions.isNotEmpty;
  bool isBusy(String regionId) => _busyRegions.contains(regionId);

  Future<void> queue(OfflineMapRegion region) async {
    if (!region.isValid) {
      throw ArgumentError.value(
        region,
        'region',
        'Invalid offline map region',
      );
    }
    await _store.put(
      OfflineRegionRecord(
        region: region,
        status: OfflineRegionStatus.queued,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    notifyListeners();
  }

  Future<void> prepare(String regionId) async {
    if (_busyRegions.contains(regionId)) return;
    final record = _store.get(regionId);
    if (record == null) return;

    _busyRegions.add(regionId);
    await _store.put(
      record.copyWith(
        status: OfflineRegionStatus.downloading,
        updatedAt: DateTime.now().toUtc(),
        error: null,
      ),
    );
    notifyListeners();

    try {
      await _mapService.prepareOfflineRegion(record.region);
      final current = _store.get(regionId);
      if (current != null) {
        await _store.put(
          current.copyWith(
            status: OfflineRegionStatus.ready,
            progress: 1,
            updatedAt: DateTime.now().toUtc(),
            error: null,
          ),
        );
      }
    } catch (error) {
      final current = _store.get(regionId);
      if (current != null) {
        await _store.put(
          current.copyWith(
            status: OfflineRegionStatus.failed,
            updatedAt: DateTime.now().toUtc(),
            error: error.toString(),
          ),
        );
      }
      rethrow;
    } finally {
      _busyRegions.remove(regionId);
      notifyListeners();
    }
  }

  Future<void> pause(String regionId) async {
    if (isBusy(regionId)) return;
    await _mapService.pauseOfflineRegion(regionId);
    final current = _store.get(regionId);
    if (current != null) {
      await _store.put(
        current.copyWith(
          status: OfflineRegionStatus.paused,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      notifyListeners();
    }
  }

  Future<void> resume(String regionId) => prepare(regionId);

  Future<void> delete(String regionId) async {
    if (_busyRegions.contains(regionId)) {
      throw StateError('Offline region is busy.');
    }
    final current = _store.get(regionId);
    if (current != null) {
      await _store.put(
        current.copyWith(
          status: OfflineRegionStatus.deleting,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    _busyRegions.add(regionId);
    notifyListeners();
    try {
      await _mapService.deleteOfflineRegion(regionId);
      await _store.remove(regionId);
    } finally {
      _busyRegions.remove(regionId);
      notifyListeners();
    }
  }
}