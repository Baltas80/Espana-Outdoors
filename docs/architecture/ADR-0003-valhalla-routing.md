# ADR-0003 — Valhalla como motor de routing outdoor

## Estado
Aceptado.

## Decisión
España Outdoor no implementará un motor de routing propio. La aplicación utiliza una interfaz `RoutingService` y delega el cálculo a Valhalla mediante `ValhallaRoutingService`.

La instancia de producción se ejecutará bajo infraestructura controlada por España Outdoor y se configurará mediante `VALHALLA_BASE_URL`. No se incrusta ningún endpoint público en la aplicación.

## Motivos

- Valhalla es un motor maduro para OSM y soporta routing peatonal, bicicleta y automóvil, map matching, matrices, isócronas, elevación y narrativas de maniobras.
- La API REST usa JSON y existe una especificación OpenAPI mantenida por el proyecto.
- Su estructura de datos por tiles permite regionalización y routing offline a nivel de infraestructura.
- La licencia del motor es MIT.
- Evita mantener algoritmos críticos de routing propios.

## Datos

Para el primer despliegue español se utiliza un extracto OSM de Geofabrik. Los datos OSM permanecen sujetos a ODbL y a sus obligaciones de atribución. La descarga de datos se realiza fuera del repositorio; nunca se almacenan extractos PBF ni tiles generados en Git.

## Versionado

La infraestructura está fijada inicialmente a Valhalla `3.9.0`. Las actualizaciones de versión se harán de forma deliberada, con pruebas de routing y revisión de seguridad.

## Seguridad

- La URL del motor se configura fuera del código.
- El cliente establece timeout para evitar bloqueos indefinidos.
- Un fallo del motor no genera rutas inventadas ni instrucciones falsas.
- El endpoint público de demostración de Valhalla no se utilizará como backend de producción.

## Elevación

Valhalla queda preparado para utilizar datos de elevación suministrados por infraestructura. El producto no presenta desnivel/elevación como dato oficial hasta que exista una fuente DEM real y trazable.

## Fuentes técnicas

- Valhalla API: https://valhalla.github.io/valhalla/api/
- Valhalla OpenAPI: https://valhalla.github.io/valhalla/api/openapi/
- Valhalla: https://github.com/valhalla/valhalla
- Geofabrik Spain: https://download.geofabrik.de/europe/spain.html
