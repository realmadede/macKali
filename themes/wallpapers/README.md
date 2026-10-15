# macKali Wallpapers

This directory houses the wallpaper assets, metadata, and provider configurations for **macKali**.

---

## Bundled Wallpapers

macKali includes two high-resolution 4K UHD (3840x2160) wallpapers:

- **`macOS-macKali-Light.png`**: Warm sunrise abstract gradient for Light mode.
- **`macOS-macKali-Dark.png`**: Deep midnight nebula gradient for Dark mode.

These are configured simultaneously in GNOME:
- `org.gnome.desktop.background picture-uri` (Light mode)
- `org.gnome.desktop.background picture-uri-dark` (Dark mode)

When you toggle between light and dark appearance in GNOME, the wallpaper transitions automatically.

---

## Finding & Applying Custom Wallpapers

Wallpaper preferences are highly personal. If you prefer photography, coding themes, or custom artwork over the default gradients, we recommend browsing high-resolution open collections such as:

👉 **[Unsplash Linux Wallpapers Collection](https://unsplash.com/s/photos/linux-wallpaper)**

### How to Apply a Custom Wallpaper

1. Browse [Unsplash Linux Wallpapers](https://unsplash.com/s/photos/linux-wallpaper) and click **"Download free"** on any wallpaper you like.
2. The image will save into your `~/Downloads` folder.
3. Apply it using the macKali wallpaper provider:

```bash
# Set as both Light and Dark wallpaper:
./scripts/providers/wallpaper-provider.sh --file ~/Downloads/your-wallpaper.jpg

# Or set separate Light and Dark wallpapers:
./scripts/providers/wallpaper-provider.sh --file ~/Downloads/day-wallpaper.jpg --variant light
./scripts/providers/wallpaper-provider.sh --file ~/Downloads/night-wallpaper.jpg --variant dark
```

---

## Configuration Provider

The driver script is located at [`scripts/providers/wallpaper-provider.sh`](../../scripts/providers/wallpaper-provider.sh).
To preview changes without applying:

```bash
./scripts/providers/wallpaper-provider.sh --bundled --dry-run
```

To revert back to Kali Linux system default wallpapers:

```bash
./scripts/providers/wallpaper-provider.sh --reset
```
