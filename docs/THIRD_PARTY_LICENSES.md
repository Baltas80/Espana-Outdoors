# ESPAÑA OUTDOOR — THIRD-PARTY SOFTWARE & LICENCE REGISTER

**Estado:** registro inicial; debe validarse automáticamente y actualizarse antes de cada release.

Este documento separa claramente el código propietario de ESPAÑA OUTDOOR de las dependencias y servicios de terceros.

## Principio de aceptación

Una dependencia solo se incorpora a producción después de revisar:

1. licencia y compatibilidad con distribución propietaria;
2. mantenimiento y actividad del proyecto;
3. seguridad y vulnerabilidades conocidas;
4. soporte multiplataforma;
5. rendimiento y consumo de batería/red;
6. coste y límites comerciales;
7. lock-in y facilidad de sustitución;
8. procedencia y cadena de suministro;
9. obligaciones de atribución/notices;
10. impacto sobre la distribución de aplicaciones propietarias.

## Dependencias actuales del MVP

| Componente | Uso | Licencia/condición | Estado |
|---|---|---|---|
| Flutter / Dart | Aplicación multiplataforma | Ecosistema Flutter | Aceptado como base de plataforma; verificar notices en release |
| flutter_map | Renderizado cartográfico Flutter | Open source | Aceptado provisionalmente; validar licencia/versionado antes de producción |
| flutter_map_mbtiles | Mapas MBTiles/offline | Open source | Aceptado provisionalmente |
| maplibre_gl | Renderizado MapLibre disponible para evolución del mapa | Open source | Aceptado provisionalmente; mantener como alternativa desacoplada |
| pmtiles | Lectura de archivos PMTiles | BSD-2-Clause | Aceptado |
| latlong2 | Geometría/geodesia básica | Open source | Aceptado provisionalmente |
| Riverpod | Estado | Open source | Aceptado provisionalmente |
| go_router | Navegación | Open source | Aceptado provisionalmente |
| geolocator | GPS/ubicación | Open source | Aceptado provisionalmente |
| connectivity_plus | Conectividad | Open source | Aceptado provisionalmente |
| shared_preferences | Preferencias no críticas | Open source | Aceptado provisionalmente |
| flutter_secure_storage | Secretos/credenciales locales | Open source | Aceptado provisionalmente |
| file_picker | Selección de archivos | Open source | Aceptado provisionalmente |
| path_provider | Rutas de almacenamiento | Open source | Aceptado provisionalmente |
| gpx | GPX | Open source | Aceptado provisionalmente |
| Hive CE | Persistencia local | Open source | Revisar mantenimiento antes de producción |
| url_launcher | Enlaces/acciones del SO | Open source | Aceptado provisionalmente |
| http | Cliente HTTP | Dart | Aceptado provisionalmente |
| purchases_flutter / purchases_ui_flutter | Entitlements y compras multiplataforma | SDK de RevenueCat; revisar términos comerciales | Aceptado como infraestructura de billing, pendiente de configuración de producción |
| background_downloader | Transferencias offline con pausa/reanudación | BSD-3-Clause / MIT | Aceptado para Android, iOS, Windows, macOS y Linux; Web mantiene un camino específico |
| flutter_lints | Calidad estática | Ecosistema Flutter | Desarrollo/CI |

## Infraestructura aceptada/priorizada

### Routing

**Valhalla 3.9.0** es el motor seleccionado. Su código está bajo MIT. La aplicación utiliza una interfaz `RoutingService` y un adaptador fino, evitando algoritmos propios de routing. La infraestructura se fija inicialmente a 3.9.0 para reproducibilidad.

### GIS y cartografía

- **PostgreSQL + PostGIS** para almacenamiento y consultas geoespaciales.
- **GDAL** para ingestión/conversión de datos geoespaciales.
- **PROJ** para transformaciones de coordenadas.
- **MapLibre** como opción prioritaria para reducir lock-in del renderizado.
- **PMTiles / MBTiles** para distribución y almacenamiento offline cuando el flujo de datos lo permita.

### Identidad y autorización

Evaluar **Keycloak / OpenID Connect** como componente maduro para identidad, autenticación, MFA y autorización, evitando implementar autenticación casera. La arquitectura debe mantener una interfaz AuthService para poder sustituirlo si fuera necesario.

### Observabilidad

Evaluar **OpenTelemetry** como capa de instrumentación y, según coste/operación, **Prometheus + Grafana** y **Sentry** para métricas, trazas, dashboards y errores/crashes.

### Datos oficiales

Integrar mediante adaptadores desacoplados fuentes oficiales como **AEMET OpenData**, **MITECO**, **IGN/CNIG**, Protección Civil y fuentes autonómicas/municipales cuando sus condiciones de reutilización y estabilidad sean adecuadas. Cada adaptador debe conservar procedencia, timestamp, vigencia, licencia y nivel de confianza.

### Datos OSM

Los extractos de OSM usados para Valhalla y cartografía deben gestionarse respetando ODbL y las obligaciones de atribución. Los extractos grandes y tiles generados no se almacenan en Git.

## Componentes que NO deben reinventarse

No implementar desde cero cuando exista una alternativa madura y compatible:

- autenticación/OIDC;
- criptografía;
- almacenamiento seguro de secretos;
- renderizado de mapas;
- parsing GPX;
- proyección geográfica;
- procesamiento GIS;
- observabilidad/tracing;
- métricas;
- gestión de logs;
- push notifications;
- pagos/suscripciones;
- CI/CD;
- escaneo de dependencias y SBOM;
- almacenamiento de objetos;
- colas/event bus;
- servidor de teselas;
- routing genérico;
- transferencias de archivos en segundo plano.

## Código que sí debe ser propio

La diferenciación de ESPAÑA OUTDOOR debe concentrarse en:

- modelo de estado y riesgo de rutas;
- motor "¿PUEDO HACER ESTA RUTA HOY?";
- Plan de Ruta;
- SOS y flujos de seguridad específicos;
- Rescue Link y sus políticas de autorización/caducidad;
- NATURA PROTECT;
- modelo de conservación;
- integración y normalización de fuentes oficiales;
- reglas de privacidad de ubicación;
- experiencia outdoor y Design System;
- reglas de producto para mascotas/fauna;
- orquestación de recomendaciones;
- búsqueda semántica propia sobre datos autorizados;
- modelo de datos y APIs propias;
- sincronización offline específica del producto.

## Regla de release

Antes de publicar una build de producción se debe generar y revisar un SBOM, comprobar licencias directas y transitivas, detectar vulnerabilidades, conservar notices requeridos y verificar que ningún componente con obligaciones incompatibles haya sido incorporado accidentalmente.
