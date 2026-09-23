import 'package:latlong2/latlong.dart';

/// Provider-neutral map contract. Implementations may use MapLibre, flutter_map,
/// PMTiles, MBTiles or another mature provider without leaking it into features.
abstract interface class MapService {
  Future<void> openRegion(String regionId);
  Future<void> closeRegion(String regionId);
  Future<bool> isRegionAvailableOffline(String regionId);
  Future<void> removeRegion(String regionId);
  Stream<double> downloadRegion(String regionId);
  Future<void> pauseRegionDownload(String regionId);
  Future<void> resumeRegionDownload(String regionId);
  Future<String?> attributionFor(LatLng point);
}
