# ADR-0006 — Android/iOS como plataformas de producto

- Estado: Aceptado
- Fecha: 2026-09-23
- Alcance: producto, UX, QA, CI/CD y arquitectura cliente

## Contexto

España Outdoor es una aplicación outdoor de seguridad y navegación. Las funciones de mayor valor —GPS, navegación, mapas offline, grabación, SOS, alertas y Rescue Link— dependen principalmente de capacidades móviles y sensores del dispositivo.

Mantener simultáneamente Web, Windows, macOS y Linux como plataformas de primera clase aumenta la superficie de código, la matriz de pruebas, las diferencias de almacenamiento/offline, los problemas de ubicación en segundo plano y el coste de release sin aportar suficiente valor al MVP.

## Decisión

Las únicas plataformas cliente soportadas oficialmente son:

- Android.
- iOS/iPadOS.

Flutter continúa siendo la base multiplataforma, pero el proyecto utilizará únicamente los targets Android/iOS para el producto actual.

Web/PWA, Windows, macOS y Linux quedan fuera del alcance activo. No se debe añadir código específico, UI específica, CI específica ni QA específico para esos targets salvo una nueva decisión de producto.

La arquitectura sí debe mantener fronteras de plataforma limpias para futuras integraciones de:

- Apple Watch.
- Wear OS.
- Garmin.
- GPS externos.
- Bluetooth LE.
- sensores outdoor.

## Consecuencias positivas

- Menor superficie de mantenimiento.
- Menor matriz de QA.
- Menos divergencia de UX.
- Mayor concentración en GPS, mapas y offline.
- Menor complejidad de almacenamiento.
- Menor coste de CI/CD.
- Menor riesgo de lanzar funciones críticas con comportamiento distinto según plataforma.
- Más tiempo disponible para seguridad, Rescue Link, Risk Engine y calidad de datos.

## Consecuencias negativas

- No habrá cliente de escritorio oficial.
- La planificación avanzada en pantalla grande queda para una futura fase.
- No habrá PWA oficial en el alcance actual.

## Regla de implementación

No implementar workarounds para mantener artificialmente compatibilidad con Web/desktop. Cuando una dependencia o API tenga diferencias entre plataformas, se priorizarán los contratos Android/iOS y se mantendrá la lógica de dominio independiente del framework.
