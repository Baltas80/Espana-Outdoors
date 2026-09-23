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

| Componente | Uso | Origen | Estado |
|---|---|---|---|
| Flutter / Dart | Aplicación multiplataforma | Google / ecosistema Flutter | Aceptado como base de plataforma; verificar versión y notices en release |
| flutter_map | Renderizado cartográfico Flutter | Comunidad open source | Aceptado provisionalmente; validar licencia/versionado antes de producción |
| flutter_map_mbtiles | Mapas MBTiles/offline | Comunidad open source | Aceptado provisionalmente; validar licencia/versionado antes de producción |
| latlong2 | Geometría/geodesia básica | Comunidad Dart | Aceptado provisionalmente |
| Riverpod | Estado | Comunidad Dart | Aceptado provisionalmente |
| go_router | Navegación | Ecosistema Flutter | Aceptado provisionalmente |
| geolocator | GPS/ubicación | Comunidad Flutter | Aceptado provisionalmente |
| connectivity_plus | Conectividad | Comunidad Flutter | Aceptado provisionalmente |
| shared_preferences | Preferencias no críticas | Ecosistema Flutter | Aceptado provisionalmente |
| flutter_secure_storage | Secretos/credenciales locales | Comunidad Flutter | Aceptado provisionalmente |
| file_picker | Selección de archivos | Comunidad Flutter | Aceptado provisionalmente |
| path_provider | Rutas de almacenamiento | Ecosistema Flutter | Aceptado provisionalmente |
| gpx | GPX | Comunidad Dart | Aceptado provisionalmente |
| Hive CE | Persistencia local | Comunidad open source | Aceptado provisionalmente; revisar estado/mantenimiento |
| url_launcher | Enlaces/acciones del SO | Ecosistema Flutter | Aceptado provisionalmente |
| http | Cliente HTTP | Dart | Aceptado provisionalmente |
| flutter_lints | Calidad estática | Ecosistema Flutter | Desarrollo/CI |

> Esta tabla no sustituye un SBOM ni la inspección de los ficheros LICENSE/COPYING de cada dependencia. Antes de una release se generará un inventario de dependencias transitivas y sus licencias.

## Infraestructura recomendada para evaluar

### GIS y cartografía

- **PostgreSQL + PostGIS** para almacenamiento y consultas geoespaciales.
- **GDAL** para ingestión/conversión de datos geoespaciales.
- **PROJ** para transformaciones de coordenadas.
- **MapLibre** como opción prioritaria a evaluar para reducir lock-in del renderizado.
- **PMTiles / MBTiles** para distribución y almacenamiento offline cuando el flujo de datos lo permita.
- **MapTiler / proveedor equivalente** solo donde el coste, SLA y licencia justifiquen usar un proveedor gestionado.

### Routing

Evaluar **Valhalla**, **GraphHopper** y **OSRM** sobre rutas y perfiles outdoor reales antes de seleccionar el motor definitivo. La decisión debe considerar senderos, restricciones, perfiles, coste de operación, datos OSM, elevación, personalización y licencia.

### Elevación

Evaluar datasets oficiales y abiertos de IGN/CNIG y pipelines con GDAL/PROJ/PostGIS. No depender de una API comercial para cada consulta si los datos pueden procesarse y cachearse legalmente.

### Identidad y autorización

Evaluar **Keycloak / OpenID Connect** como componente maduro para identidad, autenticación, MFA y autorización, evitando implementar autenticación casera. La arquitectura debe mantener una interfaz AuthService para poder sustituirlo si fuera necesario.

### Observabilidad

Evaluar **OpenTelemetry** como capa de instrumentación y, según coste/operación, **Prometheus + Grafana** y **Sentry** para métricas, trazas, dashboards y errores/crashes.

### Datos oficiales

Integrar mediante adaptadores desacoplados fuentes oficiales como **AEMET OpenData**, **MITECO**, **IGN/CNIG**, Protección Civil y fuentes autonómicas/municipales cuando sus condiciones de reutilización y estabilidad sean adecuadas. Cada adaptador debe conservar procedencia, timestamp, vigencia, licencia y nivel de confianza.

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
- routing genérico.

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
