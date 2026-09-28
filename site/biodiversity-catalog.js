(() => {
  const results = document.querySelector('[data-bio-results]');
  const tabs = [...document.querySelectorAll('[data-bio-filter]')];
  const search = document.querySelector('[data-bio-search]');
  const count = document.querySelector('[data-bio-count]');
  if (!results) return;

  let species = [];
  let activeFilter = 'all';

  const escapeHtml = (value) => String(value ?? '').replace(/[&<>"']/g, (char) => ({
    '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#039;'
  }[char]));

  const render = () => {
    const term = String(search?.value || '').trim().toLocaleLowerCase('es-ES');
    const filtered = species.filter((item) => {
      const typeOk = activeFilter === 'all' || item.type === activeFilter || item.group === activeFilter;
      const haystack = [item.common_name, item.scientific_name, item.habitat, item.zone, item.description].join(' ').toLocaleLowerCase('es-ES');
      return typeOk && (!term || haystack.includes(term));
    });

    if (count) count.textContent = String(filtered.length);

    results.innerHTML = filtered.length ? filtered.map((item) => `
      <article class="bio-card">
        <div class="bio-photo">
          <img src="${escapeHtml(item.image)}" alt="${escapeHtml(item.common_name)} — ${escapeHtml(item.scientific_name)}" loading="lazy" decoding="async">
          <span class="bio-badge">${escapeHtml(item.type === 'flora' ? 'Flora' : 'Fauna')}</span>
        </div>
        <div class="bio-body">
          <h2>${escapeHtml(item.common_name)}</h2>
          <span class="bio-scientific">${escapeHtml(item.scientific_name)}</span>
          <p>${escapeHtml(item.description)}</p>
          <div class="bio-meta">
            <div><strong>Hábitat</strong><span>${escapeHtml(item.habitat)}</span></div>
            <div><strong>Zona</strong><span>${escapeHtml(item.zone)}</span></div>
          </div>
          <span class="bio-tag">${escapeHtml(item.tag)}</span>
          <div class="bio-source">
            Fotografía: ${escapeHtml(item.credit)}.
            <a href="${escapeHtml(item.source_url)}" target="_blank" rel="noopener noreferrer">Ver fuente y licencia →</a>
          </div>
        </div>
      </article>`).join('')
      : '<div class="bio-empty"><strong>No hay coincidencias.</strong><span>Prueba con otra especie, hábitat o zona.</span></div>';
  };

  tabs.forEach((tab) => tab.addEventListener('click', () => {
    activeFilter = tab.dataset.bioFilter || 'all';
    tabs.forEach((item) => {
      const active = item === tab;
      item.classList.toggle('is-active', active);
      item.setAttribute('aria-pressed', String(active));
    });
    render();
  }));

  search?.addEventListener('input', render);

  fetch('./data/species-catalog.json', { cache: 'no-store' })
    .then((response) => response.ok ? response.json() : Promise.reject(new Error('species catalog unavailable')))
    .then((payload) => {
      species = Array.isArray(payload.species) ? payload.species : [];
      if (count) count.textContent = String(species.length);
      render();
    })
    .catch(() => {
      results.innerHTML = '<div class="bio-empty"><strong>No se ha podido cargar el catálogo.</strong><span>Revisa la conexión y vuelve a intentarlo.</span></div>';
    });
})();