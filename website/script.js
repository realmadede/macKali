/**
 * macKali Showcase Website Interactive Logic
 * Handles theming, clipboard copying with fallback, mobile navigation, and asset viewers.
 */

(function () {
  'use strict';

  // --------------------------------------------------------------------------
  // Theme Management (Light / Dark / System Preference)
  // --------------------------------------------------------------------------
  const THEME_KEY = 'mackali-theme';
  const themeToggleBtn = document.getElementById('theme-toggle-btn');
  const prefersDarkMedia = window.matchMedia('(prefers-color-scheme: dark)');

  function getSavedTheme() {
    return localStorage.getItem(THEME_KEY);
  }

  function applyTheme(theme) {
    if (theme === 'light') {
      document.documentElement.setAttribute('data-theme', 'light');
    } else if (theme === 'dark') {
      document.documentElement.removeAttribute('data-theme');
    } else {
      // System default
      if (prefersDarkMedia.matches) {
        document.documentElement.removeAttribute('data-theme');
      } else {
        document.documentElement.setAttribute('data-theme', 'light');
      }
    }
    updateThemeToggleLabel();
  }

  function updateThemeToggleLabel() {
    if (!themeToggleBtn) return;
    const isLight = document.documentElement.getAttribute('data-theme') === 'light';
    themeToggleBtn.setAttribute('aria-label', isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode');
    themeToggleBtn.setAttribute('title', isLight ? 'Switch to Dark Mode' : 'Switch to Light Mode');
    themeToggleBtn.innerHTML = isLight
      ? `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path></svg>`
      : `<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="5"></circle><line x1="12" y1="1" x2="12" y2="3"></line><line x1="12" y1="21" x2="12" y2="23"></line><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line><line x1="1" y1="12" x2="3" y2="12"></line><line x1="21" y1="12" x2="23" y2="12"></line><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line></svg>`;
  }

  // Initialize theme
  const initialTheme = getSavedTheme();
  if (initialTheme) {
    applyTheme(initialTheme);
  } else {
    applyTheme('auto');
  }

  // Listen for OS theme changes if user hasn't explicitly set one
  prefersDarkMedia.addEventListener('change', function (e) {
    if (!getSavedTheme()) {
      applyTheme('auto');
    }
  });

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', function () {
      const isLight = document.documentElement.getAttribute('data-theme') === 'light';
      const newTheme = isLight ? 'dark' : 'light';
      localStorage.setItem(THEME_KEY, newTheme);
      applyTheme(newTheme);
    });
  }

  // --------------------------------------------------------------------------
  // Mobile Navigation Menu
  // --------------------------------------------------------------------------
  const mobileToggleBtn = document.getElementById('mobile-toggle-btn');
  const navLinks = document.getElementById('nav-links');

  if (mobileToggleBtn && navLinks) {
    mobileToggleBtn.addEventListener('click', function () {
      const isExpanded = mobileToggleBtn.getAttribute('aria-expanded') === 'true';
      mobileToggleBtn.setAttribute('aria-expanded', !isExpanded);
      navLinks.classList.toggle('active');
    });

    // Close mobile menu when clicking a link
    navLinks.querySelectorAll('a').forEach(function (link) {
      link.addEventListener('click', function () {
        navLinks.classList.remove('active');
        mobileToggleBtn.setAttribute('aria-expanded', 'false');
      });
    });

    // Close on Escape key
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && navLinks.classList.contains('active')) {
        navLinks.classList.remove('active');
        mobileToggleBtn.setAttribute('aria-expanded', 'false');
        mobileToggleBtn.focus();
      }
    });
  }

  // --------------------------------------------------------------------------
  // Accessible Copy to Clipboard with Fallback
  // --------------------------------------------------------------------------
  const copyButtons = document.querySelectorAll('.copy-btn');

  copyButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      const targetId = btn.getAttribute('data-target');
      const targetEl = document.getElementById(targetId);
      if (!targetEl) return;

      const textToCopy = targetEl.innerText || targetEl.textContent;

      function onCopySuccess() {
        btn.classList.add('copied');
        const originalHtml = btn.innerHTML;
        btn.innerHTML = `<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><polyline points="20 6 9 17 4 12"></polyline></svg> Copied!`;
        
        // Notify screen readers via live region
        const liveRegion = document.getElementById('a11y-live-region');
        if (liveRegion) {
          liveRegion.textContent = 'Command copied to clipboard successfully.';
        }

        setTimeout(function () {
          btn.classList.remove('copied');
          btn.innerHTML = originalHtml;
          if (liveRegion) {
            liveRegion.textContent = '';
          }
        }, 2500);
      }

      function onCopyFailure() {
        // Fallback: select text in the container
        if (window.getSelection && document.createRange) {
          const range = document.createRange();
          range.selectNodeContents(targetEl);
          const selection = window.getSelection();
          selection.removeAllRanges();
          selection.addRange(range);
        }
        btn.innerText = 'Press Ctrl+C';
        setTimeout(function () {
          btn.innerText = 'Copy';
        }, 3000);
      }

      // Try modern navigator.clipboard
      if (navigator.clipboard && window.isSecureContext) {
        navigator.clipboard.writeText(textToCopy.trim())
          .then(onCopySuccess)
          .catch(function () {
            fallbackCopy(textToCopy, onCopySuccess, onCopyFailure);
          });
      } else {
        fallbackCopy(textToCopy, onCopySuccess, onCopyFailure);
      }
    });
  });

  function fallbackCopy(text, onSuccess, onFailure) {
    try {
      const textArea = document.createElement('textarea');
      textArea.value = text.trim();
      textArea.style.position = 'fixed';
      textArea.style.top = '-9999px';
      textArea.style.left = '-9999px';
      textArea.setAttribute('readonly', '');
      document.body.appendChild(textArea);
      textArea.select();
      const successful = document.execCommand('copy');
      document.body.removeChild(textArea);
      if (successful) {
        onSuccess();
      } else {
        onFailure();
      }
    } catch (err) {
      onFailure();
    }
  }

  // --------------------------------------------------------------------------
  // Wallpaper Showcase Switcher (Light / Dark 4K Wallpaper Preview)
  // --------------------------------------------------------------------------
  const wallpaperImg = document.getElementById('showcase-wallpaper-img');
  const wallpaperCaption = document.getElementById('showcase-wallpaper-caption');
  const segmentBtns = document.querySelectorAll('.segment-btn');

  segmentBtns.forEach(function (btn) {
    btn.addEventListener('click', function () {
      segmentBtns.forEach(function (b) {
        b.classList.remove('active');
        b.setAttribute('aria-selected', 'false');
      });
      btn.classList.add('active');
      btn.setAttribute('aria-selected', 'true');

      const variant = btn.getAttribute('data-variant');
      if (wallpaperImg) {
        wallpaperImg.style.opacity = '0.4';
        setTimeout(function () {
          if (variant === 'light') {
            wallpaperImg.src = 'assets/macOS-macKali-Light.png';
            wallpaperImg.alt = 'macKali 4K UHD Light Mode Sunrise Abstract Wallpaper Preview';
            if (wallpaperCaption) {
              wallpaperCaption.textContent = 'macOS-macKali-Light.png • 3840×2160 UHD • Dynamic Sunrise Abstract';
            }
          } else {
            wallpaperImg.src = 'assets/macOS-macKali-Dark.png';
            wallpaperImg.alt = 'macKali 4K UHD Dark Mode Midnight Nebula Wallpaper Preview';
            if (wallpaperCaption) {
              wallpaperCaption.textContent = 'macOS-macKali-Dark.png • 3840×2160 UHD • Dynamic Midnight Nebula';
            }
          }
          wallpaperImg.style.opacity = '1';
        }, 120);
      }
    });
  });

})();
