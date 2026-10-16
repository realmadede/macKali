# macKali — Showcase & Documentation Portal

This branch contains the static website and documentation portal for the **[macKali](https://github.com/realmadede/macKali/tree/main)** project, hosted and deployed via Cloudflare edge infrastructure.

🌐 **Production Website**: [https://mackali.madede.workers.dev/](https://mackali.madede.workers.dev/)  
💻 **Desktop Customization Suite**: [macKali `main` Branch](https://github.com/realmadede/macKali/tree/main)

---

## Directory Structure

```text
.
├── .github/
│   └── workflows/
│       └── website.yml       # Website build & validation CI workflow
├── website/
│   ├── index.html            # Main showcase landing page & interactive installer guide
│   ├── 404.html              # Custom 404 error page
│   ├── styles.css            # Responsive design system & Sofia Sans typography
│   ├── script.js             # Theme toggle (Light/Dark) & accessible copy
│   ├── favicon.svg           # Vector macOS squircle branding
│   ├── robots.txt            # Search engine crawl rules & sitemap reference
│   ├── sitemap.xml           # Structured XML sitemap
│   ├── build.sh              # Static website build & asset assembly script
│   ├── README.md             # In-depth website documentation
│   └── assets/               # Bundled authentic 4K wallpapers & preview graphics
├── .gitignore                # Branch-specific ignore rules (build output)
└── README.md                 # This overview
```

---

## Building & Local Preview

Build the production distribution:

```bash
bash website/build.sh
```

Preview locally:

```bash
python3 -m http.server 8000 -d website/dist
```

Then visit: [http://localhost:8000](http://localhost:8000)
