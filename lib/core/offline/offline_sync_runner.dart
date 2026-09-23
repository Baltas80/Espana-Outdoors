import '../../domain/offline_sync.dart';

final class SyncExecutionResult {
  const SyncExecutionResult._(this.success, this.retryable);

  const SyncExecutionResult.success() : this._(true, false);

  const SyncExecutionResult.retryableFailure() : this._(false, true);

  const SyncExecutionResult.permanentFailure() : this._(false, false);

  final bool success;
  final bool retryable;
}

typedef SyncOperationExecutor =
    Future<SyncExecutionResult> Function(SyncOperation operation);

final class OfflineSyncRunner {
  OfflineSyncRunner({
    required OfflineSyncStore store,
    required SyncOperationExecutor execute,
  })  : _store = store,
        _execute = execute;

  final OfflineSyncStore _store;
  final SyncOperationExecutor _execute;

  Future<int> runOnce({int limit = 50, int maxAttempts = 8}) async {
    if (limit <= 0 || maxAttempts <= 0) return 0;

    var completed = 0;
    final operations = await _store.pending(limit: limit);

    for (final operation in operations) {
      try {
        final result = await _execute(operation);
        if (result.success) {
          await _store.complete(operation.id);
          completed += 1;
        } else if (result.retryable &&
            operation.attempts + 1 < maxAttempts) {
          await _defer(operation);
        } else {
          await _store.remove(operation.id);
        }
      } on Object {
        if (operation.attempts + 1 < maxAttempts) {
          await _defer(operation);
        } else {
          await _store.remove(operation.id);
        }
      }
    }

    return completed;
  }

  Future<void> _defer(SyncOperation operation) {
    return _store.fail(
      operation.id,
      retryAt: DateTime.now().toUtc().add(_backoff(operation.attempts)),
    );
  }

  Duration _backoff(int attempts) {
    final seconds = switch (attempts) {
      0 => 2,
      1 => 5,
      2 => 15,
      3 => 30,
      4 => 60,
      5 => 120,
      _ => 300,
    };
    return Duration(seconds: seconds);
  }
}
