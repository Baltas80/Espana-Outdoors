import 'dart:io';
import 'dart:typed_data';

import 'package:espana_outdoors/core/maps/pmtiles_local_source_io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDirectory;
  late File archive;
  late String localUrl;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('pmtiles-range-');
    archive = File('${tempDirectory.path}/sample.pmtiles');
    await archive.writeAsBytes(
      Uint8List.fromList(List<int>.generate(10, (i) => i)),
    );
    localUrl = await serveLocalPmTiles(archive.path);
  });

  tearDown(() async {
    await closeLocalPmTilesServer();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<_ResponseData> request({String? range, String method = 'GET'}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse(localUrl);
      final req = await (method == 'HEAD'
          ? client.headUrl(uri)
          : client.getUrl(uri));
      if (range != null) req.headers.set(HttpHeaders.rangeHeader, range);
      final response = await req.close();
      final body = await response.fold<List<int>>(
        <int>[],
        (bytes, chunk) => bytes..addAll(chunk),
      );
      return _ResponseData(
        statusCode: response.statusCode,
        contentRange: response.headers.value(HttpHeaders.contentRangeHeader),
        contentLength: response.contentLength,
        body: body,
      );
    } finally {
      client.close(force: true);
    }
  }

  test('returns 206 and exact bytes for a valid range', () async {
    final response = await request(range: 'bytes=2-5');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.contentRange, 'bytes 2-5/10');
    expect(response.contentLength, 4);
    expect(response.body, [2, 3, 4, 5]);
  });

  test('returns 416 with unsatisfied Content-Range beyond EOF', () async {
    final response = await request(range: 'bytes=10-10');
    expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(response.contentRange, 'bytes */10');
    expect(response.contentLength, 0);
    expect(response.body, isEmpty);
  });

  test('ignores malformed range instead of mislabelling a full body as partial', () async {
    final response = await request(range: 'bytes=abc');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentRange, isNull);
    expect(response.body, List<int>.generate(10, (i) => i));
  });

  test('ignores unsupported multi-range instead of silently serving first range', () async {
    final response = await request(range: 'bytes=0-1,4-5');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.contentRange, isNull);
    expect(response.body, List<int>.generate(10, (i) => i));
  });

  test('supports suffix range and clamps suffix larger than the file', () async {
    final response = await request(range: 'bytes=-3');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.contentRange, 'bytes 7-9/10');
    expect(response.body, [7, 8, 9]);

    final all = await request(range: 'bytes=-30');
    expect(all.statusCode, HttpStatus.partialContent);
    expect(all.contentRange, 'bytes 0-9/10');
    expect(all.body, List<int>.generate(10, (i) => i));
  });

  test('HEAD with range returns headers without a response body', () async {
    final response = await request(range: 'bytes=0-2', method: 'HEAD');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.contentRange, 'bytes 0-2/10');
    expect(response.contentLength, 3);
    expect(response.body, isEmpty);
  });
}

class _ResponseData {
  const _ResponseData({
    required this.statusCode,
    required this.contentRange,
    required this.contentLength,
    required this.body,
  });

  final int statusCode;
  final String? contentRange;
  final int contentLength;
  final List<int> body;
}
