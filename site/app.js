const header = document.querySelector('[data-header]');
const menu = document.querySelector('[data-menu]');
const nav = document.querySelector('#main-nav');
const year = document.querySelector('[data-year]');

const onScroll = () => {
  header?.classList.toggle('scrolled', window.scrollY > 20);
};

window.addEventListener('scroll', onScroll, { passive: true });
onScroll();

menu?.addEventListener('click', () => {
  const open = nav?.classList.toggle('open') ?? false;
  menu.setAttribute('aria-expanded', String(open));
});

nav?.querySelectorAll('a').forEach((link) => {
  link.addEventListener('click', () => {
    nav.classList.remove('open');
    menu?.setAttribute('aria-expanded', 'false');
  });
});
if (year) year.textContent = new Date().getFullYear();