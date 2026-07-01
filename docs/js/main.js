/**
 * Renew Vault — static site enhancements
 * Mobile nav toggle, smooth scroll, active nav highlighting
 */
(function () {
  'use strict';

  var navToggle = document.querySelector('.nav-toggle');
  var siteNav = document.querySelector('.site-nav');

  if (navToggle && siteNav) {
    navToggle.addEventListener('click', function () {
      var expanded = navToggle.getAttribute('aria-expanded') === 'true';
      navToggle.setAttribute('aria-expanded', String(!expanded));
      siteNav.classList.toggle('is-open');
    });

    siteNav.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        navToggle.setAttribute('aria-expanded', 'false');
        siteNav.classList.remove('is-open');
      });
    });

    document.addEventListener('click', function (event) {
      if (
        siteNav.classList.contains('is-open') &&
        !siteNav.contains(event.target) &&
        !navToggle.contains(event.target)
      ) {
        navToggle.setAttribute('aria-expanded', 'false');
        siteNav.classList.remove('is-open');
      }
    });
  }

  document.querySelectorAll('a[href^="#"]').forEach(function (anchor) {
    anchor.addEventListener('click', function (event) {
      var targetId = anchor.getAttribute('href');
      if (targetId.length <= 1) return;

      var target = document.querySelector(targetId);
      if (!target) return;

      event.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });

  var currentPage = window.location.pathname.split('/').pop() || 'index.html';
  if (!/\.html$/i.test(currentPage)) {
    currentPage = 'index.html';
  }
  document.querySelectorAll('.site-nav a').forEach(function (link) {
    var href = link.getAttribute('href');
    if (href === currentPage) {
      link.classList.add('is-active');
      link.setAttribute('aria-current', 'page');
    }
  });

  document.querySelectorAll('.footer-nav a').forEach(function (link) {
    var href = link.getAttribute('href');
    if (href === currentPage) {
      link.classList.add('is-active');
      link.setAttribute('aria-current', 'page');
    }
  });

  var footerYear = document.getElementById('footer-year');
  if (footerYear) {
    footerYear.textContent = String(new Date().getFullYear());
  }

  var revealElements = document.querySelectorAll('.reveal');
  if (revealElements.length && 'IntersectionObserver' in window) {
    var revealObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-visible');
            revealObserver.unobserve(entry.target);
          }
        });
      },
      { root: null, rootMargin: '0px 0px -8% 0px', threshold: 0.1 }
    );

    revealElements.forEach(function (el) {
      revealObserver.observe(el);
    });
  } else {
    revealElements.forEach(function (el) {
      el.classList.add('is-visible');
    });
  }

  document.querySelectorAll('.faq-accordion-item').forEach(function (item) {
    var trigger = item.querySelector('.faq-accordion-trigger');
    var panel = item.querySelector('.faq-accordion-panel');
    if (!trigger || !panel) return;

    trigger.addEventListener('click', function () {
      var isOpen = item.classList.contains('is-open');

      item.parentElement.querySelectorAll('.faq-accordion-item.is-open').forEach(function (openItem) {
        if (openItem !== item) {
          openItem.classList.remove('is-open');
          var openTrigger = openItem.querySelector('.faq-accordion-trigger');
          var openPanel = openItem.querySelector('.faq-accordion-panel');
          if (openTrigger) openTrigger.setAttribute('aria-expanded', 'false');
          if (openPanel) openPanel.hidden = true;
        }
      });

      item.classList.toggle('is-open', !isOpen);
      trigger.setAttribute('aria-expanded', String(!isOpen));
      panel.hidden = isOpen;
    });
  });

  var legalToc = document.querySelector('.legal-toc');
  var legalTocToggle = document.querySelector('.legal-toc-toggle');
  var legalTocNav = document.querySelector('.legal-toc-nav');
  var legalTocLinks = document.querySelectorAll('.legal-toc-list a');
  var legalSections = document.querySelectorAll('.legal-content h2[id]');

  if (legalTocToggle && legalTocNav && legalToc) {
    legalTocToggle.addEventListener('click', function () {
      var expanded = legalTocToggle.getAttribute('aria-expanded') === 'true';
      legalTocToggle.setAttribute('aria-expanded', String(!expanded));
      legalToc.classList.toggle('is-open', !expanded);
    });

    legalTocLinks.forEach(function (link) {
      link.addEventListener('click', function () {
        if (window.matchMedia('(max-width: 1023px)').matches) {
          legalTocToggle.setAttribute('aria-expanded', 'false');
          legalToc.classList.remove('is-open');
        }
      });
    });
  }

  if (legalTocLinks.length && legalSections.length && 'IntersectionObserver' in window) {
    var tocObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (!entry.isIntersecting) return;

          var activeId = entry.target.getAttribute('id');
          legalTocLinks.forEach(function (link) {
            var isActive = link.getAttribute('href') === '#' + activeId;
            link.classList.toggle('is-active', isActive);
            if (isActive) {
              link.setAttribute('aria-current', 'true');
            } else {
              link.removeAttribute('aria-current');
            }
          });
        });
      },
      {
        root: null,
        rootMargin: '-20% 0px -65% 0px',
        threshold: 0
      }
    );

    legalSections.forEach(function (section) {
      tocObserver.observe(section);
    });
  } else if (legalTocLinks.length) {
    legalTocLinks[0].classList.add('is-active');
    legalTocLinks[0].setAttribute('aria-current', 'true');
  }

  var contactForm = document.getElementById('contact-form');
  if (contactForm) {
    contactForm.addEventListener('submit', function (event) {
      event.preventDefault();

      var name = document.getElementById('name').value.trim();
      var email = document.getElementById('email').value.trim();
      var topicEl = document.getElementById('topic');
      var topic = topicEl ? topicEl.value : '';
      var subject = document.getElementById('subject').value.trim();
      var message = document.getElementById('message').value.trim();

      var mailSubject = subject || ('Renew Vault ' + (topic || 'Support Request'));
      var body = 'Name: ' + name + '\nEmail: ' + email;
      if (topic) {
        body += '\nTopic: ' + topic;
      }
      body += '\n\n' + message;
      var mailto = 'mailto:jayanthrajiv@gmail.com?subject=' +
        encodeURIComponent(mailSubject) +
        '&body=' +
        encodeURIComponent(body);

      window.location.href = mailto;
    });
  }
})();
