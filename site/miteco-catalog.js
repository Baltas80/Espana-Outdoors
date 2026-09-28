(() => {
  const panel = document.querySelector('[data-miteco-panel]');
  if (!panel) return;

  const status = panel.querySelector('[data-miteco-status]');
  const updated = panel.querySelector('[data-miteco-updated]');
  const datasetList = panel.querySelector('[data-miteco-datasets]');
  const apiLink = panel.querySelector('[data-miteco-api]');
  const dot = panel.querySelector('.miteco-status-dot');

  const escapeHtml = (value) => String(value ?? '').replace(/[&<>"]/g, (char) => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'
  }[char]));

  const render = (payload) => {
    const datasets = Array.isArray(payload.datasets) ? payload.datasets : [];
    const live = payload.status === 'live';

    if (status) {
      status.textContent = live
        ? 'Conectado a la API CKAN de MITECO'
        : 'Última sincronización disponible; modo de respaldo';
      status.dataset.state = live ? 'live' : 'fallback';
      if (dot) dot.dataset.state = live ? 'live' : 'fallback';
    }

    if (updated) {
      updated.textContent = payload.generated_at
        ? `Sincronizado: ${payload.generated_at}`
        : 'Sin sincronización registrada';
    }

    if (apiLink && payload.api_base) {
      apiLink.href = payload.api_base + '/package_search?q=Distribución%20de%20especies';
    }

    if (datasetList) {
      datasetList.innerHTML = datasets.slice(0, 4).map((item) => {
        const resources = Array.isArray(item.resources) ? item.resources.filter(r => r.url).slice(0, 3) : [];
        const links = resources.map(r =>
          `<a href="${escapeHtml(r.url)}" target="_blank" rel="noopener noreferrer">${escapeHtml(r.format || 'Recurso')} →</a>`
        ).join('');
        return `
          <article class="miteco-dataset">
            <div>
              <strong>${escapeHtml(item.title || 'Dataset MITECO')}</strong>
              <span>${escapeHtml(item.organization || 'Ministerio para la Transición Ecológica y el Reto Demográfico')}</span>
            </div>
            <div class="miteco-dataset-links">
              ${links}
              ${item.catalog_url ? `<a href="${escapeHtml(item.catalog_url)}" target="_blank" rel="noopener noreferrer">Ficha →</a>` : ''}
            </div>
          </article>`;
      }).join('');
    }
  };

  fetch('./data/miteco-catalog.json', { cache: 'no-store' })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error('MITECO catalog unavailable')))
    .then(render)
    .catch(() => {
      if (status) {
        status.textContent = 'Datos oficiales MITECO disponibles mediante las fichas de fuente';
        status.dataset.state = 'fallback';
        if (dot) dot.dataset.state = 'fallback';
      }
    });
})();
