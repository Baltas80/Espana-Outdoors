# Arquitectura inicial

## Capas

```text
UI / Design System
        |
Feature controllers (Riverpod)
        |
Domain models / use cases
        |
Repositories / ports
        |
Adapters: GIS, GPS, weather, alerts, storage, notifications
        |
External providers
```

## Regla clave

Las funcionalidades de producto no deben depender directamente de un proveedor externo. Cada integración importante debe estar detrás de una interfaz propia para permitir sustitución, fallback y pruebas.

## Offline-first

Las capacidades críticas deben seguir funcionando sin red:

- mapa previamente descargado;
- GPS;
- posición;
- rutas guardadas;
- datos de seguridad almacenados;
- contactos de confianza;
- registro de actividad local.

La sincronización será eventual y deberá resolver conflictos explícitamente.

## Datos dinámicos

Cada entidad dinámica debe transportar, cuando proceda:

- `source`;
- `sourceUrl`;
- `retrievedAt`;
- `validUntil`;
- `confidence`;
- `license`.

## Seguridad

Los secretos y credenciales se almacenan mediante almacenamiento seguro del sistema. Nunca se incorporan al código fuente ni a builds públicos.

## GIS

`flutter_map` se usa como cliente cartográfico inicial. El proveedor de tiles/routing debe ser configurable. La aplicación debe respetar siempre atribución, licencia y política de uso del proveedor elegido.

## Emergencias

SOS, 112, contactos y Rescue Link son módulos independientes. Ningún módulo comunitario debe impedir o retrasar el acceso a los servicios oficiales.

## Evolución prevista

1. Persistencia local robusta y descargas offline.
2. GPX y motor de rutas.
3. AEMET y fuentes oficiales de alertas.
4. Incendios y desastres.
5. Mascotas/fauna/conservación.
6. Backend y sincronización.
7. Rescue Link seguro.
8. IA asistiva con trazabilidad.
