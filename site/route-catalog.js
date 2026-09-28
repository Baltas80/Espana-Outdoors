(() => {
  const results = document.querySelector('[data-route-results]');
  const place = document.querySelector('[data-route-place]');
  const type = document.querySelector('[data-route-type]');
  const loop = document.querySelector('[data-route-loop]');
  const count = document.querySelector('[data-route-count]');
  const searchButton = document.querySelector('[data-route-search]');
  if (!results) return;

  let routes = [];
  const normalize = (value) => (value || '').toLocaleLowerCase('es-ES').normalize('NFD').replace(/[\u0300-\u036f]/g, '');

  const render = () => {
    const q = normalize(place?.value);
    const typeValue = type?.value || 'all';
    const loopValue = loop?.value || 'all';

    const filtered = routes.filter((route) => {
      const haystack = normalize([route.name, route.code, route.locality, route.province, route.community].join(' '));
      const placeOk = !q || haystack.includes(q);
      const typeOk = typeValue === 'all' || route.type === typeValue;
      const loopOk = loopValue === 'all' || route.loop === loopValue;
      return placeOk && typeOk && loopOk;
    });

    if (count) count.textContent = String(filtered.length);
    results.innerHTML = filtered.length ? filtered.map((route) => `
      <article class="route-result-card">
        <div class="route-result-top"><span class="route-code">${route.code}</span><span class="route-kind">${route.loop === 'circular' ? 'Circular' : 'Lineal'}</span></div>
        <h3>${route.name}</h3>
        <p class="route-location">${route.locality} · ${route.community}</p>
        <div class="route-metrics">
          <div><strong>${route.distance_km} km</strong><span>distancia</span></div>
          <div><strong>+${route.ascent_m} m</strong><span>desnivel</span></div>
          <div><strong>${route.duration}</strong><span>tiempo</span></div>
        </div>
        <div class="route-result-footer">
          <span>Fuente: ${route.source_name}</span>
          <a href="${route.source_url}" target="_blank" rel="noopener noreferrer">Ver ficha oficial →</a>
        </div>
      </article>
    `).join('') : '<div class="route-empty"><strong>No hay coincidencias en la muestra local.</strong><span>Prueba otra localidad o utiliza el buscador oficial FEDME para consultar el catálogo completo.</span></div>';
  };

  fetch('./data/routes-catalog.json', { cache: 'no-store' })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error('route catalog unavailable')))
    .then((payload) => { routes = Array.isArray(payload.routes) ? payload.routes : []; render(); })
    .catch(() => {
      results.innerHTML = '<div class="route-empty"><strong>No se ha podido cargar el catálogo local.</strong><span>El buscador oficial FEDME sigue disponible en el enlace de arriba.</span></div>';
    });

  searchButton?.addEventListener('click', render);
  place?.addEventListener('input', render);
  type?.addEventListener('change', render);
  loop?.addEventListener('change', render);
})();