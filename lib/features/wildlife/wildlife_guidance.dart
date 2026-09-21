import '../../core/domain/outdoor_models.dart';

class WildlifeGuidanceCatalog {
  const WildlifeGuidanceCatalog();

  WildlifeEncounterGuidance forSpecies(String species) {
    final key = species.trim().toLowerCase();

    if (key.contains('jabal')) {
      return const WildlifeEncounterGuidance(
        species: 'Jabalí',
        actions: [
          'Mantén la distancia y evita bloquear su salida.',
          'Retira a la mascota y mantenla bajo control.',
          'Aléjate con calma si el animal muestra inquietud.',
        ],
        avoid: [
          'No te acerques para fotografiarlo.',
          'No alimentarlo ni perseguirlo.',
        ],
      );
    }

    if (key.contains('serp')) {
      return const WildlifeEncounterGuidance(
        species: 'Serpiente',
        actions: [
          'Detente y deja espacio al animal.',
          'Rodea la zona manteniendo distancia.',
          'Controla a la mascota para evitar una interacción.',
        ],
        avoid: [
          'No intentes tocarla, atraparla o identificarla de cerca.',
        ],
      );
    }

    return const WildlifeEncounterGuidance(
      species: 'Fauna silvestre',
      actions: [
        'Mantén distancia y deja una vía de escape.',
        'Mantén a la mascota bajo control.',
        'Aléjate tranquilamente si el animal se aproxima.',
      ],
      avoid: [
        'No tocar, alimentar, perseguir ni acosar al animal.',
      ],
    );
  }
}
