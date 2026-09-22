import 'dart:io';

const forbiddenTileHost = 'tile.openstreetmap.org';
const allowedConfigPath = 'lib/features/map/map_provider_config.dart';

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
    if (path == allowedConfigPath) continue;

    final content = entity.readAsStringSync();
    if (content.contains(forbiddenTileHost)) {
      violations.add(path);
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln(
      'Direct public OSM tile-server usage detected outside the provider '
      'configuration: ${violations.join(', ')}',
    );
    stderr.writeln(
      'Use MapProviderConfig/MapService instead. Public OSM tiles must not '
      'be used for bulk downloads or offline prefetching.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Map provider usage guard passed.');
}
