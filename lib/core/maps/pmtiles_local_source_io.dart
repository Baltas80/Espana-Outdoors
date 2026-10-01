import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../offline/offline_package_verifier.dart';

HttpServer? _server;
String? _servedPath;
int? _servedPort;

Future<String?> findLocalPmTiles({String? expectedFileName}) async {
  final root = await getApplicationSupportDirectory();
  final directory = Directory(
    '${root.path}${Platform.pathSeparator}offline_regions',
  );
  if (!await directory.exists()) return null;

  if (expectedFileName != null && expectedFileName.trim().isNotEmpty) {
    final file = File(
      '${directory.path}${Platform.pathSeparator}${expectedFileName.trim()}',
    );
    try {
      if (await file.length() > 0) return file.path;
    } on FileSystemException {
      return null;
    }
    return null;
  }

  final candidates = <File>[];
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.pmtiles')) {
      candidates.add(entity);
    }
  }

  candidates.sort((a, b) => a.path.compareTo(b.path));
  for (final file in candidates) {
    try {
      if (await file.length() > 0) return file.path;
    } on FileSystemException {
      // A concurrently removed/incomplete download is simply skipped.
    }
  }
  return null;
}

Future<String?> findValidLocalPmTiles({
  required String expectedFileName,
  required String expectedSha256,
}) async {
  final path = await findLocalPmTiles(expectedFileName: expectedFileName);
  if (path == null) return null;

  final file = File(path);
  try {
    await const OfflinePackageVerifier().verifyFile(
      file,
      expectedSha256: expectedSha256,
    );
    return file.path;
  } on Object {
    return null;
  }
}

/// Exposes a verified local archive only through a loopback HTTP endpoint.
///
/// flutter_map_vector_tiles' PMTiles provider is URL/range based. A loopback
/// server keeps the archive entirely on-device while preserving that mature
/// provider implementation and its range-request semantics. The listener is
/// bound exclusively to localhost and serves exactly one immutable file.
Future<String> serveLocalPmTiles(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('No existe el archivo PMTiles local: $path');
  }
  if (await file.length() <= 0) {
    throw StateError('El archivo PMTiles local está vacío: $path');
  }

  if (_server != null && _servedPath == file.path && _servedPort != null) {
    return 'http://localhost:$_servedPort/archive.pmtiles';
  }

  await _server?.close(force: true);
  _server = null;
  _servedPath = null;
  _servedPort = null;

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  _server = server;
  _servedPath = file.path;
  _servedPort = server.port;

  unawaited(_serve(server, file));
  return 'http://localhost:${server.port}/archive.pmtiles';
}

Future<void> _serve(HttpServer server, File file) async {
  await for (final request in server) {
    try {
      if (request.uri.path != '/archive.pmtiles' ||
          (request.method != 'GET' && request.method != 'HEAD')) {
        request.response
          ..statusCode = HttpStatus.notFound
          ..close();
        continue;
      }

      final length = await file.length();
      final range = _parseRange(
        request.headers.value(HttpHeaders.rangeHeader),
        length,
      );
      request.response.headers
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..set(HttpHeaders.contentTypeHeader, 'application/octet-stream');

      if (range == null) {
        request.response
          ..statusCode = HttpStatus.ok
          ..contentLength = length;
        if (request.method == 'HEAD') {
          await request.response.close();
        } else {
          await request.response.addStream(file.openRead());
        }
        continue;
      }

      final (start, end) = range;
      request.response
        ..statusCode = HttpStatus.partialContent
        ..contentLength = end - start + 1
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $start-$end/$length',
        );
      if (request.method == 'HEAD') {
        await request.response.close();
      } else {
        await request.response.addStream(file.openRead(start, end + 1));
      }
    } on Object {
      if (!request.response.headers.chunkedTransferEncoding) {
        request.response.statusCode = HttpStatus.internalServerError;
      }
      await request.response.close();
    }
  }
}

(int, int)? _parseRange(String? header, int length) {
  if (header == null || !header.startsWith('bytes=') || length <= 0) return null;
  final value = header.substring('bytes='.length).split(',').first.trim();
  final separator = value.indexOf('-');
  if (separator < 0) return null;

  final startText = value.substring(0, separator).trim();
  final endText = value.substring(separator + 1).trim();
  final start = int.tryParse(startText);
  final requestedEnd = int.tryParse(endText);

  if (start == null) {
    final suffixLength = requestedEnd;
    if (suffixLength == null || suffixLength <= 0) return null;
    final suffixStart = length - suffixLength;
    return (suffixStart < 0 ? 0 : suffixStart, length - 1);
  }
  if (start < 0 || start >= length) return null;

  final end = requestedEnd == null || requestedEnd >= length
      ? length - 1
      : requestedEnd;
  if (end < start) return null;
  return (start, end);
}
