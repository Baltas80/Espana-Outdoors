import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../../domain/offline_sync.dart';

final class HiveOfflineSyncStore implements OfflineSyncStore {
  HiveOfflineSyncStore({Box<dynamic>? box})
      : _box = box ?? Hive.box<dynamic>(_boxName);

  static const _boxName = 'offline_sync';

  final Box<dynamic> _box;

  @override
  Future<void> enqueue(SyncOperation operation) async {
    final existing = _read(operation.id);
    if (existing?.state == SyncOperationState.completed) return;
    await _box.put(operation.id, _encode(operation));
  }

  @override
  Future<List<SyncOperation>> pending({int limit = 50}) async {
    if (limit <= 0) return const [];

    final now = DateTime.now().toUtc();
    final operations = _box.values
        .map(_decode)
        .whereType<SyncOperation>()
        .where(
          (operation) =>
              (operation.state == SyncOperationState.pending ||
                  operation.state == SyncOperationState.retrying) &&
              (operation.nextAttemptAt == null ||
                  !operation.nextAttemptAt!.isAfter(now)),
        )
        .toList();

    operations.sort((a, b) {
      final priority = a.priority.index.compareTo(b.priority.index);
      if (priority != 0) return priority;
      return a.createdAt.compareTo(b.createdAt);
    });

    return List.unmodifiable(operations.take(limit));
  }

  @override
  Future<void> complete(String operationId) async {
    final operation = _read(operationId);
    if (operation == null) return;

    final completed = SyncOperation(
      id: operation.id,
      type: operation.type,
      payload: operation.payload,
      createdAt: operation.createdAt,
      priority: operation.priority,
      state: SyncOperationState.completed,
      attempts: operation.attempts,
    );
    await _box.put(operationId, _encode(completed));
  }

  @override
  Future<void> fail(
    String operationId, {
    required DateTime retryAt,
  }) async {
    final operation = _read(operationId);
    if (operation == null) return;
    await _box.put(
      operationId,
      _encode(operation.retry(nextAttemptAt: retryAt.toUtc())),
    );
  }

  @override
  Future<void> markFailed(String operationId) async {
    final operation = _read(operationId);
    if (operation == null) return;
    await _box.put(
      operationId,
      _encode(operation.markFailed()),
    );
  }

  @override
  Future<void> remove(String operationId) => _box.delete(operationId);

  Future<void> pruneCompleted({
    Duration retention = const Duration(days: 2),
  }) async {
    final cutoff = DateTime.now().toUtc().subtract(retention);
    final keys = <dynamic>[];

    for (final key in _box.keys) {
      final operation = _read(key.toString());
      if (operation?.state == SyncOperationState.completed &&
          operation!.createdAt.isBefore(cutoff)) {
        keys.add(key);
      }
    }

    for (final key in keys) {
      await _box.delete(key);
    }
  }

  SyncOperation? _read(String id) {
    final value = _box.get(id);
    return value is Map ? _decode(value) : null;
  }

  Map<String, Object?> _encode(SyncOperation operation) => {
        'id': operation.id,
        'type': operation.type,
        'payload': operation.payload,
        'createdAt': operation.createdAt.toUtc().toIso8601String(),
        'priority': operation.priority.name,
        'state': operation.state.name,
        'attempts': operation.attempts,
        'nextAttemptAt': operation.nextAttemptAt?.toUtc().toIso8601String(),
      };

  SyncOperation? _decode(dynamic raw) {
    if (raw is! Map) return null;

    final id = raw['id']?.toString() ?? '';
    final type = raw['type']?.toString() ?? '';
    final createdAt =
        DateTime.tryParse(raw['createdAt']?.toString() ?? '');
    if (id.isEmpty || type.isEmpty || createdAt == null) return null;

    final priority = SyncPriority.values
        .where((item) => item.name == raw['priority']?.toString())
        .firstOrNull;
    final state = SyncOperationState.values
        .where((item) => item.name == raw['state']?.toString())
        .firstOrNull;
    final payload = raw['payload'];

    if (priority == null || state == null || payload is! Map) return null;

    return SyncOperation(
      id: id,
      type: type,
      payload: Map<String, Object?>.from(payload),
      createdAt: createdAt.toUtc(),
      priority: priority,
      state: state,
      attempts:
          raw['attempts'] is num ? (raw['attempts'] as num).toInt() : 0,
      nextAttemptAt: DateTime.tryParse(
        raw['nextAttemptAt']?.toString() ?? '',
      )?.toUtc(),
    );
  }
}
