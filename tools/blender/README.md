# KursorQR Blender 3D Clay Assets

`render_clay_assets.py` builds all 18 claymorphism assets procedurally (no input `.blend` required), renders them to `app/assets/clay/` at 2× display resolution, generates the seamless `grain_tile.png`, and saves a local (gitignored) scene to `tools/blender/kursorqr_clay.blend`.

## Render all assets (Blender 5.2 LTS, headless EEVEE)

```powershell
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/render_clay_assets.py
```

## Optimize for web & regenerate PWA icons

```powershell
"C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/optimize_web_assets.py
```
