"""Re-encode rendered KursorQR clay assets for web delivery and generate PWA icons.

Run from the repo root after `render_clay_assets.py`:

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/optimize_web_assets.py

1. Converts 16-bit RGBA PNGs in `app/assets/clay/` to 8-bit max-compression PNGs.
2. Converts `hero_qr_scene.png` to lossless WebP (`hero_qr_scene.webp`) and removes the PNG.
3. Generates `app/web/favicon.png`, `Icon-192.png`, `Icon-512.png`,
   `Icon-maskable-192.png`, and `Icon-maskable-512.png` from `kursorqr_logo_3d.png`.
"""

import os
import tempfile

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
CLAY = os.path.join(REPO, "app", "assets", "clay")
WEB = os.path.join(REPO, "app", "web")
WEB_ICONS = os.path.join(WEB, "icons")

WEBP = {"hero_qr_scene": 100}  # 100 = lossless WebP


def _setup_scene():
    scene = bpy.context.scene
    scene.display_settings.display_device = "sRGB"
    scene.view_settings.view_transform = "Standard"
    scene.view_settings.look = "None"
    scene.view_settings.exposure = 0.0
    scene.view_settings.gamma = 1.0
    return scene


def _save(scene, img, path, webp_quality=None):
    s = scene.render.image_settings
    if webp_quality is None:
        s.file_format = "PNG"
        s.color_depth = "8"
        s.compression = 100
    else:
        s.file_format = "WEBP"
        s.quality = webp_quality
    s.color_mode = "RGBA"
    img.save_render(path, scene=scene)


def _generate_web_icons(scene, logo_path):
    if not os.path.exists(logo_path):
        print("[web] skipping web icons: kursorqr_logo_3d.png not found")
        return
    os.makedirs(WEB_ICONS, exist_ok=True)
    targets = [
        (os.path.join(WEB, "favicon.png"), 64),
        (os.path.join(WEB_ICONS, "Icon-192.png"), 192),
        (os.path.join(WEB_ICONS, "Icon-512.png"), 512),
        (os.path.join(WEB_ICONS, "Icon-maskable-192.png"), 192),
        (os.path.join(WEB_ICONS, "Icon-maskable-512.png"), 512),
    ]
    for dest, size in targets:
        img = bpy.data.images.load(logo_path, check_existing=False)
        img.scale(size, size)
        _save(scene, img, dest, None)
        bpy.data.images.remove(img)
        print(f"[web] generated {os.path.relpath(dest, REPO)} ({size}x{size}, {os.path.getsize(dest) / 1024:.1f} KB)")


def main():
    scene = _setup_scene()
    total_before = total_after = 0

    for name in sorted(os.listdir(CLAY)):
        stem, ext = os.path.splitext(name)
        if ext != ".png":
            continue
        src = os.path.join(CLAY, name)
        before = os.path.getsize(src)
        img = bpy.data.images.load(src, check_existing=False)
        quality = WEBP.get(stem)
        tmp = os.path.join(tempfile.gettempdir(), stem + (".webp" if quality else ".png"))
        _save(scene, img, tmp, quality)
        bpy.data.images.remove(img)

        after = os.path.getsize(tmp)
        dest = os.path.join(CLAY, os.path.basename(tmp))
        os.replace(tmp, dest)
        if quality:
            os.remove(src)
        total_before += before
        total_after += after
        print(f"[web] {name:26s} {before / 1024:7.1f} KB -> {after / 1024:7.1f} KB")

    print(f"[web] clay assets total: {total_before / 1024:.0f} KB -> {total_after / 1024:.0f} KB")
    _generate_web_icons(scene, os.path.join(CLAY, "kursorqr_logo_3d.png"))


if __name__ == "__main__":
    main()
