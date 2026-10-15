import 'dart:io';
import 'dart:typed_data';

import 'package:espana_outdoors/core/offline/offline_package_verifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File file;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('offline-verifier-');
    file = File('${directory.path}/region.pmtiles');
    await file.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('rejects a checksum mismatch and deletes the invalid artifact', () async {
    await expectLater(
      const OfflinePackageVerifier().verifyFile(
        file,
        expectedSha256: List.filled(64, '0').join(),
        expectedBytes: 4,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await file.exists(), isFalse);
  });

  test('rejects a size mismatch and deletes the invalid artifact', () async {
    await expectLater(
      const OfflinePackageVerifier().verifyFile(
        file,
        expectedSha256: List.filled(64, '0').join(),
        expectedBytes: 5,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await file.exists(), isFalse);
  });

  test('does not accept a missing checksum when checksum is required', () async {
    await expectLater(
      const OfflinePackageVerifier().verifyFile(
        file,
        expectedSha256: null,
      ),
      throwsA(isA<StateError>()),
    );

    expect(await file.exists(), isFalse);
  });
}
