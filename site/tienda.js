(() => {
  'use strict';

  const STORAGE_KEY = 'espana-outdoor-store-cart-v1';
  const catalog = [];
  const categories = [
    ['mochilas', 'Mochilas'],
    ['calzado', 'Calzado'],
    ['ropa', 'Ropa outdoor'],
    ['trekking', 'Trekking'],
    ['camping', 'Camping'],
    ['hidratacion', 'Hidratación'],
    ['navegacion', 'Navegación'],
    ['seguridad', 'Seguridad'],
    ['iluminacion', 'Iluminación'],
    ['accesorios', 'Accesorios']
  ];

  const state = {
    category: 'all',
    query: '',
    sort: 'featured',
    cart: loadCart()
  };

  function loadCart() {
    try {
      const parsed = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
      return Array.isArray(parsed) ? parsed.filter(item => item && item.id && Number.isInteger(item.qty) && item.qty > 0) : [];
    } catch (_) {
      return [];
    }
  }

  function saveCart() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state.cart)); } catch (_) {}
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#039;');
  }

  function renderCatalog() {
    const host = document.querySelector('#catalogo');
    if (!host) return;

    const categoryButtons = categories.map(([id, label]) => `
      <button class="store-filter ${state.category === id ? 'is-active' : ''}" type="button" data-store-category="${id}">${escapeHtml(label)}</button>
    `).join('');

    const empty = catalog.length === 0;
    host.className = 'store-catalog';
    host.innerHTML = `
      <div class="store-catalog-head">
        <div>
          <p class="kicker">Catálogo</p>
          <h2>Productos seleccionados</h2>
          <p class="store-catalog-intro">La infraestructura comercial ya está preparada. Los productos reales se incorporarán cuando estén validados proveedor, precio, disponibilidad, condiciones de entrega y destino del enlace de compra.</p>
        </div>
        <button class="store-cart-button" type="button" data-store-cart aria-controls="store-cart" aria-expanded="false">
          Carrito <span data-cart-count>0</span>
        </button>
      </div>
      <div class="store-toolbar" role="region" aria-label="Filtros de tienda">
        <div class="store-filters" aria-label="Categorías">
          <button class="store-filter ${state.category === 'all' ? 'is-active' : ''}" type="button" data-store-category="all">Todo</button>
          ${categoryButtons}
        </div>
        <label class="store-search"><span class="sr-only">Buscar productos</span><input type="search" data-store-search placeholder="Buscar en la tienda…" value="${escapeHtml(state.query)}"></label>
        <label class="store-sort"><span class="sr-only">Ordenar</span><select data-store-sort><option value="featured" ${state.sort === 'featured' ? 'selected' : ''}>Destacados</option><option value="price-asc" ${state.sort === 'price-asc' ? 'selected' : ''}>Precio: menor a mayor</option><option value="price-desc" ${state.sort === 'price-desc' ? 'selected' : ''}>Precio: mayor a menor</option></select></label>
      </div>
      <div class="store-product-grid" data-store-products>
        ${empty ? `
          <article class="store-empty store-catalog-empty">
            <span class="store-empty-mark" aria-hidden="true">+</span>
            <h2>Primer catálogo comercial pendiente de validación</h2>
            <p>No mostramos precios, stock ni enlaces ficticios. El siguiente paso es cargar proveedores reales y publicar únicamente productos comprobados.</p>
            <a class="button button-small" href="./contacto.html?asunto=proveedores">Proponer proveedor</a>
          </article>
        ` : renderProducts()}
      </div>
      <aside id="store-cart" class="store-cart" hidden aria-label="Carrito">
        <div class="store-cart-head"><strong>Tu carrito</strong><button type="button" data-store-close-cart aria-label="Cerrar carrito">×</button></div>
        <div data-store-cart-items></div>
        <div class="store-cart-foot"><strong>Total</strong><strong data-store-cart-total>0,00 €</strong><button type="button" class="button button-gold" data-store-checkout disabled>Checkout pendiente</button><small>El pago se activará cuando se conecte un proveedor de checkout verificado.</small></div>
      </aside>
    `;

    bindCatalogEvents(host);
    updateCartUi(host);
  }

  function renderProducts() {
    const filtered = catalog
      .filter(item => state.category === 'all' || item.category === state.category)
      .filter(item => !state.query || `${item.name} ${item.description}`.toLowerCase().includes(state.query.toLowerCase()))
      .slice();

    filtered.sort((a, b) => {
      if (state.sort === 'price-asc') return a.price - b.price;
      if (state.sort === 'price-desc') return b.price - a.price;
      return (a.featured ? 0 : 1) - (b.featured ? 0 : 1);
    });

    if (!filtered.length) return '<div class="store-empty store-catalog-empty"><h2>Sin resultados</h2><p>Prueba otra categoría o término de búsqueda.</p></div>';

    return filtered.map(item => `
      <article class="store-product-card">
        <div class="store-product-media"><img src="${escapeHtml(item.image)}" alt="${escapeHtml(item.name)}" loading="lazy"><span>${escapeHtml(item.badge || 'Selección')}</span></div>
        <div class="store-product-body"><small>${escapeHtml(item.vendor || 'Proveedor pendiente')}</small><h3>${escapeHtml(item.name)}</h3><p>${escapeHtml(item.description)}</p><div class="store-product-foot"><strong>${new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(item.price)}</strong><button type="button" class="button button-small" data-add-product="${escapeHtml(item.id)}">Añadir</button></div></div>
      </article>
    `).join('');
  }

  function bindCatalogEvents(host) {
    host.querySelectorAll('[data-store-category]').forEach(button => button.addEventListener('click', () => {
      state.category = button.dataset.storeCategory;
      renderCatalog();
    }));

    const search = host.querySelector('[data-store-search]');
    if (search) search.addEventListener('input', event => { state.query = event.target.value; renderCatalog(); });

    const sort = host.querySelector('[data-store-sort]');
    if (sort) sort.addEventListener('change', event => { state.sort = event.target.value; renderCatalog(); });

    host.querySelectorAll('[data-add-product]').forEach(button => button.addEventListener('click', () => addToCart(button.dataset.addProduct)));

    const cartButton = host.querySelector('[data-store-cart]');
    if (cartButton) cartButton.addEventListener('click', () => {
      const cart = host.querySelector('#store-cart');
      cart.hidden = false;
      cartButton.setAttribute('aria-expanded', 'true');
    });

    const closeCart = host.querySelector('[data-store-close-cart]');
    if (closeCart) closeCart.addEventListener('click', () => {
      const cart = host.querySelector('#store-cart');
      cart.hidden = true;
      host.querySelector('[data-store-cart]')?.setAttribute('aria-expanded', 'false');
    });
  }

  function addToCart(id) {
    const item = catalog.find(product => product.id === id);
    if (!item) return;
    const existing = state.cart.find(line => line.id === id);
    if (existing) existing.qty += 1;
    else state.cart.push({ id, qty: 1 });
    saveCart();
    const host = document.querySelector('#catalogo');
    if (host) updateCartUi(host);
  }

  function updateCartUi(host) {
    const count = state.cart.reduce((sum, line) => sum + line.qty, 0);
    const countNode = host.querySelector('[data-cart-count]');
    if (countNode) countNode.textContent = String(count);

    const itemsNode = host.querySelector('[data-store-cart-items]');
    const totalNode = host.querySelector('[data-store-cart-total]');
    if (!itemsNode || !totalNode) return;

    let total = 0;
    itemsNode.innerHTML = state.cart.map(line => {
      const product = catalog.find(item => item.id === line.id);
      if (!product) return '';
      total += product.price * line.qty;
      return `<div class="store-cart-line"><span>${escapeHtml(product.name)} × ${line.qty}</span><strong>${new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(product.price * line.qty)}</strong></div>`;
    }).join('') || '<p class="store-cart-empty">El carrito está vacío.</p>';
    totalNode.textContent = new Intl.NumberFormat('es-ES',{style:'currency',currency:'EUR'}).format(total);
  }

  document.addEventListener('DOMContentLoaded', renderCatalog, { once: true });
})();
