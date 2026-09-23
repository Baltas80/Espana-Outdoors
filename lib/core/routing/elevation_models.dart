/// Provider-neutral elevation contracts.
library;

import 'routing_models.dart';

class ElevationSample {
  const ElevationSample({required this.meters});

  final double? meters;
}

enum ElevationQuality { measured, estimated, unavailable }

class ElevationProfile {
  const ElevationProfile({
    required this.samples,
    required this.quality,
    required this.providerId,
    required this.sourceTimestamp,
  });

  final List<ElevationSample> samples;
  final ElevationQuality quality;
  final String providerId;
  final DateTime sourceTimestamp;

  bool get isUsable =>
      samples.isNotEmpty && samples.any((sample) => sample.meters != null);
}

abstract interface class ElevationService {
  String get providerId;

  Future<ElevationProfile> profile(List<RouteWaypoint> points);
}
