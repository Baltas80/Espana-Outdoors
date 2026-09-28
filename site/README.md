# España Outdoor — Web

Sitio web público independiente de la aplicación Flutter.

## Objetivo

Presentación pública de España Outdoor, contenidos de producto, cartografía, rutas, naturaleza y seguridad. La web no modifica la arquitectura de la app móvil.

## Despliegue

La carpeta `site/` está pensada para un hosting estático (Cloudflare Pages, GitHub Pages u otro equivalente).

- Directorio de salida/publicación: `site`
- Sin build step obligatorio.
- Dominio previsto: `https://espanaoutdoor.es`

## Recursos

Los recursos visuales se mantienen dentro de `site/assets` para que la web no dependa de un CDN externo para su identidad visual.

## Siguiente fase

1. Conectar navegación real a mapas/servicios públicos cuando estén publicados.
2. Añadir contenidos territoriales indexables.
3. Integrar métricas respetuosas con privacidad, solo si se decide producto.
4. Conectar enlaces oficiales de descarga de la aplicación cuando las publicaciones sean definitivas.

<!-- Deployment trigger: GitHub Pages deployment verification. -->

- Sección pública: `flora-fauna.html` con catálogo inicial de biodiversidad.
