import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'archive_models.dart';

class PlatformOfflineArchiveDownloader implements OfflineArchiveDownloader {
  PlatformOfflineArchiveDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  @override
  Stream<OfflineArchiveProgress> download(OfflineArchiveSource source) async* {
    final destination = File(source.destinationPath);
    await destination.parent.create(recursive: true);

    final partial = File('${source.destinationPath}.part');
    var existingBytes = await partial.exists() ? await partial.length() : 0;

    final response = await _dio.get<ResponseBody>(
      source.uri.toString(),
      options: Options(
        responseType: ResponseType.stream,
        headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
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
    final contentRange = response.headers.value(Headers.contentRangeHeader);
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
  }

  @override
  Future<bool> verify(OfflineArchiveSource source) async {
    final file = File(source.destinationPath);
    if (!await file.exists()) return false;
    final digest = await _sha256(file);
    return digest == source.sha256.toLowerCase();
  }

  Future<String> _sha256(File file) async {
    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);
    await for (final chunk in file.openRead()) {
      input.add(chunk);
    }
    input.close();
    return output.events.single.toString().toLowerCase();
  }
}
