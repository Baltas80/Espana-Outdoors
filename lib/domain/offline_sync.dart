enum SyncPriority { critical, high, normal, low }
enum SyncOperationState { pending, running, retrying, completed, failed }

class SyncOperation {
  const SyncOperation({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.priority = SyncPriority.normal,
    this.state = SyncOperationState.pending,
    this.attempts = 0,
    this.nextAttemptAt,
  });

  final String id;
  final String type;
  final Map<String, Object?> payload;
  final DateTime createdAt;
  final SyncPriority priority;
  final SyncOperationState state;
  final int attempts;
  final DateTime? nextAttemptAt;

  SyncOperation retry({DateTime? nextAttemptAt}) => SyncOperation(
        id: id,
        type: type,
        payload: payload,
        createdAt: createdAt,
        priority: priority,
        state: SyncOperationState.retrying,
        attempts: attempts + 1,
        nextAttemptAt: nextAttemptAt,
      );
}

abstract interface class OfflineSyncStore {
  Future<void> enqueue(SyncOperation operation);
  Future<List<SyncOperation>> pending({int limit = 50});
  Future<void> complete(String operationId);
  Future<void> fail(String operationId, {required DateTime retryAt});
  Future<void> remove(String operationId);
}

/// Coordinates local-first writes. Network adapters remain outside the domain.
class OfflineSyncCoordinator {
  OfflineSyncCoordinator(this.store);

  final OfflineSyncStore store;

  Future<void> enqueue(SyncOperation operation) => store.enqueue(operation);

  Future<List<SyncOperation>> drain({int limit = 50}) async {
    final operations = await store.pending(limit: limit);
    return List.unmodifiable(operations);
  }
}
