const header = document.querySelector('[data-header]');
const menu = document.querySelector('[data-menu]');
const nav = document.querySelector('#main-nav');
const year = document.querySelector('[data-year]');

const onScroll = () => {
  header?.classList.toggle('scrolled', window.scrollY > 24);
};
window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

const current = window.location.pathname.split('/').pop() || 'index.html';
nav?.querySelectorAll('a[href]').forEach((link) => {
  const href = link.getAttribute('href') || '';
  if (href.endsWith(current)) {
    link.setAttribute('aria-current', 'page');
  }
  link.addEventListener('click', () => {
    nav.classList.remove('open');
    menu?.setAttribute('aria-expanded', 'false');
  });
});

menu?.addEventListener('click', () => {
  const open = nav?.classList.toggle('open') ?? false;
  menu.setAttribute('aria-expanded', String(open));
});

if (year) year.textContent = new Date().getFullYear();
