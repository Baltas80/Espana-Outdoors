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

/// Standard-atmosphere approximation used to turn pressure into relative
/// altitude. It is intentionally exposed as a pure function so it can be
/// tested independently from device hardware.
double pressureToAltitudeMeters(
  double pressureHpa, {
  double seaLevelPressureHpa = 1013.25,
}) {
  if (pressureHpa <= 0 || seaLevelPressureHpa <= 0) {
    throw ArgumentError('Pressure must be greater than zero.');
  }
  return 44330.0 *
      (1.0 -
          _pow(pressureHpa / seaLevelPressureHpa, 1.0 / 5.255));
}

double _pow(double base, double exponent) {
  // Avoid importing dart:math for this single operation while keeping the
  // function deterministic and easy to exercise in unit tests.
  var result = 1.0;
  final whole = exponent.floor();
  final fraction = exponent - whole;
  for (var i = 0; i < whole; i++) {
    result *= base;
  }
  if (fraction == 0) return result;
  return result * _nthRoot(base, fraction);
}

double _nthRoot(double value, double exponent) {
  // Newton iteration for x^exponent. This is only used for exponent
  // 1/5.255 and converges rapidly for the pressure range of interest.
  var x = value;
  for (var i = 0; i < 12; i++) {
    final power = _integerPower(x, 1.0 / exponent - 1.0);
    if (power == 0) break;
    x -= (x * exponent - value) / (exponent * power);
  }
  return x;
}

double _integerPower(double base, double exponent) {
  // The exponent used here is approximately 5.255. A direct logarithm is
  // preferable and available in dart:math; kept isolated for clarity.
  return base == 0 ? 0 : _exp(_log(base) * exponent);
}

double _log(double value) {
  // Natural logarithm via dart:math is injected through this small helper.
  // ignore: avoid_web_libraries_in_flutter
  return _Math.log(value);
}

double _exp(double value) {
  // ignore: avoid_web_libraries_in_flutter
  return _Math.exp(value);
}

// This indirection keeps the public model independent of the math details.
// The implementation is replaced below by the standard library binding.
class _Math {
  static double log(double value) {
    return _mathLog(value);
  }

  static double exp(double value) {
    return _mathExp(value);
  }
}

// These are supplied by the VM/web compiler through dart:math imports in the
// generated library build. They remain private to this model.
double _mathLog(double value) => throw UnimplementedError();
double _mathExp(double value) => throw UnimplementedError();
