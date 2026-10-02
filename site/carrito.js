(() => {
  'use strict';
  const STORAGE_KEY = 'espana-outdoor-store-cart-v2';
  const SHOPIFY_DOMAIN = 'outdoorspain.myshopify.com';
  const SHOPIFY_API_VERSION = '2026-10';
  const SHOPIFY_TOKEN = window.ESPANA_OUTDOOR_SHOPIFY_STOREFRONT_TOKEN || '';
  const endpoint = `https://${SHOPIFY_DOMAIN}/api/${SHOPIFY_API_VERSION}/graphql.json`;
  let cart = loadCart();
  let catalog = [];

  function loadCart() {
    try {
      const value = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
      return Array.isArray(value) ? value.filter(item => item?.variantId && Number.isInteger(item.qty) && item.qty > 0) : [];
    } catch (_) { return []; }
  }

  function saveCart() {
    try { localStorage.setItem(STORAGE_KEY, JSON.stringify(cart)); } catch (_) {}
  }

  function escapeHtml(value) {
    return String(value ?? '').replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#039;');
  }

  async function shopify(query, variables = {}) {
    if (!SHOPIFY_TOKEN) throw new Error('Shopify aún no está configurado en el despliegue.');
    const response = await fetch(endpoint, {
      method: 'POST',
      headers: {'Content-Type':'application/json','X-Shopify-Storefront-Access-Token':SHOPIFY_TOKEN},
      body: JSON.stringify({query, variables})
    });
    if (!response.ok) throw new Error(`Shopify HTTP ${response.status}`);
    const body = await response.json();
    if (body.errors?.length) throw new Error(body.errors.map(error => error.message).join('; '));
    return body.data;
  }

  async function loadProducts() {
    const query = `query Products { products(first:100, sortKey:TITLE) { nodes { id title availableForSale featuredImage { url altText } variants(first:1) { nodes { id availableForSale price { amount currencyCode } } } } } }`;
    const data = await shopify(query);
    catalog = (data.products.nodes || [])
      .filter(product => product.availableForSale && product.variants.nodes.length && product.variants.nodes[0].availableForSale)
      .map(product => ({
        id: product.id,
        variantId: product.variants.nodes[0].id,
        name: product.title,
        image: product.featuredImage?.url || '',
        alt: product.featuredImage?.altText || product.title,
        price: Number(product.variants.nodes[0].price.amount),
        currency: product.variants.nodes[0].price.currencyCode || 'EUR'
      }));
  }

  function money(amount, currency = 'EUR') {
    return new Intl.NumberFormat('es-ES', {style:'currency', currency}).format(amount);
  }

  function setStatus(message, error = false) {
    const element = document.querySelector('#cart-status');
    if (!element) return;
    element.textContent = message || '';
    element.classList.toggle('cart-error', error);
    element.hidden = !message;
  }

  function render() {
    const root = document.querySelector('#cart-content');
    if (!root) return;
    const lines = cart.map(line => ({line, product: catalog.find(product => product.variantId === line.variantId)})).filter(item => item.product);

    if (!lines.length) {
      root.innerHTML = `<div class="cart-card cart-empty"><div class="cart-empty-mark">+</div><h2>Tu carrito está vacío</h2><p>Añade productos desde la tienda y volverán a aparecer aquí.</p><a class="button button-gold" href="./tienda.html">Seguir comprando</a></div>`;
      return;
    }

    const total = lines.reduce((sum, item) => sum + item.product.price * item.line.qty, 0);
    const count = lines.reduce((sum, item) => sum + item.line.qty, 0);
    root.innerHTML = `<div class="cart-card">${lines.map(({line, product}) => `<article class="cart-line"><img src="${escapeHtml(product.image)}" alt="${escapeHtml(product.alt)}"><div><h2>${escapeHtml(product.name)}</h2><div class="cart-line-price">${money(product.price, product.currency)} por unidad</div><div class="cart-line-actions"><div class="cart-qty"><button type="button" data-minus="${escapeHtml(line.variantId)}" aria-label="Reducir cantidad">−</button><span>${line.qty}</span><button type="button" data-plus="${escapeHtml(line.variantId)}" aria-label="Aumentar cantidad">+</button></div><button class="cart-remove" type="button" data-remove="${escapeHtml(line.variantId)}">Quitar</button></div></div><strong class="cart-line-total">${money(product.price * line.qty, product.currency)}</strong></article>`).join('')}</div><aside class="cart-summary"><h2>Resumen</h2><div class="cart-summary-row"><span>Productos</span><strong>${count}</strong></div><div class="cart-summary-total"><span>Total</span><span>${money(total)}</span></div><button type="button" class="button button-gold" data-checkout>Ir al checkout</button><small>El pago se completa en el checkout seguro de Shopify.</small><a class="cart-continue" href="./tienda.html">← Seguir comprando</a></aside>`;

    root.querySelectorAll('[data-minus]').forEach(button => button.addEventListener('click', () => changeQty(button.dataset.minus, -1)));
    root.querySelectorAll('[data-plus]').forEach(button => button.addEventListener('click', () => changeQty(button.dataset.plus, 1)));
    root.querySelectorAll('[data-remove]').forEach(button => button.addEventListener('click', () => removeItem(button.dataset.remove)));
    root.querySelector('[data-checkout]')?.addEventListener('click', checkout);
  }

  function changeQty(variantId, delta) {
    const item = cart.find(line => line.variantId === variantId);
    if (!item) return;
    item.qty += delta;
    if (item.qty <= 0) cart = cart.filter(line => line.variantId !== variantId);
    saveCart();
    setStatus('');
    render();
  }

  function removeItem(variantId) {
    cart = cart.filter(line => line.variantId !== variantId);
    saveCart();
    setStatus('');
    render();
  }

  async function checkout() {
    if (!cart.length) return;
    const button = document.querySelector('[data-checkout]');
    if (button) { button.disabled = true; button.textContent = 'Preparando…'; }
    setStatus('Preparando el checkout…');
    try {
      const data = await shopify(`mutation CartCreate($input: CartInput!) { cartCreate(input: $input) { cart { checkoutUrl } userErrors { field message } } }`, {
        input: {lines: cart.map(line => ({merchandiseId: line.variantId, quantity: line.qty}))}
      });
      const result = data.cartCreate;
      if (result.userErrors?.length) throw new Error(result.userErrors.map(error => error.message).join('; '));
      if (!result.cart?.checkoutUrl) throw new Error('Shopify no devolvió checkoutUrl.');
      window.location.href = result.cart.checkoutUrl;
    } catch (error) {
      setStatus(`No se pudo abrir el checkout: ${error.message}`, true);
      if (button) { button.disabled = false; button.textContent = 'Ir al checkout'; }
    }
  }

  document.addEventListener('DOMContentLoaded', async () => {
    try {
      await loadProducts();
      cart = cart.filter(line => catalog.some(product => product.variantId === line.variantId));
      saveCart();
      render();
    } catch (error) {
      console.error(error);
      setStatus(error.message, true);
      render();
    }
  }, {once:true});
})();
