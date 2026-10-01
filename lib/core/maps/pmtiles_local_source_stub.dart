Future<String?> findLocalPmTiles({String? expectedFileName}) async => null;

Future<String?> findValidLocalPmTiles({
  required String expectedFileName,
  required String expectedSha256,
}) async =>
    null;

Future<String> serveLocalPmTiles(String path) async =>
    throw UnsupportedError('Local PMTiles serving is native-only.');
