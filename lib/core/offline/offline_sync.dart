enum SyncOperationType { create, update, delete }

enum SyncPriority { critical, high, normal, low }

final class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.type,
    required this.payload,
    required this.createdAt,
    required this.priority,
  });

  final String id;
  final String entity;
  final String entityId;
  final SyncOperationType type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final SyncPriority priority;
}

/// Small offline-first contract. The implementation can use Hive/SQLite or a
/// server-backed queue without leaking that choice into product features.
abstract interface class OfflineSyncStore {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> pending({int limit = 100});
  Future<void> acknowledge(String operationId);
  Future<void> defer(String operationId, {required DateTime retryAt});
}

abstract interface class OfflineSyncEngine {
  Future<void> flush();
  Future<void> reconcile();
}
