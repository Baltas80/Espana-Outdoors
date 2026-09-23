import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:espana_outdoors/core/offline/hive_offline_sync_store.dart';
import 'package:espana_outdoors/domain/offline_sync.dart';

void main() {
  group('HiveOfflineSyncStore', () {
    late Directory hiveDir;
    late Box<dynamic> box;
    late HiveOfflineSyncStore store;

    setUpAll(() async {
      hiveDir = await Directory.systemTemp.createTemp('espana-outdoors-hive-');
      Hive.init(hiveDir.path);
    });

    setUp(() async {
      box = await Hive.openBox<dynamic>('offline_sync_test');
      await box.clear();
      store = HiveOfflineSyncStore(box: box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('offline_sync_test');
    });

    tearDownAll(() async {
      await Hive.close();
      if (await hiveDir.exists()) await hiveDir.delete(recursive: true);
    });

    test('orders due operations by priority and creation time', () async {
      final now = DateTime.utc(2026, 9, 23, 12);
      await store.enqueue(
        SyncOperation(
          id: 'normal',
          type: 'route.update',
          payload: const {'value': 1},
          createdAt: now,
          priority: SyncPriority.normal,
        ),
      );
      await store.enqueue(
        SyncOperation(
          id: 'critical',
          type: 'sos.create',
          payload: const {'value': 2},
          createdAt: now.add(const Duration(minutes: 1)),
          priority: SyncPriority.critical,
        ),
      );

      final pending = await store.pending();
      expect(pending.map((item) => item.id).toList(), ['critical', 'normal']);
    });

    test('completed operation is idempotent on duplicate enqueue', () async {
      final operation = SyncOperation(
        id: 'same-id',
        type: 'route.update',
        payload: const {'value': 1},
        createdAt: DateTime.utc(2026, 9, 23),
        priority: SyncPriority.normal,
      );

      await store.enqueue(operation);
      await store.complete(operation.id);
      await store.enqueue(
        SyncOperation(
          id: operation.id,
          type: operation.type,
          payload: const {'value': 2},
          createdAt: operation.createdAt,
          priority: operation.priority,
        ),
      );

      expect(await store.pending(), isEmpty);
    });

    test('retry is hidden until retry time', () async {
      final operation = SyncOperation(
        id: 'retry-me',
        type: 'weather.refresh',
        payload: const {},
        createdAt: DateTime.utc(2026, 9, 23),
      );

      await store.enqueue(operation);
      await store.fail(
        operation.id,
        retryAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      expect(await store.pending(), isEmpty);
    });
  });
}