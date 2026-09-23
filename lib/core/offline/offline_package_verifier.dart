import 'dart:io';

import 'package:crypto/crypto.dart';

final class OfflinePackageVerifier {
  const OfflinePackageVerifier();

  Future<void> verifyFile(
    File file, {
    required String? expectedSha256,
    bool requireChecksum = true,
  }) async {
    if (!await file.exists()) {
      throw StateError('Offline package does not exist.');
    }

    final expected = expectedSha256?.trim().toLowerCase();
    if (expected == null || expected.isEmpty) {
      if (requireChecksum) {
        throw StateError(
          'Offline package is missing a required SHA-256 checksum.',
        );
      }
      return;
    }

    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(expected)) {
      throw FormatException(
        'Invalid SHA-256 checksum: ' + expected,
      );
    }

    final digest = await sha256.bind(file.openRead()).first;
    final actual = digest.toString().toLowerCase();

    if (actual != expected) {
      try {
        await file.delete();
      } catch (_) {}
      throw StateError('Offline package SHA-256 verification failed.');
    }
  }
}
