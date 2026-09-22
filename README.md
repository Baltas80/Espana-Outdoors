# España Outdoor

Plataforma multiplataforma para naturaleza, rutas, seguridad, mascotas, fauna, conservación y emergencias.

## Estado

**MVP 0.1 en construcción activa.** La base actual incluye arquitectura por capas, navegación, mapa, GPS, grabación de rutas, importación GPX, persistencia local de rutas, modo offline básico, privacidad y CI. El sistema visual premium de España Outdoor ya está incorporado en la app y documentado en `docs/brand_system.md`.

## Estrategia de ingeniería: reuse-first

España Outdoor **no debe reimplementar infraestructura madura**. Antes de escribir código nuevo se evalúa una librería, SDK, motor, estándar o servicio existente. Solo se desarrolla código propio cuando aporta diferenciación, seguridad, privacidad, integración o una política de producto que no existe en la solución reutilizada.

La regla es: **software maduro para infraestructura; código España Outdoor para el producto**.

La decisión detallada está en `docs/architecture/ADR-0002-reuse-first-stack.md`.

Prioridades actuales:

1. Contratos de routing/elevación y adaptador Valhalla.
2. Contratos de alertas y gateway normalizado de datos oficiales.
3. Offline con formatos estándar MBTiles/PMTiles y proveedor de mapas desacoplado.
4. Navegación y navegación básica offline sobre el motor de routing.
5. Seguridad/SOS y Rescue Link con mínima exposición de ubicación.

## Trabajo reciente

- Design System premium: tokens de marca, estados semánticos, light/dark/high-contrast y componentes base.
- Marca vectorial reutilizable en `assets/brand/espana_outdoor_mark.svg`.
- Integración del símbolo de marca en la experiencia principal.
- Atribución visible de OpenStreetMap en el mapa.
- ADR de cartografía/offline con decisión de no usar los servidores públicos de teselas OSM para descargas offline.
- Arquitectura preparada para sustituir proveedor cartográfico sin acoplar la UI al proveedor.
- Política reuse-first para minimizar código propio y lock-in.

## Objetivos

- Android, iOS/iPadOS, Web, Windows, macOS y Linux.
- Offline-first para las funciones críticas.
- Mapas y GIS desacoplados del proveedor.
- Datos con procedencia, fecha de actualización y nivel de confianza.
- Seguridad y privacidad desde el diseño.
- Importación y análisis GPX con persistencia local multiplataforma.
- Grabación GPS de rutas directamente sobre el mapa.
- SOS, contactos de confianza y Rescue Link como módulos aislados y auditables.
- Reutilización de SDKs, APIs y software maduro en lugar de reinventar componentes.

## Stack inicial

- Flutter / Dart
- Riverpod para estado
- go_router para navegación
- flutter_map para cartografía multiplataforma en el MVP
- geolocator para ubicación
- connectivity_plus para estado de conectividad
- shared_preferences para preferencias no críticas
- flutter_secure_storage para secretos y credenciales locales
- Hive CE para persistencia local de rutas
- GPX para importación/exportación

Las versiones se mantienen deliberadamente en rangos compatibles y deben revisarse periódicamente antes de releases.

## Estructura

```text
lib/
  app/          aplicación, tema, marca y routing
  core/         modelos y servicios transversales
  domain/       entidades y reglas de dominio
  features/     funcionalidades de producto
  main.dart

docs/           arquitectura, privacidad, datos, seguridad y Design System
assets/         identidad visual y recursos reutilizables
.github/        CI y automatización
scripts/        bootstrap local
```

## Arranque local

Requiere Flutter estable instalado.

```bash
flutter create . --platforms=android,ios,web,windows,macos,linux
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

> `flutter create .` solo debe ejecutarse para generar los directorios nativos que el repositorio no necesita almacenar manualmente durante este bootstrap.

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
11. Preferir dependencias con licencias permisivas cuando resuelvan el mismo problema; GPL requiere decisión legal específica antes de incorporarse.
12. No duplicar en Dart funcionalidades maduras que puedan ejecutarse de forma fiable en infraestructura especializada.

## Documentación clave

- `docs/brand_system.md` — identidad visual y Design System.
- `docs/architecture/ADR-0001-maps-and-offline.md` — estrategia de cartografía, proveedores y offline.
- `docs/architecture/ADR-0002-reuse-first-stack.md` — política de reutilización, licencias y componentes candidatos.

## Licencia

Pendiente de decisión del propietario antes del lanzamiento público. Las dependencias de terceros mantienen sus propias licencias.
