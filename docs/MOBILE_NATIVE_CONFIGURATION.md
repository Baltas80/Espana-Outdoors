# Mobile native configuration

España Outdoor es Android + iOS/iPadOS. El proyecto guarda deliberadamente la lógica Flutter y genera los proyectos nativos durante bootstrap/CI.

El script `tool/configure_mobile_native.py` aplica la configuración nativa necesaria para las funciones de campo:

- Android: permisos de localización, foreground service, configuración de red local del renderer offline y `minSdk 24`.
- Android/OIDC: configura `appAuthRedirectScheme=com.espanaoutdoors` en Gradle para `flutter_appauth`. La biblioteca AppAuth gestiona el receptor de redirección; no se debe volver a insertar el callback de la dependencia retirada `openidconnect`.
- iOS: textos de permiso de ubicación y `UIBackgroundModes=location`.

La configuración Android incluye comprobaciones en `tool/verify_mobile_native.py` para asegurar que el placeholder de AppAuth está presente y que no queda el callback nativo de la dependencia antigua.

La aplicación utiliza las APIs maduras de geolocator, incluyendo AndroidSettings, AppleSettings y ForegroundNotificationConfig, en lugar de añadir otro SDK de geolocalización.

El flujo de CI debe ser:

1. `flutter create . --platforms=android,ios`
2. `python tool/configure_mobile_native.py --platform android` y `python tool/verify_mobile_native.py --platform android`
3. `flutter pub get`
4. `flutter analyze`
5. `flutter test`
6. Compilar Android release y validar que se generan APK y AAB.

Antes del lanzamiento real hay que revisar las fichas de privacidad de Google Play y App Store y justificar el acceso a ubicación en segundo plano. La configuración técnica no sustituye la revisión de políticas de las tiendas.
