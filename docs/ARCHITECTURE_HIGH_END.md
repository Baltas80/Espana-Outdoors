# España Outdoor — arquitectura móvil de alta gama

## 1. Renderer Android

Android usa exclusivamente `agus_maps_flutter 0.1.18` + CoMaps/MWM.

No se permite introducir en el camino Android MapLibre, flutter_map, flutter_map_vector_tiles ni PMTiles como fuente/renderizador del mapa Android.

La infraestructura PMTiles/R2 existente queda aislada como legado/web hasta su retirada formal. No participa en el renderer Android.

## 2. Lifecycle de Agus Maps

Orden obligatorio:

1. Crear almacenamiento MWM.
2. Extraer/validar `comaps_data`.
3. Limpiar transferencias parciales.
4. Validar mapas persistidos.
5. Extraer/validar `World.mwm` y `WorldCoasts.mwm`.
6. Ejecutar `agus.initWithPaths(dataPath, dataPath)` una sola vez.
7. Crear `AgusMap`.
8. Esperar `onMapReady`.
9. Registrar mapas MWM.
10. Ejecutar `invalidateMap()` / `forceRedraw()`.

No se debe cambiar el viewport inicial durante la creación de la superficie nativa.

La aplicación no debe invocar funciones nativas después de desmontar el widget. La liberación de la superficie queda bajo el lifecycle del plugin.

## 3. Integridad offline

Un MWM descargado sigue esta máquina de estados:

`NO_EXISTE -> .download -> SIZE_OK -> SHA1_UPSTREAM_OK -> SHA256_CALCULADO -> RENOMBRADO -> METADATA -> REGISTRADO`

Un archivo `.download` nunca se considera disponible.

Antes de registrarlo se comprueba tamaño, se valida SHA-1 frente al catálogo CoMaps, se calcula SHA-256 completo, se almacena el SHA-256 junto con la metadata y en arranques posteriores se vuelve a calcular y comparar. Si no coincide, el MWM se elimina y debe recuperarse.

### Próximo endurecimiento

El catálogo propio de producción debe incorporar un SHA-256 esperado por versión/archivo. Hasta disponer de ese manifiesto firmado, CoMaps SHA-1 + SHA-256 local constituye una doble comprobación de transporte/persistencia, pero no debe describirse como una cadena de confianza SHA-256 externa completa.

## 4. Foreground tracking

La grabación Android usa `geolocator 14` con foreground notification, wake lock y `setOngoing=true`. La aplicación persiste cada punto para recuperar una sesión si el proceso se interrumpe.

No se afirma que Android permita un proceso literalmente inmune a destrucción. Un foreground service reduce las restricciones de ejecución, pero el sistema/OEM puede finalizar procesos. El objetivo profesional es foreground service de ubicación, notificación persistente, permisos correctos, persistencia incremental, recuperación de sesión y pruebas Android 14/15/16.

Si el requisito final es sobrevivir también al swipe de recientes y reinicios del proceso Flutter, se debe migrar el tracking a un foreground service con engine dedicado, manteniendo la misma store de recuperación.

## 5. Caching predictivo

El motor MWM no utiliza tiles PMTiles. El caching predictivo se implementará sobre unidades MWM/regiones:

- analizar una ruta guardada o planificada;
- determinar regiones MWM intersectadas;
- añadir un corredor de 500 m alrededor de la ruta;
- priorizar región actual + siguiente región + margen;
- descargar silenciosamente solo con conectividad y batería adecuadas;
- validar integridad antes de activar cada región;
- no duplicar descargas ya presentes.

No se descargará automáticamente toda España cuando una ruta solo atraviese una pequeña zona.

## 6. Hillshading / elevación

No se debe simular hillshading con degradados visuales. La implementación profesional requiere una fuente DEM compatible y con licencia documentada, almacenamiento local por bloques, validación, cálculo local de normales/sombreado, caché por zoom/bloque, límites de resolución según dispositivo e integración mediante una API soportada por Agus Maps.

Si Agus Maps 0.1.18 no expone una capa de raster/overlay adecuada, no se debe forzar una integración nativa no soportada. Se mantiene como módulo desacoplado hasta disponer de un punto de integración estable.

## 7. Rendimiento

- Evitar polling de alta frecuencia.
- Evitar copias de MWM a RAM.
- No recalcular elevación mientras el mapa está estático.
- Invalidar cachés solo cuando cambie el bloque relevante.
- Mantener procesamiento pesado fuera del isolate de UI.
- Liberar streams y suscripciones al desmontar features.
- No usar imágenes gigantes cuando una resolución menor sea suficiente.

## 8. Gates de release Android

Un release candidate no puede avanzar si falla cualquiera de estos gates:

1. `flutter analyze`.
2. tests unitarios/widget.
3. guard contra renderer obsoleto.
4. validación nativa Agus Maps.
5. build APK.
6. instalación en dispositivo/emulador.
7. apertura de `Mapa` sin crash.
8. navegación fuera de `Mapa` y regreso sin crash.
9. registro de MWM sin error nativo.
10. validación offline.
11. GPS/foreground tracking.
