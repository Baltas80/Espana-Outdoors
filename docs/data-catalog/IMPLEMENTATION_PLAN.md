# España Outdoor — plan de datos: rutas y biodiversidad

## Principio de arquitectura

Rutas y Flora/Fauna son **dos módulos independientes** en esta fase.

- No comparten tablas.
- No comparten lógica de ingestión.
- No se crea una relación ruta-especie.
- No se afirma que una ruta determine la presencia de una especie.
- Cada módulo tendrá sus propias fuentes, actualizaciones y modelo de datos.

## Módulo 1 — Rutas

### Objetivo

Permitir:

**Comunidad → Provincia → Localidad → rutas disponibles → filtros → ficha → mapa → GPX → navegación.**

### Fuentes prioritarias

1. CNIG / Senderos FEDME.
2. CNIG / Caminos Naturales.
3. Datos abiertos autonómicos.
4. OpenStreetMap como complemento.

### Modelo

`route`
`route_segment`
`route_place`

Cada registro conserva fuente, identificador de origen, licencia, fecha y versión.

### Resultado

El sistema de rutas será consumido por el mapa, GPX y posteriormente Valhalla.

## Módulo 2 — Flora y Fauna

### Objetivo

Construir un catálogo independiente de biodiversidad:

**Fauna / Flora → grupo → especie → ficha → fotografía → hábitat → distribución → conservación.**

### Fuentes prioritarias

1. EIDOS / MITECO como base oficial.
2. GBIF-Spain para checklists especializadas.
3. Fuentes autonómicas cuando aporten información oficial adicional.

### Modelo

`taxon`
`species_profile`
`species_distribution`
`species_media`

Cada registro conserva fuente, identificador, licencia, fecha y versión.

### Resultado

El catálogo de biodiversidad será consumido por la sección Flora y Fauna de la web y, posteriormente, por la aplicación como catálogo independiente.

## No hacer en esta fase

- No cruzar rutas con especies.
- No mostrar especies asociadas automáticamente a una ruta.
- No introducir filtros de biodiversidad dentro del buscador de rutas.
- No crear tablas puente `route_species`.

## Evolución futura

En una fase posterior se podrá estudiar una integración contextual entre módulos, pero solo después de tener ambos catálogos completos, normalizados y validados de forma independiente.

## Resultado de producto

### Rutas
**Localidad → Ruta → Mapa → GPX → Navegación.**

### Flora y Fauna
**Especie → Fotografía → Descripción → Hábitat → Distribución → Conservación.**