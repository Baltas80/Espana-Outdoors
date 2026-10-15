import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
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
/// The listener is bound exclusively to localhost and serves exactly one file.
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

  await closeLocalPmTilesServer();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  _server = server;
  _servedPath = file.path;
  _servedPort = server.port;

  unawaited(_serve(server, file));
  return 'http://localhost:${server.port}/archive.pmtiles';
}

/// Test seam to ensure the loopback listener is closed after HTTP tests.
@visibleForTesting
Future<void> closeLocalPmTilesServer() async {
  final server = _server;
  _server = null;
  _servedPath = null;
  _servedPort = null;
  await server?.close(force: true);
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
        ..set(HttpHeaders.contentTypeHeader, 'application/vnd.pmtiles');

      if (range.kind == _RangeKind.unsatisfiable) {
        request.response
          ..statusCode = HttpStatus.requestedRangeNotSatisfiable
          ..headers.set(HttpHeaders.contentRangeHeader, 'bytes */$length')
          ..contentLength = 0;
        await request.response.close();
        continue;
      }

      final span = range.span;
      if (span == null) {
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

      request.response
        ..statusCode = HttpStatus.partialContent
        ..contentLength = span.end - span.start + 1
        ..headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes ${span.start}-${span.end}/$length',
        );
      if (request.method == 'HEAD') {
        await request.response.close();
      } else {
        await request.response.addStream(
          file.openRead(span.start, span.end + 1),
        );
      }
    } on Object {
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..contentLength = 0;
        await request.response.close();
      } on Object {
        // The peer may have disconnected or the response may already be closed.
      }
    }
  }
}

enum _RangeKind { full, partial, unsatisfiable }

class _ByteSpan {
  const _ByteSpan(this.start, this.end);

  final int start;
  final int end;
}

class _RangeOutcome {
  const _RangeOutcome._(this.kind, this.span);

  const _RangeOutcome.full() : this._(_RangeKind.full, null);
  const _RangeOutcome.unsatisfiable()
      : this._(_RangeKind.unsatisfiable, null);
  const _RangeOutcome.partial(_ByteSpan span)
      : this._(_RangeKind.partial, span);

  final _RangeKind kind;
  final _ByteSpan? span;
}

/// Invalid/unsupported Range fields are ignored (full response). A syntactically
/// valid range whose first byte is outside the representation returns 416.
_RangeOutcome _parseRange(String? header, int length) {
  if (header == null || length <= 0) return const _RangeOutcome.full();

  // This endpoint intentionally supports one byte range. Do not silently
  // interpret a multi-range request as a different single-range request.
  final match = RegExp(r'^bytes=(\d*)-(\d*)$', caseSensitive: false)
      .firstMatch(header.trim());
  if (match == null) return const _RangeOutcome.full();

  final startText = match.group(1)!;
  final endText = match.group(2)!;
  if (startText.isEmpty && endText.isEmpty) {
    return const _RangeOutcome.full();
  }

  if (startText.isEmpty) {
    final suffixLength = int.tryParse(endText);
    if (suffixLength == null || suffixLength <= 0) {
      return const _RangeOutcome.full();
    }
    final start = suffixLength >= length ? 0 : length - suffixLength;
    return _RangeOutcome.partial(_ByteSpan(start, length - 1));
  }

  final start = int.tryParse(startText);
  if (start == null) return const _RangeOutcome.full();
  if (start >= length) return const _RangeOutcome.unsatisfiable();

  final requestedEnd = endText.isEmpty ? length - 1 : int.tryParse(endText);
  if (requestedEnd == null) return const _RangeOutcome.full();
  if (requestedEnd < start) return const _RangeOutcome.full();

  final end = requestedEnd >= length ? length - 1 : requestedEnd;
  return _RangeOutcome.partial(_ByteSpan(start, end));
}
