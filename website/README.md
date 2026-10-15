# macKali Static Showcase & Documentation Portal

This directory contains the production-ready static website and documentation portal for the **macKali** project.

The website provides a modern, Apple-inspired presentation introducing macKali's architecture, demonstrating its visual presets, explaining its dynamic 4-tier GNOME compatibility model, and guiding visitors to install the project safely on Kali Linux GNOME.

---

## Architecture & Directory Structure

```text
website/
├── index.html        # Main landing page, hero, capabilities, showcase & installation
├── 404.html          # Clean error page with home navigation
├── styles.css        # Responsive design system, CSS variables, bento grids, glassmorphism
├── script.js         # Theme toggle, accessible clipboard copy with fallback, mobile drawer
├── favicon.svg       # Vector macOS squircle with traffic lights and Kali terminal prompt
├── robots.txt        # Search engine crawl rules and sitemap pointer
├── sitemap.xml       # Structured XML sitemap
├── build.sh          # Self-contained static site build & validation script
├── README.md         # This technical documentation
└── dist/             # Generated deployment output (gitignored)
    ├── index.html
    ├── 404.html
    ├── styles.css
    ├── script.js
    ├── favicon.svg
    ├── robots.txt
    ├── sitemap.xml
    └── assets/       # Bundled authentic project previews & 4K wallpapers
```

---

## Building the Static Site

The static site does not require Node.js, npm, webpack, or any external package managers. Build and assembly are handled directly by the reproducible build script:

```bash
bash website/build.sh
```

### What `build.sh` Does:
1. Cleans and prepares the isolated `website/dist/` output directory.
2. Copies all core website files (`index.html`, `404.html`, `styles.css`, `script.js`, `favicon.svg`, `robots.txt`, `sitemap.xml`).
3. Resolves and bundles authentic repository visual assets (`assets/preview.png`, `themes/wallpapers/macOS-macKali-Light.png`, `themes/wallpapers/macOS-macKali-Dark.png`) into `website/dist/assets/`.
4. Performs strict integrity validation ensuring all output files exist, are non-empty, and all internal asset references resolve.

---

## Local Preview

To preview the built static site locally in your browser:

```bash
# 1. Build the distribution:
bash website/build.sh

# 2. Launch a local HTTP server:
python3 -m http.server 8000 -d website/dist
```

Then open your browser to: `http://localhost:8000`

---

## Deployment Configuration

The website is designed for zero-maintenance, high-speed static hosting on modern edge platforms.

### Option 1: Cloudflare Pages (Recommended)
1. In the Cloudflare Dashboard, navigate to **Compute (Workers & Pages)** → **Create** → **Pages** → **Connect to Git**.
2. Select the `realmadede/macKali` repository.
3. Configure the build settings:
   - **Framework preset**: `None`
   - **Build command**: `bash website/build.sh`
   - **Build output directory**: `website/dist`
   - **Root directory**: `/` (or leave empty)
4. Click **Save and Deploy**.
5. Cloudflare Pages will automatically build pull request preview deployments for any branch and deploy pushes to `main`.

### Option 2: GitHub Pages via GitHub Actions
The site can be deployed via GitHub Actions using the bundled `.github/workflows/website.yml` workflow which builds `website/dist/` and uploads the artifact.

---

## Accessibility & Performance Features

- **Semantic HTML5**: Full landmark hierarchy (`<header>`, `<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`), valid heading structure (`<h1>` through `<h3>`).
- **Keyboard Navigation & Focus**: High-visibility focus indicators (`:focus-visible`), skip-to-content bypass link (`.skip-link`).
- **Accessible Clipboard Copy**: Primary `navigator.clipboard.writeText` with visual ("Copied!") and screen-reader announcements (`aria-live="polite"`), plus a reliable fallback that selects text for manual copy if clipboard permissions are restricted.
- **Light & Dark Theming**: Dynamic theme switcher with automatic OS preference detection (`prefers-color-scheme`) and persistent preference storage (`localStorage`).
- **Reduced Motion Support**: Comprehensive `@media (prefers-reduced-motion: reduce)` media query disabling transitions, transforms, and animations for motion-sensitive users.
- **Zero Remote Dependencies**: Self-contained fonts (system font stack), local vector SVG icons, and bundled project assets. Zero external CDN calls or tracking scripts.
