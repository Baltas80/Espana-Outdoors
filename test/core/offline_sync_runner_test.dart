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

    test('retains permanent failures instead of dropping work', () async {
      await store.enqueue(
        SyncOperation(
          id: 'permanent',
          type: 'route.update',
          payload: const {},
          createdAt: DateTime.utc(2026, 9, 23),
          priority: SyncPriority.normal,
        ),
      );

      final runner = OfflineSyncRunner(
        store: store,
        execute: (_) async => const SyncExecutionResult.permanentFailure(),
      );

      expect(await runner.runOnce(), 0);

      final raw = await box.get('permanent');
      expect(raw, isA<Map>());
      expect(
        (raw!['state'] ?? '').toString(),
        SyncOperationState.failed.name,
      );
      expect(await store.pending(), isEmpty);
    });

    test('moves exceptions to failed state after max attempts', () async {
      await store.enqueue(
        SyncOperation(
          id: 'exception',
          type: 'route.update',
          payload: const {},
          createdAt: DateTime.utc(2026, 9, 23),
          priority: SyncPriority.normal,
          attempts: 7,
        ),
      );

      final runner = OfflineSyncRunner(
        store: store,
        execute: (_) async => throw StateError('boom'),
      );

      expect(await runner.runOnce(maxAttempts: 8), 0);

      final raw = await box.get('exception');
      expect(raw, isA<Map>());
      expect(
        (raw!['state'] ?? '').toString(),
        SyncOperationState.failed.name,
      );
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