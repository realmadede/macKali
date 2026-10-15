# macKali GNOME Extensions Architecture

This directory houses the metadata, schemas, manifests, and preset configurations for GNOME Shell extensions utilized by **macKali**.

## Principles

1. **No Phantom Extensions**: Extension identifiers and compatibility ranges are verified against upstream source repositories and extensions.gnome.org.
2. **Phase 1 Non-Destructive Design**: Extensions are **not** installed during Phase 1. The infrastructure establishes schemas, compatibility manifests, and settings templates for future automated deployment in Phase 2.
3. **Explicit Verification**: Any field that has not been directly verified against upstream metadata is explicitly registered in `unverified_fields`.

---

## Directory Layout

```
extensions/
├── manifest-schema.json    # JSON Schema definition for all extension manifests
├── manifests/              # Individual verified extension manifests
│   ├── dash-to-dock.json
│   ├── desktop-cube.json
│   ├── compiz-windows-effect.json
│   ├── compiz-alike-magic-lamp-effect.json
│   └── blur-my-shell.json
└── presets/                # Preset groupings mapped to visual tiers
    ├── minimal.json
    ├── balanced.json
    └── full.json
```

---

## Supported Extensions Summary

| Extension | Verified UUID | Upstream Source | Presets | Supported GNOME Versions |
| :--- | :--- | :--- | :--- | :--- |
| **Dash to Dock** | `dash-to-dock@micxgx.gmail.com` | [micheleg/dash-to-dock](https://github.com/micheleg/dash-to-dock) | Minimal, Balanced, Full | 45, 46, 47, 48, 49, 50, 51 |
| **Desktop Cube** | `desktop-cube@schneegans.github.com` | [Schneegans/Desktop-Cube](https://github.com/Schneegans/Desktop-Cube) | Full | 45, 46, 47, 48, 49, 50, 51 |
| **Compiz Windows Effect** | `compiz-windows-effect@hermes83.github.com` | [hermes83/compiz-windows-effect](https://github.com/hermes83/compiz-windows-effect) | Full | 49, 50, 51 (older GNOME via releases) |
| **Compiz Alike Magic Lamp Effect** | `compiz-alike-magic-lamp-effect@hermes83.github.com` | [hermes83/compiz-alike-magic-lamp-effect](https://github.com/hermes83/compiz-alike-magic-lamp-effect) | Balanced, Full | 45, 46, 47, 48, 49, 50, 51 |
| **Blur My Shell** | `blur-my-shell@aunetx` | [aunetx/blur-my-shell](https://github.com/aunetx/blur-my-shell) | Balanced, Full | 46, 47, 48, 49, 50, 51 |

---

## Validating Manifests

You can validate all manifests against `manifest-schema.json` using standard JSON Schema validation tools (such as `ajv`, `jsonschema` in Python, or the `scripts/compat-check.sh` utility).
