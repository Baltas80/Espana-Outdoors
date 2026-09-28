# Catálogo maestro de biodiversidad — fuentes y estrategia

## Objetivo
Construir el catálogo de flora y fauna de España Outdoor con una fuente maestra de taxonomía, distribución y conservación, separando esos datos de las fotografías y del contenido editorial.

## Fuente maestra: EIDOS / MITECO
- URL: https://www.miteco.gob.es/es/biodiversidad/servicios/banco-datos-naturaleza/eidos_acceso.html
- Información oficial sobre especies silvestres presentes en España.
- Estándar: Plinian Core.
- Uso: identidad taxonómica, nombres, descripción, distribución oficial, estado legal y conservación.
- MITECO indica que EIDOS reúne información de Atlas, Libros Rojos, catálogos, inventarios e informes.
- MITECO también advierte que las comunidades autónomas pueden disponer de información más actualizada o detallada.

## Complemento de flora vascular
GBIF-Spain — Lista de táxones de la flora vascular española
- URL: https://ipt.gbif.es/resource?r=taxonesfloraespanola
- Versión consultada: 1.16, publicada en 2025.
- 10.489 registros.
- Cobertura: Península, Baleares, Canarias, Ceuta y Melilla.
- Incluye especies, subespecies, géneros y familias; no híbridos.
- Licencia: CC BY 4.0.
- Formato: Darwin Core Archive.

## Complemento de mamíferos
SECEM — Checklist of the Mammal Species of Spain 2025
- URL: https://ipt.gbif.es/resource?r=secem-checklist-mammal-es
- Versión 2.0 publicada en 2026.
- Licencia: CC BY 4.0.
- Cobertura: territorio continental, archipiélagos, Ceuta y Melilla y demarcaciones marinas españolas.

## Distribución geográfica
MITECO — Distribución de especies / EIDOS
- Catálogo: https://catalogo.datosabiertos.miteco.gob.es/catalogo/es/dataset/fc21c1a5-4c02-4157-9d2f-9a2cd200f908
- WMS: https://wms.mapama.gob.es/sig/Biodiversidad/SD_EIDOS
- Uso: distribución espacial oficial por especie.

## Modelo interno propuesto
taxon: taxon_id, scientific_name, common_name_es, rank, kingdom, phylum, class, order, family, genus, source, source_id, source_version, updated_at.
species_profile: taxon_id, summary_es, habitat, ecology, conservation_status, legal_status, endemic, invasive, editorial_status, content_version.
species_distribution: taxon_id, geometry_source, grid_reference, autonomous_community, province, source, precision, updated_at.
species_media: taxon_id, media_url, thumbnail_url, author, license, source_url, credit_text, verified_at.

## Regla editorial
Cada ficha debe separar dato científico, fuente, licencia, texto editorial España Outdoor y fotografía.

## Protección de especies sensibles
No mostrar coordenadas exactas de especies amenazadas o localizaciones sensibles de reproducción o nidificación. Usar una precisión pública apropiada a cada especie.

## Resultado esperado
Flora y Fauna → Todo / Fauna / Flora / Mamíferos / Aves / Reptiles / Anfibios / Peces continentales / Invertebrados / Flora vascular / Flora no vascular.
Búsqueda por especie, localidad, ecosistema, parque, ruta y comunidad autónoma.

## Fuentes
- MITECO EIDOS: https://www.miteco.gob.es/es/biodiversidad/servicios/banco-datos-naturaleza/eidos_acceso.html
- MITECO IEET: https://www.miteco.gob.es/es/biodiversidad/temas/inventarios-nacionales/inventario-especies-terrestres.html
- GBIF-Spain flora vascular: https://ipt.gbif.es/resource?r=taxonesfloraespanola
- SECEM mammals: https://ipt.gbif.es/resource?r=secem-checklist-mammal-es

## Integración API MITECO
El sitio web mantiene una capa de sincronización de metadatos mediante la API CKAN oficial del Portal de Datos Abiertos MITECO:
- API base: https://catalogo.datosabiertos.miteco.gob.es/catalogo/api/3/action
- Descubrimiento: `package_search` para localizar datasets relevantes.
- Fichas: `package_show` para obtener recursos, formatos y URLs.
- El despliegue de GitHub Pages genera `site/data/miteco-catalog.json` para que el frontend consulte una copia local rápida y resiliente.
- La cartografía EIDOS se mantiene como fuente espacial oficial mediante sus servicios WMS/WFS.

La capa web no realiza consultas directas a MITECO en cada visita: se sincroniza durante el despliegue para evitar dependencia de latencia o disponibilidad externa en tiempo de navegación.
