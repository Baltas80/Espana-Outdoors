import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:espana_outdoors/core/offline/offline_package_verifier.dart';

void main() {
  test('accepts matching SHA-256', () async {
    final file = File(
      Directory.systemTemp.path + '/espana-outdoors-hash-test.txt',
    );
    await file.writeAsString('abc');

    addTearDown(() async {
      if (await file.exists()) await file.delete();
    });

    await const OfflinePackageVerifier().verifyFile(
      file,
      expectedSha256:
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('rejects a checksum mismatch', () async {
    final file = File(
      Directory.systemTemp.path + '/espana-outdoors-hash-mismatch.txt',
    );
    await file.writeAsString('abc');

    expect(
      () => const OfflinePackageVerifier().verifyFile(
        file,
        expectedSha256: List.filled(64, '0').join(),
      ),
      throwsStateError,
    );

    expect(await file.exists(), isFalse);
  });
}
