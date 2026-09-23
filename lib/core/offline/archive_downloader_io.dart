import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'archive_models.dart';

class PlatformOfflineArchiveDownloader implements OfflineArchiveDownloader {
  PlatformOfflineArchiveDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;
  final Map<String, CancelToken> _cancelTokens = {};

  @override
  Stream<OfflineArchiveProgress> download(OfflineArchiveSource source) async* {
    final destination = File(source.destinationPath);
    await destination.parent.create(recursive: true);

    final partial = File('${source.destinationPath}.part');
    var existingBytes = await partial.exists() ? await partial.length() : 0;

    if (source.expectedBytes != null &&
        existingBytes == source.expectedBytes &&
        await _matchesSha256(partial, source.sha256)) {
      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);
      yield OfflineArchiveProgress(
        completedBytes: existingBytes,
        totalBytes: source.expectedBytes,
      );
      return;
    }

    final cancelToken = CancelToken();
    _cancelTokens[source.regionId] = cancelToken;

    try {
      final response = await _dio.get<ResponseBody>(
        source.uri.toString(),
        cancelToken: cancelToken,
        options: Options(
          responseType: ResponseType.stream,
          headers:
              existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      final resumed = existingBytes > 0 && response.statusCode == 206;
      if (!resumed) {
        existingBytes = 0;
        if (await partial.exists()) await partial.delete();
      }

      final contentLength = int.tryParse(
        response.headers.value(Headers.contentLengthHeader) ?? '',
      );
      final contentRange = response.headers.value('content-range');
      final totalFromRange = contentRange == null
          ? null
          : int.tryParse(contentRange.split('/').last.trim());
      final totalBytes = source.expectedBytes ??
          totalFromRange ??
          (contentLength == null ? null : existingBytes + contentLength);

      final sink = partial.openWrite(
        mode: resumed ? FileMode.append : FileMode.write,
      );
      var completedBytes = existingBytes;
      yield OfflineArchiveProgress(
        completedBytes: completedBytes,
        totalBytes: totalBytes,
      );

      try {
        await for (final chunk in response.data!.stream) {
          sink.add(chunk);
          completedBytes += chunk.length;
          yield OfflineArchiveProgress(
            completedBytes: completedBytes,
            totalBytes: totalBytes,
          );
        }
        await sink.flush();
        await sink.close();
      } catch (_) {
        await sink.close();
        rethrow;
      }

      final digest = await _sha256(partial);
      if (digest != source.sha256.toLowerCase()) {
        await partial.delete();
        throw StateError(
          'La integridad SHA-256 del archivo offline no coincide.',
        );
      }

      if (await destination.exists()) await destination.delete();
      await partial.rename(destination.path);
      yield OfflineArchiveProgress(
        completedBytes: completedBytes,
        totalBytes: totalBytes,
      );
    } finally {
      _cancelTokens.remove(source.regionId);
    }
  }

  @override
  Future<bool> verify(OfflineArchiveSource source) async {
    final file = File(source.destinationPath);
    if (!await file.exists()) return false;
    return _matchesSha256(file, source.sha256);
  }

  @override
  Future<void> cancel(String regionId) async {
    _cancelTokens.remove(regionId)?.cancel();
  }

  @override
  Future<void> delete(OfflineArchiveSource source) async {
    await cancel(source.regionId);
    for (final path in <String>[
      source.destinationPath,
      '${source.destinationPath}.part',
    ]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }

  Future<bool> _matchesSha256(File file, String expected) async {
    try {
      return await _sha256(file) == expected.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  Future<String> _sha256(File file) async {
    final sink = _DigestSink();
    final input = sha256.startChunkedConversion(sink);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return sink.value.toString().toLowerCase();
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest event) {
    value = event;
  }

  @override
  void close() {}
}