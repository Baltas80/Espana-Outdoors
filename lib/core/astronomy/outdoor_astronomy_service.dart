import 'dart:math' as math;

class SolarTimes {
  const SolarTimes({this.sunrise, this.sunset, this.solarNoon});
  final DateTime? sunrise;
  final DateTime? sunset;
  final DateTime? solarNoon;
  bool get polarNight => sunrise == null && sunset == null;
}

class SolarPosition {
  const SolarPosition({required this.azimuth, required this.elevation});
  final double azimuth;
  final double elevation;
}

class MoonPhase {
  const MoonPhase({required this.ageDays, required this.illumination, required this.name});
  final double ageDays;
  final double illumination;
  final String name;
}

/// Offline astronomical calculations for outdoor planning.
/// Values are approximate and are not intended for safety-critical navigation.
class OutdoorAstronomyService {
  static SolarTimes solarTimes({required DateTime date, required double latitude, required double longitude}) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final n = day.difference(DateTime.utc(date.year, 1, 1)).inDays + 1;
    final gamma = 2 * math.pi / 365 * (n - 1);
    final eqTime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma) - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma));
    final decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma) - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma) - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma);
    final lat = _degToRad(latitude.clamp(-89.9, 89.9));
    final zenith = _degToRad(90.833);
    final cosH = (math.cos(zenith) / (math.cos(lat) * math.cos(decl))) - math.tan(lat) * math.tan(decl);
    final solarNoonMinutes = 720 - 4 * longitude - eqTime;
    if (cosH > 1 || cosH < -1) return SolarTimes(solarNoon: _utcMinutes(day, solarNoonMinutes));
    final hourAngle = _radToDeg(math.acos(cosH));
    return SolarTimes(
      sunrise: _utcMinutes(day, solarNoonMinutes - hourAngle * 4),
      sunset: _utcMinutes(day, solarNoonMinutes + hourAngle * 4),
      solarNoon: _utcMinutes(day, solarNoonMinutes),
    );
  }

  static SolarPosition solarPosition({required DateTime time, required double latitude, required double longitude}) {
    final utc = time.toUtc();
    final n = utc.difference(DateTime.utc(utc.year, 1, 1)).inDays + 1;
    final minutes = utc.hour * 60 + utc.minute + utc.second / 60.0 + utc.millisecond / 60000.0;
    final gamma = 2 * math.pi / 365 * (n - 1 + (minutes - 720) / 1440);
    final eqTime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma) - 0.032077 * math.sin(gamma) - 0.014615 * math.cos(2 * gamma) - 0.040849 * math.sin(2 * gamma));
    final decl = 0.006918 - 0.399912 * math.cos(gamma) + 0.070257 * math.sin(gamma) - 0.006758 * math.cos(2 * gamma) + 0.000907 * math.sin(2 * gamma) - 0.002697 * math.cos(3 * gamma) + 0.00148 * math.sin(3 * gamma);
    final trueSolarMinutes = (minutes + eqTime + 4 * longitude) % 1440;
    final hourAngle = _degToRad(trueSolarMinutes / 4 - 180);
    final lat = _degToRad(latitude.clamp(-89.9, 89.9));
    final cosZenith = math.sin(lat) * math.sin(decl) + math.cos(lat) * math.cos(decl) * math.cos(hourAngle);
    final elevation = 90 - _radToDeg(math.acos(cosZenith.clamp(-1.0, 1.0)));
    var azimuth = _radToDeg(math.atan2(math.sin(hourAngle), math.cos(hourAngle) * math.sin(lat) - math.tan(decl) * math.cos(lat))) + 180;
    azimuth %= 360;
    return SolarPosition(azimuth: azimuth, elevation: elevation);
  }

  static MoonPhase moonPhase(DateTime date) {
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    final days = date.toUtc().difference(reference).inMinutes / 1440.0;
    final age = ((days % 29.530588853) + 29.530588853) % 29.530588853;
    final phase = age / 29.530588853;
    final illumination = (1 - math.cos(2 * math.pi * phase)) / 2;
    final name = switch (phase) {
      < 0.0625 || >= 0.9375 => 'Luna nueva',
      < 0.1875 => 'Creciente inicial',
      < 0.3125 => 'Cuarto creciente',
      < 0.4375 => 'Gibosa creciente',
      < 0.5625 => 'Luna llena',
      < 0.6875 => 'Gibosa menguante',
      < 0.8125 => 'Cuarto menguante',
      _ => 'Creciente final',
    };
    return MoonPhase(ageDays: age, illumination: illumination, name: name);
  }

  static DateTime _utcMinutes(DateTime day, double minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    return day.add(Duration(minutes: normalized.round()));
  }
  static double _degToRad(double value) => value * math.pi / 180;
  static double _radToDeg(double value) => value * 180 / math.pi;
}
