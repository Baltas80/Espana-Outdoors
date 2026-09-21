/// Offline-first capabilities and cache priorities.
library;

enum OfflineAssetPriority { critical, recommended, optional }

class OfflineAsset {
  const OfflineAsset({
    required this.id,
    required this.label,
    required this.priority,
    required this.estimatedBytes,
  });

  final String id;
  final String label;
  final OfflineAssetPriority priority;
  final int estimatedBytes;
}

const offlineCriticalAssets = <OfflineAsset>[
  OfflineAsset(
    id: 'base-map',
    label: 'Mapa base de la zona seleccionada',
    priority: OfflineAssetPriority.critical,
    estimatedBytes: 0,
  ),
  OfflineAsset(
    id: 'route',
    label: 'Ruta y navegación básica',
    priority: OfflineAssetPriority.critical,
    estimatedBytes: 0,
  ),
  OfflineAsset(
    id: 'safety',
    label: 'Información de seguridad y emergencia',
    priority: OfflineAssetPriority.critical,
    estimatedBytes: 0,
  ),
  OfflineAsset(
    id: 'contacts',
    label: 'Contactos de confianza',
    priority: OfflineAssetPriority.critical,
    estimatedBytes: 0,
  ),
];

class OfflineDownloadPlan {
  const OfflineDownloadPlan({
    required this.name,
    required this.assets,
  });

  final String name;
  final List<OfflineAsset> assets;

  int get estimatedBytes => assets.fold(0, (sum, asset) => sum + asset.estimatedBytes);
}
