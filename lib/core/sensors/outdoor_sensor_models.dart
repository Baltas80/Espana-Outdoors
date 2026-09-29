import 'dart:math' as math;

class OutdoorSensorState {
  const OutdoorSensorState({
    this.heading,
    this.headingAccuracy,
    this.pressureHpa,
    this.sensorAltitudeMeters,
    this.gpsAltitudeMeters,
    this.lastUpdated,
    this.compassAvailable = false,
    this.barometerAvailable = false,
    this.error,
  });

  final double? heading;
  final double? headingAccuracy;
  final double? pressureHpa;
  final double? sensorAltitudeMeters;
  final double? gpsAltitudeMeters;
  final DateTime? lastUpdated;
  final bool compassAvailable;
  final bool barometerAvailable;
  final String? error;

  bool get hasCompass => heading != null;
  bool get hasPressure => pressureHpa != null;

  OutdoorSensorState copyWith({
    Object? heading = _unset,
    Object? headingAccuracy = _unset,
    Object? pressureHpa = _unset,
    Object? sensorAltitudeMeters = _unset,
    Object? gpsAltitudeMeters = _unset,
    Object? lastUpdated = _unset,
    bool? compassAvailable,
    bool? barometerAvailable,
    Object? error = _unset,
  }) {
    return OutdoorSensorState(
      heading: identical(heading, _unset) ? this.heading : heading as double?,
      headingAccuracy: identical(headingAccuracy, _unset)
          ? this.headingAccuracy
          : headingAccuracy as double?,
      pressureHpa: identical(pressureHpa, _unset)
          ? this.pressureHpa
          : pressureHpa as double?,
      sensorAltitudeMeters: identical(sensorAltitudeMeters, _unset)
          ? this.sensorAltitudeMeters
          : sensorAltitudeMeters as double?,
      gpsAltitudeMeters: identical(gpsAltitudeMeters, _unset)
          ? this.gpsAltitudeMeters
          : gpsAltitudeMeters as double?,
      lastUpdated: identical(lastUpdated, _unset)
          ? this.lastUpdated
          : lastUpdated as DateTime?,
      compassAvailable: compassAvailable ?? this.compassAvailable,
      barometerAvailable: barometerAvailable ?? this.barometerAvailable,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();
}

/// Standard-atmosphere approximation. For a useful field altitude reading,
/// sea-level pressure should ideally be calibrated from a trusted source.
double pressureToAltitudeMeters(
  double pressureHpa, {
  double seaLevelPressureHpa = 1013.25,
}) {
  if (pressureHpa <= 0 || seaLevelPressureHpa <= 0) {
    throw ArgumentError('Pressure must be greater than zero.');
  }
  return (44330.0 *
          (1.0 -
              math.pow(pressureHpa / seaLevelPressureHpa, 1.0 / 5.255)))
      .toDouble();
}
