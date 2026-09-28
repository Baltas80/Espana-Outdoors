# España Outdoor — plan unificado de datos geográficos y biodiversidad

## Decisión
No depender de una única web externa. Construir una capa de datos propia alimentada por fuentes oficiales y abiertas, guardando en cada registro origen, identificador, fecha, licencia, versión y URL de fuente.

## Catálogo biodiversidad
EIDOS / MITECO → autoridad base para taxonomía, descripción, distribución y conservación.
GBIF-Spain → checklists especializadas, especialmente flora vascular y otros grupos.
Fuentes autonómicas → completar detalle territorial cuando exista información más reciente o precisa.

## Catálogo rutas
CNIG/FEDME → senderos homologados y tracks GPX/KML/SHP.
CNIG/MAPA Caminos Naturales → red de Caminos Naturales y etapas.
Datos abiertos autonómicos → rutas locales oficiales.
OpenStreetMap → cobertura complementaria y rutas locales.

## Unión clave
localidad → ruta → geometría → espacio natural → especies potencialmente presentes → puntos de interés.
La relación especie-ruta debe ser espacial/ecológica; nunca afirmar que una especie está garantizado que vaya a verse.

## Tablas de producto
Localidad: municipio, provincia, comunidad, coordenadas, comarca, espacios naturales próximos.
Ruta: nombre, código, tipo, distancia, desnivel, duración, dificultad, geometría, GPX, operador, estado y fuente.
Especie: nombre común, nombre científico, taxonomía, descripción, hábitat, distribución, conservación, fotografía y licencia.
Relación ruta-especie: route_id, taxon_id, relationship, source, confidence, seasonality, notes.

relationship puede ser: documented_nearby, habitat_suitable u official_distribution_overlap.

## Alcance
No existe una única lista estática que pueda llamarse literalmente todas las especies de España con el mismo nivel de actualización en todos los grupos. EIDOS es la base oficial integrada, pero MITECO reconoce que el detalle puede variar por grupo y que las comunidades autónomas pueden disponer de información adicional.

## Fases
Fase A: importar rutas FEDME y Caminos Naturales, normalizar localidades, crear taxonomía maestra e índice espacial.
Fase B: selector localidad, lista de rutas, ficha, mapa, perfil de elevación, GPX y flora/fauna del entorno.
Fase C: PMTiles, geometrías offline, índice local, fichas de especies, imágenes optimizadas y sincronización incremental.

## Resultado
La web será el catálogo editorial. La app será el producto operativo. La base geográfica será común a ambos.