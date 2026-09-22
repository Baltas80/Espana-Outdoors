import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/offline/archive_models.dart';

void main() {
  test('archive progress clamps its fraction', () {
    const progress = OfflineArchiveProgress(completedBytes: 120, totalBytes: 100);
    expect(progress.fraction, 1);
  });

  test('archive progress is unknown when total size is unavailable', () {
    const progress = OfflineArchiveProgress(completedBytes: 100);
    expect(progress.fraction, isNull);
  });
}
