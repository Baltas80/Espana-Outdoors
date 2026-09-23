import 'dart:io';

const allowedFiles = <String>{
  'lib/core/weather/aemet_weather_service.dart',
};

final directAemetPattern = RegExp(r'\\bAemetWeatherService\\s*\\(');
final directRuntimeCredentialPattern = RegExp(
  r'WeatherRuntimeConfig\\s*\\([^)]*apiKey\\s*:',
  dotAll: true,
);

void main() {
  final violations = <String>[];
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('lib/ directory not found.');
    exitCode = 2;
    return;
  }

  for (final entity in lib.listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll('\\', '/');
    if (allowedFiles.contains(path)) continue;

    final content = entity.readAsStringSync();
    if (directAemetPattern.hasMatch(content) ||
        directRuntimeCredentialPattern.hasMatch(content)) {
      violations.add(path);
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Direct credentialed live-provider usage detected: ' +
          violations.join(', '),
    );
    stderr.writeln(
      'Features must consume SourceGateway/GatewayWeatherService. '
      'AEMET credentials remain server-side.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Live data provider usage guard passed.');
}
