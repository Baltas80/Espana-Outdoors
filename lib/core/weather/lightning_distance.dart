class LightningDistance {
  const LightningDistance({required this.seconds, required this.distanceKm, required this.distanceMeters});

  final double seconds;
  final double distanceKm;
  final double distanceMeters;

  /// Estimates distance from lightning using the delay between flash and thunder.
  /// Uses 343 m/s at approximately 20 C. This is an outdoor estimate only.
  factory LightningDistance.fromThunderDelay(double seconds) {
    final safeSeconds = seconds < 0 ? 0.0 : seconds;
    final meters = safeSeconds * 343.0;
    return LightningDistance(seconds: safeSeconds, distanceKm: meters / 1000.0, distanceMeters: meters);
  }
}
