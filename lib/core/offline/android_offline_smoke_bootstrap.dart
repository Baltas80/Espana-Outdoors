import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../map/map_service.dart';
import 'offline_region_store.dart';

const _enabled = bool.fromEnvironment(
  'ANDROID_OFFLINE_SMOKE',
  defaultValue: false,
);

Future<void> prepareAndroidOfflineSmoke() async {
  if (!_enabled) return;

  const assetPath = 'assets/testing/offline_smoke.pmtiles';
  final data = await rootBundle.load(assetPath);
  final bytes = data.buffer.asUint8List(
    data.offsetInBytes,
    data.lengthInBytes,
  );
  if (bytes.isEmpty) {
    throw StateError('Android offline smoke fixture is empty.');
  }

  final digest = sha256.convert(bytes).toString();
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/offline_regions');
  await directory.create(recursive: true);

  final file = File('${directory.path}/spain-$digest.pmtiles');
  await file.writeAsBytes(bytes, flush: true);

  const region = OfflineMapRegion(
    id: 'spain',
    name: 'Spain offline smoke',
    bounds: MapBounds(
      west: -180,
      south: -85,
      east: 180,
      north: 85,
    ),
    minZoom: 0,
    maxZoom: 0,
    providerId: 'approved-pmtiles-catalog',
    styleVersion: '1',
  );

  await OfflineRegionStore().put(
    OfflineRegionRecord(
      region: region,
      status: OfflineRegionStatus.ready,
      bytesDownloaded: bytes.length,
      bytesTotal: bytes.length,
      localPath: file.path,
      sha256: digest,
      artifactVersion: 'android-offline-smoke-v1',
      updatedAt: DateTime.now().toUtc(),
    ),
  );
}
