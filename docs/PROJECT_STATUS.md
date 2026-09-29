# España Outdoor — estado técnico

Última auditoría: 2026-09-29

## Objetivo MVP

Android primero. El criterio de aceptación principal es un APK instalable que abra el mapa sin cerrar la aplicación, renderice cartografía vectorial real y permita usar GPS, rutas y mapas offline.

## Auditoría ejecutada

- [x] Revisión de la arquitectura Flutter: `app/`, `core/`, `domain/`, `features/`, `infrastructure/`.
- [x] Revisión del proveedor cartográfico actual: Agus Maps / CoMaps.
- [x] Confirmado que las dependencias directas antiguas `flutter_map`, `flutter_map_vector_tiles` y `pmtiles` ya no están en `pubspec.yaml`.
- [x] Refuerzo del guard de CI para impedir que vuelvan imports de MapLibre/flutter_map/PMTiles al código Dart.
- [x] Revisión del runtime nativo `AgusMapsRuntime`.
- [x] Validación de `World.mwm` y `WorldCoasts.mwm` por tamaño + SHA-1 antes de registrarlos.
- [x] Validación de recursos críticos de CoMaps antes de `initWithPaths()`.
- [x] Limpieza de mapas parciales `.mwm.download` antes del registro.
- [x] Validación de mapas persistidos antes de registrarlos.
- [x] Impeller Android desactivado en la configuración nativa generada, por compatibilidad con el renderer de Agus Maps.
- [x] Smoke test Android real que navega a `Mapa` y comprueba que el proceso sigue vivo.
- [x] Smoke test preparado para conservar `logcat` y jerarquía UI como artifacts de diagnóstico.
- [x] Agus Maps actualizado de 0.1.17 a 0.1.18, que incorpora una corrección específica del orden de inicialización del viewport.
- [x] SDK 0.1.18 fijado por SHA-256 en CI.
- [x] Redraw nativo explícito después del registro de mapas.

## Limpieza / no eliminar todavía

- `assets/backgrounds/`: conservar hasta completar la búsqueda de referencias en todas las features; no se elimina por suposición.
- `lib/app/outdoor_visuals.dart`: conservar porque todavía proporciona héroes/iconos SVG en varias pantallas.
- `LICENSE` y `LICENSE.md`: no son duplicados byte a byte; contienen versiones/idiomas distintos de la licencia propietaria.
- Infraestructura PMTiles/R2: conservar. Es la fuente de cartografía vectorial distribuida y no debe confundirse con el renderer Android.
- `services/source-gateway` y `services/rescue-link`: conservar; son servicios de producto activos.

## Pendiente crítico

1. **CI Android staging con Agus Maps 0.1.18**.
2. **Smoke test Mapa PASS** sin crash nativo.
3. APK staging nuevo y prueba física en móvil.
4. Verificar cartografía detallada: carreteras, caminos, ciudades, pueblos, hidrografía y etiquetas.
5. Verificar descarga/preparación de regiones offline.
6. Verificar integridad SHA-256 del paquete offline.
7. Verificar rutas con Valhalla.
8. Verificar navegación GPS y grabación de rutas.
9. Auditoría final de assets no referenciados cuando el índice de búsqueda de código esté disponible.
10. Release candidate Android.

## Criterio de cierre del incidente del mapa

No se considera resuelto porque el APK compile. El incidente queda cerrado únicamente cuando el smoke test abre `Mapa`, el proceso Android permanece vivo y el APK resultante se instala y se comprueba físicamente sin cierre de la aplicación.
