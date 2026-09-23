import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:espana_outdoors/core/offline/hive_offline_sync_store.dart';
import 'package:espana_outdoors/core/offline/offline_sync_runner.dart';
import 'package:espana_outdoors/domain/offline_sync.dart';

void main() {
  group('OfflineSyncRunner', () {
    late Box<dynamic> box;
    late HiveOfflineSyncStore store;

    setUp(() async {
      await Hive.initFlutter();
      box = await Hive.openBox<dynamic>('offline_sync_runner_test');
      await box.clear();
      store = HiveOfflineSyncStore(box: box);
    });

    tearDown(() async {
      await box.close();
      await Hive.deleteBoxFromDisk('offline_sync_runner_test');
    });

    test('completes successful operations', () async {
      await store.enqueue(
        SyncOperation(
          id: 'ok',
          type: 'route.update',
          payload: const {},
          createdAt: DateTime.utc(2026, 9, 23),
          priority: SyncPriority.normal,
        ),
      );

      final runner = OfflineSyncRunner(
        store: store,
        execute: (_) async => const SyncExecutionResult.success(),
      );

      expect(await runner.runOnce(), 1);
      expect(await store.pending(), isEmpty);
    });

    test('defers retryable failures', () async {
      await store.enqueue(
        SyncOperation(
          id: 'retry',
          type: 'route.update',
          payload: const {},
          createdAt: DateTime.utc(2026, 9, 23),
          priority: SyncPriority.normal,
        ),
      );

      final runner = OfflineSyncRunner(
        store: store,
        execute: (_) async => const SyncExecutionResult.retryableFailure(),
      );

      expect(await runner.runOnce(), 0);
      expect(await store.pending(), isEmpty);
    });
  });
}