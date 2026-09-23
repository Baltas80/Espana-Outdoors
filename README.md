# España Outdoor

Plataforma móvil premium para naturaleza, rutas, seguridad, mascotas, fauna, conservación y emergencias.

## Estado

**MVP 0.1 en construcción activa.** La base actual incluye arquitectura por capas, navegación, mapa, GPS, grabación de rutas, importación GPX, persistencia local de rutas, modo offline básico, privacidad y CI. El sistema visual premium de España Outdoor ya está incorporado en la app y documentado en `docs/brand_system.md`.

## Objetivo de plataformas

España Outdoor se concentra deliberadamente en **Android y iOS/iPadOS**. Son las plataformas de producto soportadas oficialmente y reciben toda la inversión de UX, GPS, navegación, mapas offline, SOS, Rescue Link, rendimiento y QA.

Web/PWA, Windows, macOS y Linux quedan fuera del alcance del producto y del MVP. No se desarrollarán adaptaciones de escritorio ni Web mientras no exista una decisión de producto posterior que justifique reabrir ese alcance. Esto reduce superficie de mantenimiento, matrices de pruebas, complejidad de distribución y código específico de plataforma.

La arquitectura conserva interfaces abstractas para permitir en el futuro integraciones con wearables, Garmin, GPS externos, Bluetooth y sensores sin comprometer el foco móvil actual.

## Trabajo reciente

- Design System premium: tokens de marca, estados semánticos, light/dark/high-contrast y componentes base.
- Marca vectorial reutilizable en `assets/brand/espana_outdoor_mark.svg`.
- Integración del símbolo de marca en la experiencia principal.
- Atribución visible de OpenStreetMap en el mapa.
- ADR de cartografía/offline con decisión de no usar los servidores públicos de teselas OSM para descargas offline.
- El proveedor cartográfico de producción ya no se fija en código: se inyecta por configuración y la aplicación evita silenciosamente usar OSM público en `production`.
- Arquitectura preparada para sustituir proveedor cartográfico sin acoplar la UI al proveedor.
- Licencia propietaria incorporada para el código y activos propios; las dependencias de terceros conservan sus licencias.
- Registro inicial de dependencias y alternativas maduras en `docs/THIRD_PARTY_LICENSES.md`.
- Valhalla integrado mediante una interfaz `RoutingService`, con endpoint de producción externo al código.
- Infraestructura reproducible para generar y servir tiles de Valhalla para España.
- Descargas offline regionales preparadas con `background_downloader`, incluyendo pausa/reanudación y persistencia de transferencias.
- El catálogo offline ya no contiene zonas ficticias: solo se muestran paquetes publicados por el backend configurado.
- RevenueCat conectado a la frontera de producto mediante entitlements Free/Premium/Professional.
- OpenID Connect integrado mediante un adaptador provider-neutral preparado para Keycloak.
- Sentry integrado con PII desactivada y DSN inyectado en runtime.
- Risk Engine corregido para que la confianza represente realmente la completitud de los datos verificados.
- CI de seguridad reforzado con Dependabot, Gitleaks, Trivy y CodeQL para GitHub Actions.

## Alcance MVP

- Android.
- iOS/iPadOS.
- Offline-first para las funciones críticas.
- Mapas y GIS desacoplados del proveedor.
- Datos con procedencia, fecha de actualización y nivel de confianza.
- Seguridad y privacidad desde el diseño.
- Importación y análisis GPX con persistencia local.
- Grabación GPS de rutas directamente sobre el mapa.
- SOS, contactos de confianza y Rescue Link como módulos aislados y auditables.
- Reutilización de SDKs, APIs y software maduro en lugar de reinventar componentes.

## Stack inicial

- Flutter / Dart.
- Riverpod para estado.
- go_router para navegación.
- MapLibre/PMTiles como renderizado/vector/offline cartográfico prioritario.
- geolocator para ubicación.
- connectivity_plus para estado de conectividad.
- shared_preferences para preferencias no críticas.
- flutter_secure_storage para secretos y credenciales locales.
- Hive CE para persistencia local de rutas.
- GPX para importación/exportación.
- Valhalla 3.9.0 para routing/map matching.
- PMTiles para paquetes cartográficos regionales.
- background_downloader para transferencias offline móviles.
- RevenueCat para billing/entitlements.
- OpenID Connect para identidad; Keycloak es el proveedor de infraestructura objetivo.
- Sentry para errores/crashes.

Las versiones se mantienen deliberadamente en rangos compatibles y deben revisarse periódicamente antes de releases.

## Configuración de routing

El cliente no contiene una URL de routing fija. En desarrollo o release se inyecta:

```bash
flutter run --dart-define=VALHALLA_BASE_URL=https://routing.example.com/
```

Si no se configura, el routing permanece deshabilitado de forma explícita en lugar de utilizar un proveedor no verificado.

## Configuración cartográfica

Producción requiere un proveedor contratado/operado y sus obligaciones de atribución:

```bash
flutter run \
  --dart-define=APP_ENV=production \
  --dart-define=MAP_TILE_URL=https://maps.example.com/{z}/{x}/{y}.png \
  --dart-define=MAP_ATTRIBUTION="Proveedor cartográfico"
```

Durante desarrollo, si no se configura un proveedor, se permite un fallback online de OpenStreetMap para facilitar pruebas. Ese fallback no se usa en producción ni para descargas offline/bulk.

## Configuración del catálogo offline

El catálogo se inyecta con:

```bash
flutter run --dart-define=OFFLINE_CATALOG_URL=https://api.example.com/v1/offline/regions
```

El endpoint debe devolver un array JSON con `id`, `name`, `description`, `downloadUrl`, `sizeBytes`, `updatedAt` y opcionalmente `sha256`. No se deben publicar URLs ni paquetes ficticios.

## Identidad OIDC / Keycloak

La aplicación no implementa autenticación casera. La configuración se inyecta:

```bash
--dart-define=OIDC_ISSUER=https://auth.example.com/realms/espana-outdoor
--dart-define=OIDC_CLIENT_ID=espana-outdoor-public
--dart-define=OIDC_REDIRECT_URI=espanaoutdoor://callback
```

El flujo objetivo es Authorization Code + PKCE con almacenamiento seguro gestionado por el componente OIDC maduro. Los secretos de clientes confidenciales permanecen exclusivamente en backend/infraestructura.

## Billing / Free / Premium / Professional

RevenueCat proporciona la capa de billing y España Outdoor consume solamente estos entitlements:

- `free`
- `premium`
- `professional`

El código de producto de las tiendas, precios y promociones no se reparte por la aplicación. La frontera de producto se mantiene en `OutdoorEntitlement` y `EntitlementGate`.

## Observabilidad

Sentry se habilita únicamente cuando se inyecta `SENTRY_DSN`:

```bash
--dart-define=APP_ENV=production \
--dart-define=SENTRY_DSN=https://example@sentry.example/123
```

`sendDefaultPii` permanece desactivado. No se deben registrar coordenadas de emergencia, ubicaciones sensibles de fauna, tokens ni secretos en eventos de observabilidad.

## Infraestructura Valhalla

`ops/valhalla/` contiene la infraestructura reproducible. Los datos PBF, tiles, extracts y el JSON generado de configuración quedan fuera de Git.

```bash
cd ops/valhalla
./build-config.sh
./build-spain.sh
docker compose up -d
```

El extracto de España procede de Geofabrik/OSM y debe gestionarse con las obligaciones de licencia y atribución correspondientes. La versión de Valhalla está fijada a `3.9.0` para reproducibilidad.

## Estructura

```text
lib/
  app/          aplicación, tema, marca y routing
  core/         modelos y servicios transversales
  domain/       entidades y reglas de dominio
  features/     funcionalidades de producto
  infrastructure/ adaptadores externos: routing, auth, billing y fuentes
  main.dart

docs/           arquitectura, privacidad, datos, seguridad y Design System
assets/         identidad visual y recursos reutilizables
ops/            infraestructura local/producción no sensible
.github/        CI y automatización
scripts/        bootstrap local
```

## Arranque local móvil

Requiere Flutter estable y toolchains de Android/iOS.

```bash
flutter create . --platforms=android,ios
flutter pub get
flutter analyze
flutter test
flutter devices
```

Para iOS se requiere macOS/Xcode para compilar, firmar y distribuir. Android puede compilarse con el SDK de Android correspondiente.

## Principios

1. No inventar datos de seguridad.
2. No presentar estimaciones de IA como hechos oficiales.
3. No exponer coordenadas sensibles de fauna.
4. No recopilar ubicación más tiempo del necesario.
5. SOS debe tener el mínimo número de pasos razonable.
6. Rescue Link nunca sustituye a los servicios profesionales de emergencia.
7. Toda fuente dinámica debe tener frescura y procedencia.
8. Ningún secreto entra en Git.
9. No usar `tile.openstreetmap.org` para descargas offline o prefetched bulk.
10. Las decisiones de proveedor deben considerar licencia, capacidad, coste, lock-in y rendimiento.
11. El código y los activos propios de España Outdoor son propietarios salvo indicación expresa.
12. Cada componente de terceros conserva su licencia y obligaciones originales.
13. La confianza del motor de riesgo mide calidad/completitud de datos, nunca seguridad absoluta.
14. Las funciones críticas de emergencia no dependen de billing, analytics ni conectividad continua.
15. Android e iOS/iPadOS son las únicas plataformas de producto soportadas actualmente.
16. Web, Windows, macOS y Linux no forman parte del alcance activo y no deben recibir trabajo específico salvo nueva decisión de producto.

## Documentación clave

- `docs/brand_system.md` — identidad visual y Design System.
- `docs/architecture/ADR-0001-maps-and-offline.md` — estrategia de cartografía, proveedores y offline.
- `docs/architecture/ADR-0003-valhalla-routing.md` — decisión y despliegue de routing.
- `docs/THIRD_PARTY_LICENSES.md` — registro de software de terceros y alternativas maduras.
- `docs/production-readiness.md` — variables de despliegue y gates de producción.
- `LICENSE.md` — licencia propietaria de España Outdoor.

## Licencia

El código, diseño y activos propios de España Outdoor están bajo **licencia propietaria**. El repositorio público no concede por sí mismo derechos de reutilización, redistribución, modificación o creación de productos derivados. Los componentes y datos de terceros se rigen por sus respectivas licencias y condiciones.
