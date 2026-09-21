# Plataformas

## Objetivo

Android, iOS/iPadOS, Web, Windows, macOS y Linux.

El repositorio guarda el núcleo Flutter y genera los directorios nativos mediante `flutter create` hasta que necesitemos personalizaciones específicas.

## Ubicación

Cuando se active GPS real, revisar antes de cada release:

- Android: permisos de ubicación en primer/segundo plano según necesidad real.
- iOS/iPadOS: `NSLocationWhenInUseUsageDescription` y solo permisos adicionales si una función los necesita.
- macOS/Windows/Linux: capacidades y permisos del sistema.
- Web: HTTPS y permisos del navegador.

## Emergencias

La integración de llamada y compartición de ubicación debe utilizar APIs nativas cuando sean necesarias. No debe implementarse un mecanismo que prometa que el sistema operativo entregará coordenadas al 112 si el dispositivo/red no lo permite.

## Mapas

El proveedor de tiles debe ser configurable. Para producción habrá que seleccionar un proveedor con capacidad, SLA y política de uso compatibles con el tráfico esperado y mantener atribución visible.

## Offline

La descarga de mapas no debe depender de una conexión permanente. La implementación futura debe almacenar tiles/datos en una base local con cuotas, integridad, versionado y eliminación controlada.
