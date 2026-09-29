# España Outdoor — estado técnico

Última auditoría: 2026-09-30

## Objetivo MVP

Android primero. El criterio de aceptación principal es un APK instalable que abra el mapa sin cerrar la aplicación, renderice cartografía vectorial real y permita usar GPS, rutas y mapas offline.

## Arquitectura fijada

- Renderer Android: `agus_maps_flutter 0.1.18` + CoMaps/MWM.
- Flutter/Riverpod/go_router.
- PMTiles no forma parte del renderer Android.
- iOS queda fuera del MVP.
- Web/desktop quedan fuera del camino crítico del MVP.

## Auditoría ejecutada

- [x] Revisión de arquitectura Flutter: `app/`, `core/`, `domain/`, `features/`, `infrastructure/`.
- [x] Revisión del proveedor cartográfico actual: Agus Maps / CoMaps.
- [x] Confirmado que las dependencias directas antiguas `flutter_map`, `flutter_map_vector_tiles` y `pmtiles` ya no están en `pubspec.yaml`.
- [x] Guard de CI para impedir imports de MapLibre/flutter_map/PMTiles en Dart.
- [x] Revisión del lifecycle de `AgusMapsRuntime`.
- [x] Validación de `World.mwm` y `WorldCoasts.mwm` por tamaño + SHA-1 antes de registrarlos.
- [x] Validación de recursos críticos de CoMaps antes de `initWithPaths()`.
- [x] Limpieza de mapas parciales `.mwm.download`.
- [x] Validación de mapas persistidos por tamaño + SHA-256.
- [x] Descargas MWM: SHA-1 upstream + cálculo SHA-256 antes de promoción.
- [x] SHA-256 almacenado en `MwmMetadata` para revalidación en posteriores arranques.
- [x] Impeller Android desactivado en configuración nativa generada por compatibilidad con el renderer Agus Maps.
- [x] Smoke test Android que navega a `Mapa` y comprueba que el proceso sigue vivo.
- [x] Smoke test preparado para conservar `logcat` y jerarquía UI como artifacts.
- [x] Agus Maps fijado en 0.1.18.
- [x] SDK Agus Maps fijado por SHA-256 en CI.
- [x] Redraw nativo explícito después del registro de mapas.
- [x] Foreground notification GPS configurada como ongoing + wake lock.
- [x] Tests de Home/widget alineados con la UI actual, eliminando expectativas obsoletas.
- [x] Documento de arquitectura de alta gama creado en `docs/ARCHITECTURE_HIGH_END.md`.

## Problemas detectados que siguen abiertos

### P0 — Crash al abrir Mapa

El código ya contiene defensas de lifecycle, pero el cierre físico de la aplicación no se considera resuelto hasta que el smoke test Android ejecute realmente `Mapa` y capture un resultado PASS. La última ejecución que falló no llegó al smoke test porque el análisis/tests fallaron antes.

### P0 — Cartografía detallada

`World.mwm` + `WorldCoasts.mwm` son mapas base. Para mostrar el nivel de detalle esperado de España hay que disponer y registrar los MWM regionales de España. No se debe confundir que el renderer funcione con que exista cobertura regional detallada.

### P1 — SHA-256 de confianza externa

El catálogo CoMaps expone SHA-1. La app ya calcula y persiste SHA-256, pero el cierre definitivo del requisito de alta seguridad exige un manifiesto propio de producción con SHA-256 esperado por versión/archivo, preferiblemente firmado.

### P1 — Foreground service resiliente

`geolocator` proporciona foreground service y notificación persistente. Para sobrevivir al cierre explícito de la app/proceso y escenarios OEM extremos, el diseño objetivo es un service con engine dedicado y recuperación persistente.

### P1 — Caching predictivo 500 m

Pendiente integrar con el planificador de rutas y convertir el corredor de 500 m en una selección de regiones MWM a descargar de forma preventiva.

### P2 — Hillshading

Pendiente fuente DEM + pipeline local + integración soportada por Agus Maps. No se implementará un falso sombreado visual.

## Limpieza / conservación

- `assets/backgrounds/`: conservar hasta completar búsqueda de referencias; no borrar por suposición.
- `lib/app/outdoor_visuals.dart`: conservar mientras existan features que dependan de sus SVG.
- `LICENSE` y `LICENSE.md`: no eliminar sin revisar diferencias legales/licencia.
- PMTiles/R2: aislar del Android MVP y tratar como legado/web hasta su retirada formal; no debe entrar en la cadena de renderizado Android.
- `services/source-gateway` y `services/rescue-link`: conservar; forman parte de la arquitectura de producto.

## Lista de tareas

### Terminadas

- Auditoría inicial y clasificación de arquitectura.
- Limpieza de dependencias cartográficas antiguas.
- Protección CI contra regresión del renderer.
- Correcciones de lifecycle Agus Maps.
- Validación de CoMaps data/assets.
- Integridad MWM base.
- Integridad SHA-256 de MWM descargados/persistidos.
- Foreground notification GPS persistente.
- Smoke test de navegación al mapa.
- Corrección de tests obsoletos de UI.
- Sistema visual premium con fotografía propia.

### Pendientes — orden de ejecución

1. **PASS Android staging + `Mapa` smoke test.**
2. **Capturar/analizar logcat nativo si vuelve a caer.**
3. **Nuevo APK staging.**
4. **Prueba física del APK en móvil.**
5. **Registrar MWM regional de España y comprobar carreteras, caminos, pueblos, ciudades, ríos, lagos y etiquetas.**
6. **Manifiesto SHA-256 de producción.**
7. **Recuperación automática de descarga corrupta.**
8. **Foreground service con engine dedicado para resiliencia extrema.**
9. **Caching predictivo de corredor 500 m.**
10. **DEM/hillshading profesional.**
11. **Valhalla y navegación.**
12. **QA Android 14/15/16 + dispositivos OEM.**
13. **Auditoría final de assets no utilizados.**
14. **Release candidate Android.**

## Criterio de cierre del incidente del mapa

No se considera resuelto porque compile. El incidente queda cerrado únicamente cuando el smoke test abre `Mapa`, el proceso Android permanece vivo, el renderer registra MWM sin error nativo y el APK resultante se instala y se comprueba físicamente sin cierre de la aplicación.
