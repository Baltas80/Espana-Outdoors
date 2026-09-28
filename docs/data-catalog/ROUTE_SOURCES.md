# Catálogo maestro de rutas — fuentes y estrategia

## Objetivo
Construir un catálogo que permita: Localidad → rutas disponibles → ficha → mapa → GPX → navegación.

## Fuente principal: Senderos FEDME
Mi Senda FEDME: https://misendafedme.es/buscador-de-senderos/
Permite buscar por localidad, comunidad autónoma, tipo de sendero, tipo de recorrido, distancia, desnivel, tiempo estimado, espacios naturales protegidos y senderos europeos.

## Descarga oficial CNIG
https://centrodedescargas.cnig.es/CentroDescargas/senderos-fedme
- 6.923 ficheros visibles.
- GR, PR y SL homologados FEDME.
- GPX, KML y Shapefile.
- WGS84.
- Búsqueda por municipio y posición.
- Licencia indicada por CNIG: CC BY 4.0 FEDME.

## Fuente complementaria: Caminos Naturales
https://centrodedescargas.cnig.es/CentroDescargas/caminos-naturales
- 1.483 ficheros visibles.
- Más de 10.600 km de Caminos Naturales.
- GPX, KML y Shapefile.
- WGS84.
- Licencia indicada por CNIG: CC BY 4.0 MAPA.
Visor oficial: https://www.mapa.gob.es/caminos-naturales/

## Fuentes autonómicas
Usar datos.gob.es y los portales de datos abiertos de las comunidades y diputaciones para completar rutas locales y municipales.
Ejemplo verificado: Gipuzkoa publica rutas de senderismo en GPX.

## OpenStreetMap
OSM puede cubrir rutas locales que no estén en los catálogos anteriores.
Documentación: https://wiki.openstreetmap.org/wiki/ES:Tag:route%3Dhiking
Overpass: https://wiki.openstreetmap.org/wiki/ES:API_de_Overpass/Ejemplos_avanzados
Licencia: ODbL. Requiere atribución y condiciones específicas para bases derivadas.

## Wikiloc
https://www.wikiloc.com/
Útil para estudiar UX y proporcionar enlaces externos, pero no como fuente de ingestión automática. Wikiloc declara actualmente que no dispone de API pública por razones técnicas, legales y de privacidad.

## Arquitectura interna
route: route_id, source, source_id, name, ref, route_type, network, operator, description, distance_m, elevation_gain_m, elevation_loss_m, duration_min, difficulty, route_shape, start_point, end_point, municipality_id, province, autonomous_community, protected_area_id, license, source_url, source_updated_at, ingested_at, status.
route_segment: segment_id, route_id, stage_number, name, start_name, end_name, distance_m, geometry, gpx_uri, kml_uri.
route_place: localidad ↔ ruta.

## Normalización
Todas las fuentes deben convertirse a WGS84 / EPSG:4326. Después: simplificación para web, geometría completa para navegación, perfil de elevación, índice espacial y búsqueda por municipio y proximidad.

## Prioridad
P0: FEDME CNIG.
P0: Caminos Naturales CNIG.
P1: Datos abiertos autonómicos.
P1: OpenStreetMap.
P2: fuentes turísticas oficiales.
No ingestión automática desde plataformas sin API o licencia de reutilización compatible.

## Flujo definitivo
Fuente → descarga original → comprobación de licencia → parser GPX/KML/SHP → normalización → deduplicación → asociación localidad → asociación espacio protegido → cálculo de métricas → validación geométrica → base de datos → API → mapa España Outdoor → Valhalla.

## UX final
Comunidad → Provincia → Localidad → lista de rutas → filtros GR/PR/SL, circular/lineal, distancia, desnivel, dificultad, duración, actividad y espacio natural → ficha → mapa → perfil → GPX → navegación.

## Fuentes
- Mi Senda FEDME: https://misendafedme.es/buscador-de-senderos/
- CNIG Senderos FEDME: https://centrodedescargas.cnig.es/CentroDescargas/senderos-fedme
- CNIG Caminos Naturales: https://centrodedescargas.cnig.es/CentroDescargas/caminos-naturales
- Caminos Naturales MAPA: https://www.mapa.gob.es/caminos-naturales/
- Datos abiertos: https://datos.gob.es/
- OSM hiking routes: https://wiki.openstreetmap.org/wiki/ES:Tag:route%3Dhiking
- Wikiloc: https://www.wikiloc.com/