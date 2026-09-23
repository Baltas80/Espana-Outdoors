# Mobile native configuration

España Outdoor es Android + iOS/iPadOS. El proyecto guarda deliberadamente la lógica Flutter y genera los proyectos nativos durante bootstrap/CI.

El script tool/configure_mobile_native.py aplica la configuración mínima necesaria para el seguimiento GPS en segundo plano:

- Android: coarse/fine location, background location, foreground service y foreground-service location.
- iOS: textos de permiso de ubicación y UIBackgroundModes=location.

La aplicación utiliza las APIs maduras de geolocator, incluyendo AndroidSettings, AppleSettings y ForegroundNotificationConfig, en lugar de añadir otro SDK de geolocalización.

El flujo de CI debe ser:

1. flutter create . --platforms=android,ios
2. python tool/configure_mobile_native.py
3. flutter pub get
4. flutter analyze
5. flutter test

Antes del lanzamiento real hay que revisar las fichas de privacidad de Google Play y App Store y justificar el acceso a ubicación en segundo plano. La configuración técnica no sustituye la revisión de políticas de las tiendas.
