import 'dart:io';

final directCredentialPatterns = <RegExp>[
  RegExp(r'\bAemetWeatherService\s*\('),
  RegExp(r'\bWeatherRuntimeConfig\s*\('),
  RegExp(r'api_key\s*[:=]'),
];

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
    final source = entity.readAsStringSync();

    for (final pattern in directCredentialPatterns) {
      if (pattern.hasMatch(source)) {
        violations.add(path + ': ' + pattern.pattern);
        break;
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Direct client-side credentialed live-provider usage detected:',
    );
    for (final violation in violations) {
      stderr.writeln(' - ' + violation);
    }
    stderr.writeln(
      'Features must consume SourceGateway/GatewayWeatherService. '
      'Provider credentials remain server-side.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln(
    'Live data provider usage guard passed: gateway-only client boundary.',
  );
}
