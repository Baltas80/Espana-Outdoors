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
| geolocator 14.0.3 | GPS/ubicación y background location | Open source | Aceptado |
| connectivity_plus | Conectividad | Open source | Aceptado |
| shared_preferences | Preferencias no críticas | Open source | Aceptado |
| flutter_secure_storage | Secretos/credenciales locales | Open source | Aceptado |
| file_picker | Selección de archivos | Open source | Aceptado |
| path_provider | Rutas de almacenamiento | Open source | Aceptado |
| gpx | GPX | Open source | Aceptado |
| Hive CE | Persistencia local temporal | Open source | Mantener durante MVP |
| url_launcher | Acciones del SO | Open source | Aceptado |
| http | Cliente HTTP | Dart | Aceptado |
| crypto 3.0.7 | SHA-256 para integridad de paquetes offline | BSD-3-Clause | Adoptado |
| purchases_flutter / purchases_ui_flutter 10.13.1 | Billing/entitlements | RevenueCat; revisar términos comerciales | Aceptado |
| background_downloader 9.6.2 | Descarga de paquetes offline | BSD-3-Clause / MIT | Aceptado para móvil |
| openidconnect 3.0.0 | OIDC/OAuth 2.0 + PKCE | Apache-2.0 | Aceptado |
| sentry_flutter 9.30.1 | Crash/error telemetry | MIT | Aceptado |
| battery_plus 7.1.1 | Estado de batería | Open source | Adoptado para SOS |

## Dependencias del backend Rescue Link

| Componente | Uso | Licencia/condición | Estado |
|---|---|---|---|
| Go 1.27.1 | Runtime/backend | Licencia Go | Adoptado |
| go-oidc/v3 3.21.0 | Verificación OIDC/Keycloak | Apache-2.0 | Adoptado |
| pgx/v5 5.11.0 | PostgreSQL | MIT | Adoptado |
| x/time 0.16.0 | Rate limiting | BSD-3-Clause | Adoptado |
| PostgreSQL + PostGIS | Persistencia geoespacial/backend | Open source; revisar notices del paquete base | Infraestructura |
## ## Candidatos localizados, todavía no incorporados al pubspec

| Componente | Uso | Licencia/situación | Decisión |
|---|---|---|---|
| firebase_messaging 16.7.0 | Push Android/iOS | Plugin oficial Flutter/Firebase | Incorporar cuando configuremos FCM/APNs y backend de notificaciones |
| Drift 2.35.0 | SQLite, migraciones, transacciones, FTS5 | Open source | Incorporar cuando rutas, sesiones y sincronización superen el alcance de Hive |
| Martin | Vector tiles desde PostGIS/PMTiles/MBTiles | Apache-2.0 o MIT | Adoptar en backend GIS |
| H3 de Uber | Indexación hexagonal y agregación espacial | Apache-2.0 | Adoptar en backend |
| Tippecanoe | Generación/optimización de vector tiles | Open source | Evaluar para pipeline GIS |
| PowerSync | Sincronización SQLite con backend | Cliente Apache-2.0; servidor con condiciones distintas | Evaluar antes de comprometer arquitectura |

## Persistencia

Hive CE se mantiene durante el MVP para rutas importadas, segmentos activos recuperables y cola local de sincronización. Drift queda como candidato de evolución, no como dependencia forzada.

PowerSync queda en evaluación: el cliente es Apache-2.0, pero deben evaluarse las condiciones del servidor antes de comprometer la arquitectura.