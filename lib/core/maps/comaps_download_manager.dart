import 'dart:convert';
import 'dart:io';

import 'package:agus_maps_flutter/agus_maps_flutter.dart' as agus;
import 'package:agus_maps_flutter/mirror_service.dart';
import 'package:crypto/crypto.dart';

import 'agus_maps_runtime.dart';

final class CoMapsSpainPlan {
  const CoMapsSpainPlan({
    required this.mirror,
    required this.snapshot,
    required this.region,
  });

  final Mirror mirror;
  final Snapshot snapshot;
  final MwmRegion region;

  List<MwmRegion> get leaves => _leafRegions(region);
  int get totalBytes => leaves.fold<int>(
        0,
        (sum, item) => sum + item.sizeBytes,
      );
  String get label => region.displayName;

  static List<MwmRegion> _leafRegions(MwmRegion root) {
    final children = root.subregions;
    if (children == null || children.isEmpty) {
      return [root];
    }

    return [
      for (final child in children) ..._leafRegions(child),
    ];
  }
}

final class CoMapsDownloadManager {
  CoMapsDownloadManager._();
  static final CoMapsDownloadManager instance = CoMapsDownloadManager._();

  final MirrorService _mirrors = MirrorService();
  final Set<String> _cancelled = <String>{};

  Future<CoMapsSpainPlan> resolveSpain() async {
    await _mirrors.measureLatencies();
    final selected = _mirrors.getFastestMirror();

    if (selected == null) {
      throw StateError('No hay ningún servidor CoMaps disponible.');
    }

    final snapshots = await _mirrors.getSnapshots(selected);
    if (snapshots.isEmpty) {
      throw StateError('No se encontró un catálogo CoMaps reciente.');
    }

    final snapshot = snapshots.first;
    final regions = await _mirrors.getRegions(selected, snapshot);

    MwmRegion? spain;
    for (final region in regions) {
      if (region.id == 'Spain' ||
          region.id.toLowerCase().contains('spain')) {
        spain = region;
        break;
      }
    }

    if (spain == null) {
      throw StateError('El catálogo CoMaps no contiene España.');
    }

    return CoMapsSpainPlan(
      mirror: selected,
      snapshot: snapshot,
      region: spain,
    );
  }

  Future<void> downloadSpain({
    required void Function(
      MwmRegion region,
      int received,
      int total,
      int completed,
      int count,
    ) onProgress,
  }) async {
    await AgusMapsRuntime.instance.ensureInitialized();

    final plan = await resolveSpain();
    final leaves = plan.leaves;
    if (leaves.isEmpty) {
      throw StateError('España no contiene mapas descargables.');
    }

    var completed = 0;
    for (final region in leaves) {
      if (_cancelled.contains(region.id)) {
        _cancelled.remove(region.id);
        throw StateError('Descarga cancelada: ' + region.displayName);
      }

      await _downloadRegion(
        plan: plan,
        region: region,
        onProgress: (received, total) {
          onProgress(region, received, total, completed, leaves.length);
        },
      );
      completed++;
      onProgress(
        region,
        region.sizeBytes,
        region.sizeBytes,
        completed,
        leaves.length,
      );
    }
  }

  void cancelRegion(String regionId) => _cancelled.add(regionId);

  Future<void> _downloadRegion({
    required CoMapsSpainPlan plan,
    required MwmRegion region,
    required void Function(int received, int total) onProgress,
  }) async {
    final runtime = AgusMapsRuntime.instance;
    final dataPath = runtime.dataPath;

    if (dataPath == null) {
      throw StateError('El directorio de datos de CoMaps no está disponible.');
    }

    final versionDir = Directory(dataPath + '/' + plan.snapshot.version);
    await versionDir.create(recursive: true);

    final finalFile = File(versionDir.path + '/' + region.fileName);
    final tempFile = File(finalFile.path + '.download');

    if (await finalFile.exists() &&
        (region.sizeBytes == 0 ||
            await finalFile.length() == region.sizeBytes)) {
      await _recordAndRegister(
        plan: plan,
        region: region,
        file: finalFile,
      );
      return;
    }

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    _cancelled.remove(region.id);

    final url = _mirrors.getDownloadUrl(
      plan.mirror,
      plan.snapshot,
      region,
    );

    final received = await _mirrors.downloadToFile(
      url,
      tempFile,
      onProgress: onProgress,
    );

    if (region.sizeBytes > 0 && received != region.sizeBytes) {
      await _discardPartial(tempFile);
      throw StateError('Tamaño inesperado para ' + region.displayName + '.');
    }

    // CoMaps publishes SHA-1 in its region catalog. Keep that upstream check,
    // then calculate and persist our own SHA-256 fingerprint before the file
    // can be promoted from .download to a usable MWM.
    if (region.sha1Base64 != null) {
      final actual = await _sha1Base64(tempFile);
      if (actual != region.sha1Base64) {
        await _discardPartial(tempFile);
        throw StateError(
          'La verificación SHA-1 de ' + region.displayName + ' ha fallado.',
        );
      }
    }

    final sha256 = await _sha256Hex(tempFile);
    if (sha256.length != 64) {
      await _discardPartial(tempFile);
      throw StateError(
        'No se pudo calcular un SHA-256 válido para ${region.displayName}.',
      );
    }

    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    await tempFile.rename(finalFile.path);

    await _recordAndRegister(
      plan: plan,
      region: region,
      file: finalFile,
      sha256: sha256,
    );
  }

  Future<void> _recordAndRegister({
    required CoMapsSpainPlan plan,
    required MwmRegion region,
    required File file,
    String? sha256,
  }) async {
    final runtime = AgusMapsRuntime.instance;
    final computedSha256 = sha256 ?? await _sha256Hex(file);

    await runtime.storage?.upsert(
      agus.MwmMetadata(
        regionName: region.id,
        snapshotVersion: plan.snapshot.version,
        fileSize: await file.length(),
        downloadDate: DateTime.now(),
        filePath: file.path,
        sha256: computedSha256,
        isBundled: false,
      ),
    );

    await runtime.registerDownloadedMap(
      filePath: file.path,
      version: int.parse(plan.snapshot.version),
    );
  }

  Future<void> _discardPartial(File file) async {
    try {
      await file.delete();
    } catch (_) {}
  }

  Future<String> _sha1Base64(File file) async {
    final digest = await sha1.bind(file.openRead()).first;
    return base64Encode(digest.bytes);
  }

  Future<String> _sha256Hex(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase();
  }

  void dispose() => _mirrors.dispose();
}
