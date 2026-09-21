# España Outdoor

Plataforma multiplataforma para naturaleza, rutas, seguridad, mascotas, fauna, conservación y emergencias.

## Estado

**Bootstrap técnico / MVP 0.1**. El repositorio parte vacío y esta primera base establece la arquitectura, diseño, navegación, mapa, GPS, modo offline básico, privacidad y CI.

## Objetivos

- Android, iOS/iPadOS, Web, Windows, macOS y Linux.
- Offline-first para las funciones críticas.
- Mapas y GIS desacoplados del proveedor.
- Datos con procedencia, fecha de actualización y nivel de confianza.
- Seguridad y privacidad desde el diseño.
- SOS, contactos de confianza y Rescue Link como módulos aislados y auditables.
- Reutilización de SDKs, APIs y software maduro en lugar de reinventar componentes.

## Stack inicial

- Flutter / Dart
- Riverpod para estado
- go_router para navegación
- flutter_map para cartografía multiplataforma
- geolocator para ubicación
- connectivity_plus para estado de conectividad
- shared_preferences para preferencias no críticas
- flutter_secure_storage para secretos y credenciales locales

Las versiones se mantienen deliberadamente en rangos compatibles y deben revisarse periódicamente antes de releases.

## Estructura

```text
lib/
  app/          aplicación, tema y routing
  core/         modelos y servicios transversales
  features/     funcionalidades de producto
  main.dart

docs/           arquitectura, privacidad, datos y seguridad
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

## Licencia

Pendiente de decisión del propietario antes del lanzamiento público. Las dependencias de terceros mantienen sus propias licencias.
