# España Outdoor — Catálogo definitivo de assets

**Versión:** 1.0  
**Estado:** bloqueado como especificación de producción  
**Regla:** una referencia visual no se convierte automáticamente en un asset final.

## 1. Estados

- **READY** — asset existente y apto para integración, con procedencia/licencia documentada.
- **DIRECTION_ONLY** — sirve para fijar dirección artística; no debe tratarse como asset final.
- **REVIEW_REQUIRED** — existe, pero falta acreditar procedencia, licencia, calidad o adecuación a producción.
- **MISSING** — debe producirse/adquirirse antes de cerrar la pantalla correspondiente.

## 2. Catálogo maestro

| ID | Categoría | Asset / familia | Ruta | Estado | Requisito de producción |
|---|---|---|---|---|---|
| SPLASH-HERO-01 | Hero Splash | Fotografía hero principal de naturaleza española | `assets/visuals/` | **MISSING** | Fotografía licenciable/propia, composición vertical, sujeto limpio para overlay de marca, exportación optimizada WebP/AVIF + fallback JPG/PNG |
| ROUTE-PHOTO-01 | Rutas | Fotografías de rutas y paisajes | `assets/landscapes/` | **REVIEW_REQUIRED** | Procedencia y licencia por imagen; recorte consistente; versiones retina |
| NATURE-PHOTO-01 | Naturaleza | Flora/fauna | `assets/flora_fauna/` | **REVIEW_REQUIRED** | Procedencia/licencia documentada; mantener taxonomía y nombre de especie separados del recurso visual |
| BG-01 | Fondos | Fondos de aplicación | `assets/backgrounds/` | **DIRECTION_ONLY** | Sustituir cualquier fondo provisional por versión final coherente con la biblia visual |
| BRAND-01 | Logotipo | Marca España Outdoor | `assets/brand/espana_outdoor_mark.svg` | **READY** | Mantener SVG vectorial; no rasterizar como fuente maestra |
| ICON-01 | Iconografía | Iconos funcionales | `assets/visuals/icons/` | **READY** | SVG, geometría y stroke coherentes; no introducir iconos alternativos sin actualizar el catálogo |
| HERO-02 | Hero secundarios | Rutas, mapa, naturaleza, offline, rescate, seguridad, alertas, perfil, etc. | `assets/visuals/hero_*.svg` | **DIRECTION_ONLY** | Son referencias vectoriales de dirección; no sustituyen fotografía premium definitiva cuando la pantalla requiera fotografía |
| MAP-01 | Estado de mapa | Estilo cartográfico offline | `assets/maps/offline_style.json` | **READY** | El estilo es parte del sistema de mapa; PMTiles son datos y no assets visuales de interfaz |
| MAP-02 | Estados de mapa | Tiles/PMTiles, overlays, estados online/offline/error | `assets/maps/` + infraestructura PMTiles | **READY / INFRA** | No almacenar el PMTiles de producción en Git; consumirlo desde R2/endpoint oficial con Range Requests |
| NAV-01 | Navegación | Controles, orientación, ubicación, rutas, rescate | `assets/visuals/icons/` | **READY** | Usar únicamente el set catalogado y los componentes fijados por el sistema visual |
| PHOTO-ATLAS-01 | Fotografías | Atlas fotográfico provisional | `assets/visuals/outdoor_photo_atlas.jpg` | **REVIEW_REQUIRED** | No utilizar en producción hasta documentar procedencia/licencia y separar sus imágenes en recursos finales optimizados |

## 3. Assets existentes actualmente

### Marca

- `assets/brand/espana_outdoor_mark.svg`

### Fondos existentes

- `assets/backgrounds/bg_home.svg`
- `assets/backgrounds/bg_map.svg`
- `assets/backgrounds/bg_navigation.svg`
- `assets/backgrounds/bg_offline.svg`
- `assets/backgrounds/bg_profile.svg`
- `assets/backgrounds/bg_rescue.svg`
- `assets/backgrounds/bg_routes.svg`
- `assets/backgrounds/bg_safety.svg`

**Nota:** estos recursos quedan registrados, pero no se consideran automáticamente finales. Deben respetar exactamente la biblia visual antes de marcarse READY.

### Heroes vectoriales existentes

- `hero_alerts.svg`
- `hero_map.svg`
- `hero_natura.svg`
- `hero_offline.svg`
- `hero_pets.svg`
- `hero_plans.svg`
- `hero_profile.svg`
- `hero_rescue.svg`
- `hero_routes.svg`
- `hero_safety.svg`
- `hero_wildlife.svg`

Ruta: `assets/visuals/`.

Estos archivos quedan explícitamente clasificados como **DIRECTION_ONLY** hasta que exista una decisión final de uso. No deben presentarse como fotografía premium definitiva.

### Paisaje / naturaleza existentes

- `assets/landscapes/cazorla_land05.svg`
- `assets/landscapes/donana_land07.svg`
- `assets/landscapes/ordesa_land04.svg`
- `assets/landscapes/picos_europa_land01.svg`
- `assets/landscapes/pirineos_land02.svg`
- `assets/landscapes/sierra_nevada_land03.svg`
- `assets/landscapes/teide_land06.svg`
- `assets/flora_fauna/flora/spanish_juniper.svg`
- `assets/flora_fauna/fauna/iberian_ibex.svg`

Estos recursos son útiles como iconografía/ilustración de apoyo, pero no sustituyen las fotografías finales cuando una pantalla requiera fotografía real.

## 4. Reglas de licenciamiento

1. Ninguna fotografía entra en producción sin procedencia identificable.
2. Para cada fotografía final se debe conservar: autor/proveedor, fuente, licencia, fecha de adquisición y restricciones de uso.
3. No usar imágenes encontradas en buscadores como si fueran libres de derechos.
4. Los recursos generados por IA solo pueden utilizarse como assets finales cuando la licencia del servicio y los términos aplicables permitan el uso comercial previsto y quede registrada la procedencia.
5. Los assets de referencia generados durante diseño no se incorporan automáticamente al producto.
6. OSM/PMTiles y fotografía son categorías independientes: la atribución cartográfica no sustituye la licencia fotográfica.

## 5. Especificaciones de exportación

### Fotografía

- Maestro: resolución original conservada fuera de la app.
- App: WebP/AVIF cuando el pipeline lo permita.
- Fallback: JPEG optimizado.
- Sin metadatos EXIF innecesarios en distribución.
- Compresión revisada visualmente antes de integrar.
- Recortes definidos por pantalla, no reutilizar indiscriminadamente una misma imagen.

### SVG

- SVG limpio y válido.
- Sin fuentes externas.
- Sin scripts ni recursos remotos embebidos.
- ViewBox definido.
- Colores compatibles con la paleta fijada.

### Iconografía

- Una sola familia visual.
- Tamaños base definidos por el sistema de componentes.
- Estados normal/activo/deshabilitado/error deben resolverse mediante el componente, no mediante duplicación arbitraria de iconos.

## 6. Criterio de cierre

El catálogo no se considera cerrado mientras exista cualquiera de estos bloqueos:

- `SPLASH-HERO-01` en MISSING.
- Una fotografía de producción en REVIEW_REQUIRED sin licencia/procedencia.
- Un asset usado por una pantalla que no figure en este catálogo.
- Un hero de referencia usado como asset definitivo sin aprobación explícita.
- Iconografía duplicada o de familias visuales diferentes.

## 7. Próximo asset prioritario

**SPLASH-HERO-01**: seleccionar/producir una fotografía hero definitiva y licenciable. Después se documentará su procedencia y se integrará únicamente en la pantalla Splash fijada por el layout V1.0.
