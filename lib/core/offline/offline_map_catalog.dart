import 'dart:convert';

import '../live_data/live_data_gateway_client.dart';
import '../live_data/live_data_models.dart';
import '../map/map_service.dart';
import 'archive_models.dart';

class OfflineMapPackage {
  const OfflineMapPackage({
    required this.id,
    required this.name,
    required this.providerId,
    required this.version,
    required this.uri,
    required this.sha256,
    required this.bytes,
    required this.region,
    this.license,
    this.attribution,
  });

  final String id;
  final String name;
  final String providerId;
  final String version;
  final Uri uri;
  final String sha256;
  final int bytes;
  final OfflineMapRegion region;
  final String? license;
  final String? attribution;

  OfflineArchiveSource source(String destinationPath) => OfflineArchiveSource(
        regionId: id,
        providerId: providerId,
        uri: uri,
        destinationPath: destinationPath,
        sha256: sha256,
        expectedBytes: bytes,
        license: license,
        attribution: attribution,
      );

  static OfflineMapPackage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final bounds = raw['bounds'];
    if (bounds is! Map) return null;

    final id = raw['id']?.toString().trim() ?? '';
    final name = raw['name']?.toString().trim() ?? '';
    final providerId = raw['providerId']?.toString().trim() ?? '';
    final version = raw['version']?.toString().trim() ?? '';
    final uri = Uri.tryParse(raw['uri']?.toString() ?? '');
    final sha256 = raw['sha256']?.toString().trim() ?? '';
    final bytes = raw['bytes'] is num ? (raw['bytes'] as num).toInt() : 0;

    final west = _number(bounds['west']);
    final south = _number(bounds['south']);
    final east = _number(bounds['east']);
    final north = _number(bounds['north']);
    final minZoom = _int(raw['minZoom']);
    final maxZoom = _int(raw['maxZoom']);

    if (id.isEmpty ||
        name.isEmpty ||
        providerId.isEmpty ||
        version.isEmpty ||
        uri == null ||
        !uri.hasScheme ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256) ||
        bytes <= 0 ||
        west == null ||
        south == null ||
        east == null ||
        north == null) {
      return null;
    }

    final region = OfflineMapRegion(
      id: id,
      name: name,
      bounds: MapBounds(
        west: west,
        south: south,
        east: east,
        north: north,
      ),
      minZoom: minZoom,
      maxZoom: maxZoom,
      providerId: providerId,
      styleVersion: version,
    );
    if (!region.isValid) return null;

    return OfflineMapPackage(
      id: id,
      name: name,
      providerId: providerId,
      version: version,
      uri: uri,
      sha256: sha256,
      bytes: bytes,
      region: region,
      license: raw['license']?.toString(),
      attribution: raw['attribution']?.toString(),
    );
  }

  static double? _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value');

  static int _int(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

abstract interface class OfflineMapCatalogService {
  Future<LiveDataEnvelope<List<OfflineMapPackage>>> packages();
}

class GatewayOfflineMapCatalogService implements OfflineMapCatalogService {
  const GatewayOfflineMapCatalogService(this._gateway);

  final HttpLiveDataGateway _gateway;

  @override
  Future<LiveDataEnvelope<List<OfflineMapPackage>>> packages() async {
    final response = await _gateway.get<dynamic>('/v1/maps/catalog', const {});
    if (response.data is! List) {
      throw const LiveDataGatewayException('Catálogo offline inválido.');
    }

    final packages = (response.data as List)
        .map(OfflineMapPackage.fromJson)
        .whereType<OfflineMapPackage>()
        .toList(growable: false);

    return LiveDataEnvelope(
      data: packages,
      provenance: response.provenance,
    );
  }
}

/// Allows tests and future background workers to deserialize a cached
/// catalog without reimplementing the schema.
List<OfflineMapPackage> parseOfflineMapCatalog(String json) {
  final decoded = jsonDecode(json);
  if (decoded is! List) return const [];
  return decoded.map(OfflineMapPackage.fromJson).whereType<OfflineMapPackage>().toList();
}
