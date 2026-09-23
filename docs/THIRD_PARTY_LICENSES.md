# ESPAÑA OUTDOOR — THIRD-PARTY SOFTWARE & LICENCE REGISTER

Estado: registro inicial; validar automáticamente y actualizar antes de cada release.

## Principio de aceptación

Una dependencia solo se incorpora a producción después de revisar licencia, mantenimiento, seguridad, soporte móvil, rendimiento, coste, lock-in, procedencia, obligaciones de atribución y compatibilidad con distribución propietaria.

## Dependencias actuales del MVP móvil

| Componente | Uso | Licencia/condición | Estado |
|---|---|---|---|
| Flutter / Dart | Aplicación móvil | Ecosistema Flutter | Aceptado; revisar notices |
| maplibre_gl 0.27.1 | Renderizado MapLibre Android/iOS | BSD-3-Clause | Aceptado |
| pmtiles 2.2.0 | Lectura PMTiles | BSD-2-Clause | Aceptado |
| latlong2 | Geometría/geodesia | Open source | Aceptado |
| Riverpod | Estado | Open source | Aceptado |
| go_router | Navegación | Open source | Aceptado |
| geolocator 14.0.3 | GPS/ubicación y background location | Open source | Aceptado; configuración nativa pendiente de release |
| connectivity_plus | Conectividad | Open source | Aceptado |
| shared_preferences | Preferencias no críticas | Open source | Aceptado |
| flutter_secure_storage | Secretos/credenciales locales | Open source | Aceptado |
| file_picker | Selección de archivos | Open source | Aceptado |
| path_provider | Rutas de almacenamiento | Open source | Aceptado |
| gpx | GPX | Open source | Aceptado |
| Hive CE | Persistencia local temporal | Open source | Mantener durante MVP; evaluar migración |
| url_launcher | Acciones del SO | Open source | Aceptado |
| http | Cliente HTTP | Dart | Aceptado |
| purchases_flutter / purchases_ui_flutter 10.13.1 | Billing/entitlements | RevenueCat; revisar términos comerciales | Aceptado |
| background_downloader 9.6.2 | Descarga de paquetes offline | BSD-3-Clause / MIT | Aceptado para móvil |
| openidconnect 3.0.0 | OIDC/OAuth 2.0 + PKCE | Apache-2.0 | Aceptado |
| sentry_flutter 9.30.1 | Crash/error telemetry | MIT | Aceptado |
| battery_plus 7.1.1 | Estado de batería | Open source | Adoptado para SOS |

## Candidatos localizados, todavía no incorporados al pubspec

| Componente | Uso | Licencia/situación | Decisión |
|---|---|---|---|
| firebase_messaging 16.7.0 | Push Android/iOS | Plugin oficial Flutter/Firebase | Incorporar cuando configuremos FCM/APNs y el backend de notificaciones |
| Drift 2.35.0 | SQLite, migraciones, transacciones, FTS5 | Open source | Incorporar junto a la migración de persistencia/offline sync |
| Martin | Vector tiles desde PostGIS/PMTiles/MBTiles | Apache-2.0 o MIT | Adoptar en backend GIS |
| H3 de Uber | Indexación hexagonal y agregación espacial | Apache-2.0 | Adoptar en backend |
| Tippecanoe | Generación/optimización de vector tiles | Open source | Evaluar para pipeline GIS |
| PowerSync | Sincronización SQLite con backend | Cliente Apache-2.0; servidor con condiciones distintas | Evaluar antes de comprometer arquitectura |

## Infraestructura priorizada

### Routing
Valhalla 3.9.0 es el motor seleccionado. La aplicación utiliza una interfaz RoutingService y un adaptador fino.

### GIS y cartografía
- PostgreSQL + PostGIS.
- GDAL.
- PROJ.
- MapLibre.
- PMTiles.
- Martin como servidor de vector tiles y herramientas PMTiles/MBTiles en backend.

### Indexación espacial
H3 de Uber es candidato prioritario para backend: celdas, geofencing aproximado, agregación espacial, búsqueda de voluntarios y privacidad de localización.

### Identidad
Keycloak / OIDC.

### Observabilidad
Sentry para cliente; OpenTelemetry + Prometheus + Grafana para backend/infraestructura.

### Datos oficiales
AEMET, MITECO, IGN/CNIG, Protección Civil y fuentes territoriales mediante Source Gateway.

## Componentes eliminados o descartados

- flutter_map: eliminado del MVP móvil.
- flutter_map_mbtiles: no es dependencia activa.
- adaptadores específicos Web/desktop: fuera de alcance.
- BRouter como router principal: no proporciona una estrategia única Android+iOS adecuada.
- flutter_foreground_task para navegación continua: no satisface el modelo iOS requerido.
- bgeo_background_geolocation: motor nativo cerrado, licencia de release y uploader no verificado; no se incorpora ahora.
- libre_location: no suficientemente maduro para una función crítica.

## Persistencia
Hive CE se mantiene únicamente para no romper el MVP actual. Drift queda como candidato para la siguiente capa, donde necesitaremos rutas, sesiones, offline queue, reportes y reconciliación con transacciones y migraciones.

PowerSync queda en evaluación: el cliente es Apache-2.0, pero deben evaluarse las condiciones del servidor antes de comprometer la arquitectura.

## Regla de release
Antes de publicar una build de producción se debe generar y revisar SBOM, licencias directas y transitivas, vulnerabilidades, notices y obligaciones de atribución.

## Evidencia
- MapLibre GL 0.27.1: Android/iOS, MVT/PMTiles y offline regions.
- Martin: PostGIS, PMTiles y MBTiles vector tile server/tooling.
- H3: Apache-2.0.
- battery_plus: Android/iOS.
- firebase_messaging: Android/iOS.
- Drift: SQLite, migraciones y transacciones.
- BGeo: motor nativo cerrado, licencia de release y uploader no verificado.