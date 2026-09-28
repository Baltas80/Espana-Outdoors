(() => {
  const params = new URLSearchParams(window.location.search);
  const id = params.get('id');
  const esc = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'
  }[char]));
  const $ = (selector) => document.querySelector(selector);
  const typeLabel = (route) => ({
    GR:'GR — Gran Recorrido', PR:'PR — Pequeño Recorrido', SL:'SL — Sendero Local',
    CN:'Camino Natural', PN:'Parque Nacional'
  }[route.type] || route.type_label || 'Ruta oficial');
  const set = (selector, value) => { const el=$(selector); if(el) el.textContent=value; };

  if (!id) {
    set('[data-route-name]', 'Ruta no especificada');
    return;
  }

  fetch('./data/routes-catalog.json', { cache:'default' })
    .then((r) => r.ok ? r.json() : Promise.reject(new Error('catalog unavailable')))
    .then((payload) => {
      const route = (payload.routes || []).find((item) => item.id === id);
      if (!route) throw new Error('route not found');

      document.title = \`España Outdoor — \${route.name || route.code || 'Ruta'}\`;
      set('[data-route-code]', route.code || 'Ruta');
      set('[data-route-name]', route.name || route.code || 'Ruta oficial');
      set('[data-route-location]', [route.locality, route.province, route.community].filter(Boolean).join(' · ') || 'Ubicación en la ficha oficial');
      set('[data-route-type-label]', typeLabel(route));
      set('[data-route-source-name]', route.source_name || 'Fuente oficial');

      document.querySelectorAll('[data-route-source-link]').forEach((link) => {
        link.href = route.catalog_url || route.source_url || '#';
      });

      const download = $('[data-route-download]');
      if (route.download_url && download) {
        download.hidden = false;
        download.href = route.download_url;
      }

      const metrics = $('[data-route-metrics]');
      if (!metrics) return;
      const items = [
        ['Distancia', route.distance_km != null ? \`\${route.distance_km} km\` : 'No publicada en este índice'],
        ['Desnivel +', route.ascent_m != null ? \`+\${route.ascent_m} m\` : 'No publicado en este índice'],
        ['Desnivel −', route.descent_m != null ? \`−\${route.descent_m} m\` : 'No publicado en este índice'],
        ['Duración', route.duration || 'No publicada en este índice'],
        ['Recorrido', route.loop === 'circular' ? 'Circular' : route.loop === 'lineal' ? 'Lineal' : 'Consultar ficha'],
        ['Fuente', route.source_name || 'Fuente oficial']
      ];
      metrics.innerHTML = items.map(([label,value]) =>
        \`<article class="route-detail-metric"><span>\${esc(label)}</span><strong>\${esc(value)}</strong></article>\`
      ).join('');
    })
    .catch(() => {
      set('[data-route-name]', 'Ruta no disponible');
      set('[data-route-location]', 'No hemos podido localizar esta ficha en el catálogo actual.');
    });
})();