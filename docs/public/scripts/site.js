// Haven marketing-site behavior.
// Loaded with `defer` from BaseLayout — DOM is parsed before this runs.

(function () {
  // 1) Scroll reveal — only attach when the user has not requested reduced motion.
  // The CSS in global.css keeps elements visible by default outside the
  // (prefers-reduced-motion: no-preference) block, so this observer is purely
  // the motion enhancement.
  if (window.matchMedia('(prefers-reduced-motion: no-preference)').matches) {
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target);
        }
      });
    }, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });

    document.querySelectorAll('.reveal').forEach(function (el) {
      observer.observe(el);
    });
  }

  // 2) Mobile menu toggle.
  var toggle = document.getElementById('menu-toggle');
  var menu = document.getElementById('mobile-menu');
  if (toggle && menu) {
    toggle.addEventListener('click', function () {
      var open = menu.classList.toggle('open');
      toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
    });
  }
})();
