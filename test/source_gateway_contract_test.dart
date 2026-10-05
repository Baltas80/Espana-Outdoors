import 'package:flutter_test/flutter_test.dart';

import 'package:espana_outdoors/core/contracts/source_gateway.dart';

void main() {
  test('stale snapshots are never fresh', () {
    final snapshot = SourceSnapshot(
      sourceId: 'aemet-weather',
      kind: SourceKind.official,
      status: SourceStatus.stale,
      observedAt: DateTime.utc(2026, 9, 23, 12),
    );

    expect(snapshot.isFresh, isFalse);
  });

  test('unavailable snapshots are never fresh', () {
    final snapshot = SourceSnapshot(
      sourceId: 'aemet-weather',
      kind: SourceKind.official,
      status: SourceStatus.unavailable,
      observedAt: DateTime.utc(2026, 9, 23, 12),
    );

    expect(snapshot.isFresh, isFalse);
  });

  test('healthy snapshots without expiry remain fresh', () {
    final snapshot = SourceSnapshot(
      sourceId: 'aemet-weather',
      kind: SourceKind.official,
      status: SourceStatus.healthy,
      observedAt: DateTime.utc(2026, 9, 23, 12),
    );

    expect(snapshot.isFresh, isTrue);
  });
}
