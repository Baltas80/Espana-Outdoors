# Experimento: Organic Maps como base de España Outdoor

Estado: evaluación técnica en rama aislada. No integrar en `master` ni sustituir la aplicación actual hasta validar compilación, licencias, capacidades y coste de mantenimiento.

## Objetivo

Evaluar Organic Maps como plataforma funcional reutilizable para reducir el trabajo de cartografía, mapas sin conexión, búsqueda de lugares y navegación. La prioridad es obtener una aplicación outdoor funcional, no preservar la implementación actual por inercia.

- Repositorio upstream: https://github.com/organicmaps/organicmaps
- Licencia principal del código: Apache-2.0, sujeta a revisión de componentes, recursos y dependencias.
- Los datos cartográficos y los paquetes de mapas tienen licencias y obligaciones de atribución independientes.
- La licencia no garantiza por sí sola que una distribución white-label o un fork comercial completo esté libre de obligaciones adicionales. Revisar el README y consultar al proyecto cuando proceda.

## Decisión de arquitectura que se debe probar

Organic Maps es una aplicación nativa madura con una base importante en C++ y capas específicas para Android/iOS. España Outdoor usa Flutter/Dart y un backend Go. No es un paquete Flutter que se pueda añadir a `pubspec.yaml` y esperar una integración directa.

La vía de menor riesgo para esta prueba es mantener una rama aislada y comprobar primero si Organic Maps puede compilarse y ejecutarse como aplicación base independiente. Después se decidirá entre:

1. Adoptar/forkear Organic Maps como aplicación principal y portar las funciones propias de España Outdoor.
2. Integrar capacidades seleccionadas mediante una frontera nativa controlada.
3. Descartarlo si el coste de portar funciones, mantener el fork o cumplir las licencias supera el beneficio.

No se propone mantener dos motores cartográficos en producción sin una razón demostrable.

## Matriz inicial de cobertura

| Capacidad | Organic Maps | Trabajo pendiente para España Outdoor |
|---|---|---|
| Mapas offline | Capacidad central | Validar cobertura, descarga/actualización, almacenamiento y límites en España |
| Mapa vectorial y POI | Capacidad central | Comprobar categorías y calidad de datos locales |
| Búsqueda de lugares | Incluida | Mejorar búsquedas y filtros específicos de naturaleza española |
| Navegación peatonal | Incluida | Validar rutas de montaña; no asumir que un itinerario en OSM es seguro o transitable |
| Rutas de senderismo | Parcial, dependiente de datos OSM y del perfil de enrutamiento | Inventariar GR/PR/SL, tracks oficiales, dificultad, desnivel y estado de mantenimiento |
| Importación GPX | Debe probarse en la versión candidata | Validar tracks largos, waypoints, perfiles y manejo de errores |
| Grabación GPS | Debe probarse contra requisitos del producto | Ciclo de vida en segundo plano, recuperación tras muerte del proceso, precisión y consumo |
| Brújula/orientación | Capacidades disponibles según plataforma | Calibración, permisos, comportamiento sin sensores y UX de campo |
| Meteorología AEMET | No sustituye el gateway propio | Conectar con `services/source-gateway`, trazabilidad, antigüedad y fallbacks |
| Alertas meteorológicas | No cubre por sí solo el sistema español requerido | Umbrales, avisos oficiales, zona afectada, expiración y modo offline |
| Astronomía | No es cobertura principal | Añadir cálculo astronómico local y datos verificables |
| Flora y fauna | POI/datos generales no equivalen a una base naturalista curada | Fuentes con licencia clara, distribución, estacionalidad y conservación |
| Seguridad y rescate | No sustituye un sistema específico | SOS, ubicación compartible, coordenadas, protocolo de emergencia y advertencias claras |
| Terreno y contexto territorial | Parcial, según capas y datos disponibles | Pendiente de evaluación de elevación, pendientes, espacios protegidos y fuentes oficiales |
| Funcionamiento sin conexión | Capacidad central | Probar cada función por separado; no asumir que meteorología, alertas o contenido dinámico estará disponible offline |

## Componentes maduros adicionales a evaluar

No incorporarlos todos por defecto. Cada uno debe cubrir una carencia identificada y tener licencia, mantenimiento y pruebas aceptables.

- **Valhalla** (MIT): motor de enrutamiento OSM; solo si el motor de Organic Maps no cubre perfiles o necesidades verificadas.
- **Planetiler** (Apache-2.0): generación de vector tiles; útil si se decide operar una canalización propia de mapas, no necesario por defecto.
- **QField** (GPL-2.0-or-later): GIS de campo para inspección y recopilación de datos; no es un sustituto directo de una app outdoor de consumo.
- **MapLibre Flutter**: alternativa de mapas en el stack Flutter existente; redundante si Organic Maps se adopta como app principal, salvo que la prueba justifique una integración concreta.

## Plan de evaluación y criterios de salida

1. Fijar una versión/commit upstream reproducible y registrar submódulos y dependencias.
2. Revisar README, licencia principal, licencias de terceros, recursos, datos y condiciones de distribución.
3. Preparar compilación Android en entorno limpio y registrar SDK/NDK, espacio, tiempo y errores.
4. Ejecutar pruebas de campo simuladas: modo avión, descarga de región, reinicio, GPS sin red, GPX grande, batería y recuperación.
5. Comparar las funciones existentes en España Outdoor con la implementación nativa de Organic Maps; separar reutilizable, reemplazable y exclusivo del proyecto.
6. Estimar el portado de gateway meteorológico, alertas, astronomía, naturaleza, seguridad y backend.
7. Decidir con evidencias si se adopta como base o se mantiene Flutter.

## Reglas de seguridad y calidad

- La navegación calculada no certifica que un sendero esté abierto, sea seguro ni transitable.
- Mostrar procedencia y fecha de actualización cuando el dato afecte a una decisión en montaña.
- No afirmar que una función opera offline hasta probarla sin conectividad.
- No incluir claves, tokens ni secretos en el repositorio.
- Mantener este experimento aislado; ningún cambio se incorpora automáticamente a `master`.
