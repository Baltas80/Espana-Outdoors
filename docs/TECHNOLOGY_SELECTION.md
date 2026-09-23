# ESPAÑA OUTDOOR — TECHNOLOGY SELECTION

**Fecha:** 2026-09-23
**Objetivo:** minimizar código propio no diferenciador y construir sobre componentes maduros.

## Decisiones base

| Área | Primera opción a evaluar | Alternativas | Código propio |
|---|---|---|---|
| Cliente multiplataforma | Flutter | React Native / nativo | UI, dominio y adaptadores |
| Estado | Riverpod | Bloc | Muy poco |
| Navegación | go_router | Router nativo | Configuración |
| Map renderer | MapLibre/Flutter adapter | flutter_map / Mapbox | Integración y UX |
| Offline maps | PMTiles/MBTiles + almacenamiento local | proveedor gestionado | descarga, catálogo y sincronización |
| Base GIS | PostgreSQL + PostGIS | PostgreSQL + extensiones GIS equivalentes | modelo de dominio |
| GIS ETL | GDAL + PROJ | herramientas especializadas | pipelines propios |
| Routing | Valhalla / GraphHopper / OSRM | servicio comercial | perfiles, reglas outdoor y fallback |
| Elevación | datasets IGN/CNIG + procesamiento GIS | proveedor de elevación | pipeline y caché |
| Identidad | Keycloak + OIDC | proveedor IAM gestionado | AuthService/adaptadores |
| API | servicio backend modular | gateway/API gestionada | dominio y políticas |
| Eventos | NATS / RabbitMQ / Kafka según escala | colas gestionadas | contratos/eventos críticos |
| Objetos | S3-compatible | almacenamiento gestionado | políticas y metadatos |
| Observabilidad | OpenTelemetry | SDK proveedor | dashboards/alertas |
| Errores cliente | Sentry | alternativa compatible | integración |
| Métricas | Prometheus + Grafana | servicio gestionado | métricas de negocio |
| CI/CD | GitHub Actions | GitLab CI | workflows |
| Seguridad supply-chain | Dependabot + CodeQL + SBOM | Trivy/Grype según pipeline | políticas |
| Push | FCM/APNs mediante abstracción | proveedor push | NotificationService |
| Pagos | App Store / Google Play + proveedor web adecuado | Stripe donde proceda | entitlement/planes |

## Investigación actual

### Flutter

Flutter mantiene despliegue oficial para Android, iOS, Windows, macOS, Linux y Web. Esto encaja con el objetivo multiplataforma de España Outdoor y reduce la necesidad de mantener seis aplicaciones independientes. La arquitectura debe reservar adaptadores nativos para GPS en segundo plano, Bluetooth, sensores y capacidades específicas de cada plataforma cuando un plugin maduro no sea suficiente.

Fuente: documentación oficial de Flutter.

### Meteorología

AEMET OpenData dispone de una API REST y publica datos reutilizables, incluidas predicciones específicas de montaña y predicciones por municipio. Debe utilizarse mediante un adaptador `WeatherService`, manteniendo procedencia, timestamp, vigencia y estado del proveedor.

Fuente: AEMET OpenData.

### Datos ambientales

MITECO publica un catálogo de datos abiertos con datasets INSPIRE y conjuntos de alto valor, además de acceso mediante APIs. Debe utilizarse como una fuente prioritaria para capas ambientales, conservación y territorio cuando la licencia y la cobertura sean adecuadas.

Fuente: Portal de Datos Abiertos de MITECO.

### Identidad

Keycloak implementa OpenID Connect y proporciona autenticación/autorización madura, gestión de usuarios y MFA. Es preferible a crear un sistema de contraseñas y tokens desde cero. Se mantendrá una interfaz `AuthService` para evitar lock-in.

Fuente: documentación oficial de Keycloak.

## GIS: estrategia recomendada

### 1. Datos

- OSM como una fuente geográfica, respetando ODbL, atribución y condiciones de uso.
- IGN/CNIG y administraciones públicas para fuentes oficiales españolas.
- MITECO y organismos autonómicos para conservación y medio ambiente.
- AEMET y organismos oficiales para meteorología/avisos.

### 2. Almacenamiento

**PostgreSQL + PostGIS** debe ser la columna vertebral geoespacial del backend. Permite geometrías, índices espaciales, consultas por proximidad, intersecciones, geofencing y análisis territorial sin inventar un motor GIS propio.

### 3. Procesamiento

**GDAL + PROJ** deben encargarse de ingestión, conversión y reproyección cuando sea aplicable. El código propio debe limitarse a pipelines, validaciones, normalización y reglas de negocio.

### 4. Mapas offline

No utilizar los servidores públicos de teselas de OpenStreetMap para descargas masivas. Preparar un pipeline de generación de paquetes offline basado en formatos adecuados y proveedores/datos con derechos de redistribución compatibles. Evaluar PMTiles y MBTiles según el tipo de capa.

### 5. Routing

No implementar un algoritmo de routing desde cero. Evaluar en entorno real:

- Valhalla: fuerte candidato para perfiles multimodales y personalización.
- GraphHopper: candidato para routing configurable y operación propia.
- OSRM: excelente referencia para routing rápido basado en OSM, pero requiere comprobar si cubre suficientemente el dominio outdoor.

La selección definitiva se realizará con un benchmark de rutas reales españolas, incluyendo senderos, caminos, restricciones, desnivel y rutas largas.

## Código propio que NO debemos escribir si existe alternativa madura

No crear desde cero:

- parser GPX;
- motor de mapas;
- motor de teselas;
- motor de routing genérico;
- motor de proyecciones;
- base GIS;
- IAM/OIDC;
- criptografía;
- almacenamiento seguro de contraseñas;
- telemetría/tracing;
- métricas;
- dashboards;
- pipeline genérico de CI;
- sistema genérico de notificaciones;
- sistema de pagos;
- cola/event bus genérico;
- servidor de objetos;
- scanner de vulnerabilidades;
- generador de SBOM.

## Código propio que sí aporta diferenciación

1. **Route State Engine** — NORMAL / PRECAUCIÓN / PROBLEMAS / CERRADA con evidencia y vigencia.
2. **Can I Do This Route Today?** — combinación explicable de condiciones, meteorología, avisos, exposición, dificultad, peligros y perfil.
3. **Pet Mode** — reglas de compatibilidad y riesgo para mascotas.
4. **Natura Protect** — conservación y protección de localizaciones sensibles.
5. **Rescue Link** — autorización, minimización, caducidad y política de no exposición de voluntarios.
6. **Safety Plan** — plan de salida/regreso/contactos y estado de emergencia.
7. **Official vs Spain Outdoor advisory model** — procedencia y confianza.
8. **Source Gateway** — normalización, frescura, fallback y circuit breaker de fuentes.
9. **Offline Sync Engine** — sincronización específica de rutas, reportes, estado y emergencias.
10. **Outdoor Design System** — experiencia premium y accesible.

## Requisitos de selección de proveedores

Cada proveedor debe tener una ficha con:

- versión/fecha;
- licencia;
- coste estimado;
- SLA y límites;
- regiones/cobertura;
- dependencia de red;
- soporte offline;
- rendimiento;
- mantenimiento;
- vulnerabilidades;
- lock-in;
- estrategia de salida;
- obligaciones de atribución;
- compatibilidad con distribución propietaria.

## Resultado de esta fase

La dirección tecnológica es **buy/build selectively**: comprar/reutilizar infraestructura madura y reservar el desarrollo propio para la inteligencia outdoor, seguridad, conservación, integración de fuentes y experiencia de producto que hacen diferente a España Outdoor.
