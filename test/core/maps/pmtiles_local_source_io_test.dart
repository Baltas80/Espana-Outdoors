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
    await archive.writeAsBytes(Uint8List.fromList(List<int>.generate(10, (i) => i)));
    localUrl = await serveLocalPmTiles(archive.path);
  });

  tearDown(() async {
    await closeLocalPmTilesServer();
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  Future<HttpClientResponse> getResponse({String? range, String method = 'GET'}) async {
    final client = HttpClient();
    final request = await (method == 'HEAD'
        ? client.headUrl(Uri.parse(localUrl))
        : client.getUrl(Uri.parse(localUrl)));
    if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
    final response = await request.close();
    // Consume the body before closing the client; the tests need the response
    // stream, so the caller owns disposal by reading it.
    return _ClientOwnedResponse(response, client).response;
  }

  test('returns 206 and exact bytes for a valid range', () async {
    final response = await getResponse(range: 'bytes=2-5');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes 2-5/10');
    expect(response.contentLength, 4);
    expect(await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b)), [2, 3, 4, 5]);
  });

  test('returns 416 with unsatisfied Content-Range beyond EOF', () async {
    final response = await getResponse(range: 'bytes=10-10');
    expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes */10');
    expect(response.contentLength, 0);
    await response.drain<void>();
  });

  test('ignores malformed range rather than mislabelling a full body as partial', () async {
    final response = await getResponse(range: 'bytes=abc');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), isNull);
    expect(await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b)), List<int>.generate(10, (i) => i));
  });

  test('ignores unsupported multi-range instead of silently serving first range', () async {
    final response = await getResponse(range: 'bytes=0-1,4-5');
    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), isNull);
    expect(await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b)), List<int>.generate(10, (i) => i));
  });

  test('supports suffix range and clamps suffix larger than the file', () async {
    final response = await getResponse(range: 'bytes=-3');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes 7-9/10');
    expect(await response.fold<List<int>>(<int>[], (a, b) => a..addAll(b)), [7, 8, 9]);

    final all = await getResponse(range: 'bytes=-30');
    expect(all.statusCode, HttpStatus.partialContent);
    expect(all.headers.value(HttpHeaders.contentRangeHeader), 'bytes 0-9/10');
    expect(await all.fold<List<int>>(<int>[], (a, b) => a..addAll(b)), List<int>.generate(10, (i) => i));
  });

  test('HEAD with range returns headers without a response body', () async {
    final response = await getResponse(range: 'bytes=0-2', method: 'HEAD');
    expect(response.statusCode, HttpStatus.partialContent);
    expect(response.headers.value(HttpHeaders.contentRangeHeader), 'bytes 0-2/10');
    expect(response.contentLength, 3);
    expect(await response.drain<void>(), isNull);
  });
}

// Keep each HttpClient alive until the response body is consumed. HttpClient is
// process-local test infrastructure and is closed when the wrapper is disposed.
class _ClientOwnedResponse {
  _ClientOwnedResponse(this.response, this.client);
  final HttpClientResponse response;
  final HttpClient client;
}
