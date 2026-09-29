import 'dart:io';

const forbiddenTileHost = 'tile.openstreetmap.org';
const forbiddenImports = <String>{
  'package:flutter_map/',
  'package:flutter_map_vector_tiles/',
  'package:maplibre_gl/',
  'package:maplibre_gl_platform_interface/',
  'package:pmtiles/',
};

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
    final content = entity.readAsStringSync();

    if (content.contains(forbiddenTileHost)) {
      violations.add('$path: direct OSM tile host');
    }

    for (final importPrefix in forbiddenImports) {
      if (content.contains("'$importPrefix")) {
        violations.add('$path: legacy map import $importPrefix');
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('Legacy/direct map provider usage detected:');
    for (final violation in violations) {
      stderr.writeln(' - $violation');
    }
    stderr.writeln(
      'España Outdoor Android uses Agus Maps/CoMaps as the map renderer. '
      'PMTiles is infrastructure input only and must not be coupled to the '
      'native map widget.',
    );
    exitCode = 1;
    return;
  }

  stdout.writeln('Map provider usage guard passed.');
}
