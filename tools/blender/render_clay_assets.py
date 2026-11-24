"""Procedural claymorphism 3D asset renderer for KursorQR.

Run headless from the repo root (Blender 5.2 LTS):

    "C:/Program Files/Blender Foundation/Blender 5.2/blender.exe" -b --python tools/blender/render_clay_assets.py

Builds all 18 KursorQR claymorphism assets procedurally from primitives,
renders them to app/assets/clay/<name>.png at 2x display size, writes the
seamless grain_tile.png, and saves tools/blender/kursorqr_clay.blend.

Optional CLI flags after "--":
    --only name1,name2   render only these assets (by file stem)
    --scale 0.5          multiply the render resolution
    --samples 32         EEVEE TAA samples (default 48)
    --engine CYCLES      use Cycles instead of EEVEE
    --no-blend           skip saving the .blend file
    --out DIR            override output directory
"""

import math
import os
import sys
from math import radians

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT_DIR = os.path.join(REPO, "app", "assets", "clay")
BLEND_PATH = os.path.join(HERE, "kursorqr_clay.blend")


def _parse_args():
    argv = sys.argv
    args = argv[argv.index("--") + 1:] if "--" in argv else []
    opts = {
        "only": None,
        "scale": 1.0,
        "samples": 48,
        "engine": "BLENDER_EEVEE",
        "blend": True,
        "out": None,
    }
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--only":
            opts["only"] = set(args[i + 1].split(","))
            i += 2
        elif a == "--scale":
            opts["scale"] = float(args[i + 1])
            i += 2
        elif a == "--samples":
            opts["samples"] = int(args[i + 1])
            i += 2
        elif a == "--engine":
            opts["engine"] = args[i + 1]
            i += 2
        elif a == "--no-blend":
            opts["blend"] = False
            i += 1
        elif a == "--out":
            opts["out"] = os.path.abspath(args[i + 1])
            i += 2
        else:
            i += 1
    return opts


OPTS = _parse_args()
if OPTS["out"]:
    OUT_DIR = OPTS["out"]

# --------------------------------------------------------------------------------------
# Colour tokens (matching app/lib/core/constants/app_colors.dart)
# --------------------------------------------------------------------------------------

TOKENS_HEX = {
    "sand": "EAE0C8",
    "clay": "F7F1E3",
    "clayDeep": "E3D7BC",
    "primary": "8B3103",
    "primaryDeep": "5C1F02",
    "primaryLight": "C45722",
    "mint": "F0D6C4",
    "gold": "DFA94B",
    "goldDeep": "B88329",
    "goldLight": "FAD284",
    "butter": "F9EAC8",
    "coral": "D9534F",
    "coralDeep": "B53531",
    "sage": "5C8D6B",
}

TOKEN_BASE = {}
ASSET_COLLECTIONS = []
_MATERIALS = {}
_current_collection = None

LIGHT_DISTANCE = 4.0
EXPOSURE = 0.0
VIEW_TRANSFORM = "Khronos PBR Neutral"
VIEW_LOOKS = ("None",)
FALLBACK_VIEW_TRANSFORM = "AgX"
FALLBACK_LOOKS = ("AgX - Base Contrast", "AgX - Medium Contrast", "None")
GRID_STEP = 6.0


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_to_linear(h):
    r, g, b = (int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return (srgb_to_linear(r), srgb_to_linear(g), srgb_to_linear(b), 1.0)


def linear_to_srgb(v):
    v = max(0.0, min(1.0, v))
    return v * 12.92 if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055


def token_linear(name):
    if name in TOKEN_BASE:
        r, g, b = TOKEN_BASE[name]
        return (r, g, b, 1.0)
    return hex_to_linear(TOKENS_HEX[name])


# --------------------------------------------------------------------------------------
# Scene, lighting & cameras
# --------------------------------------------------------------------------------------


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.name = "KursorQRClayAssets"
    scene.unit_settings.system = "METRIC"

    try:
        scene.render.engine = OPTS["engine"]
    except TypeError:
        scene.render.engine = "BLENDER_EEVEE"

    if scene.render.engine == "BLENDER_EEVEE":
        ev = scene.eevee
        ev.taa_render_samples = OPTS["samples"]
        ev.use_shadows = True
        ev.shadow_ray_count = 4
        ev.shadow_step_count = 8
        ev.use_raytracing = False
        ev.use_fast_gi = False
    else:
        cy = scene.cycles
        cy.device = "CPU"
        cy.samples = max(32, OPTS["samples"])
        cy.use_denoising = True
        cy.max_bounces = 4
        cy.caustics_reflective = False
        cy.caustics_refractive = False

    scene.render.film_transparent = True
    scene.render.dither_intensity = 1.0
    img = scene.render.image_settings
    img.file_format = "PNG"
    img.color_mode = "RGBA"
    img.color_depth = "16"
    img.compression = 50
    img.color_management = "FOLLOW_SCENE"

    looks = VIEW_LOOKS
    try:
        scene.view_settings.view_transform = VIEW_TRANSFORM
    except TypeError:
        scene.view_settings.view_transform = FALLBACK_VIEW_TRANSFORM
        looks = FALLBACK_LOOKS
    for look in looks:
        try:
            scene.view_settings.look = look
            break
        except TypeError:
            continue
    scene.view_settings.exposure = EXPOSURE
    scene.view_settings.gamma = 1.0
    scene.display_settings.display_device = "sRGB"

    world = bpy.data.worlds.new("ClayWorld")
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = hex_to_linear(TOKENS_HEX["sand"])
    bg.inputs["Strength"].default_value = 0.3
    scene.world = world

    _MATERIALS.clear()
    ASSET_COLLECTIONS.clear()


def make_area_light(name, power, size, kelvin):
    data = bpy.data.lights.new(name, type="AREA")
    data.energy = power
    data.size = size
    data.shape = "SQUARE"
    if hasattr(data, "use_temperature"):
        data.use_temperature = True
        data.temperature = kelvin
    else:
        data.color = (1.0, 0.93, 0.85) if kelvin < 6000 else (0.87, 0.91, 1.0)
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def aim(obj, target):
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def setup_lights_and_cameras():
    scene = bpy.context.scene

    cam_iso_data = bpy.data.cameras.new("IconCamera")
    cam_iso_data.type = "ORTHO"
    cam_iso_data.ortho_scale = 2.2
    cam_iso_data.clip_start = 0.01
    cam_iso_data.clip_end = 200
    cam_iso = bpy.data.objects.new("IconCamera", cam_iso_data)
    scene.collection.objects.link(cam_iso)

    cam_persp_data = bpy.data.cameras.new("HeroCamera")
    cam_persp_data.type = "PERSP"
    cam_persp_data.lens = 50
    cam_persp_data.sensor_width = 36
    cam_persp_data.clip_start = 0.01
    cam_persp_data.clip_end = 200
    cam_persp = bpy.data.objects.new("HeroCamera", cam_persp_data)
    scene.collection.objects.link(cam_persp)

    key = make_area_light("KeyLight", 400, 3.0, 5200)
    fill = make_area_light("FillLight", 120, 2.0, 7000)
    return cam_iso, cam_persp, key, fill


def place_lights(cam, key, fill, target=(0, 0, 0), distance=7.0):
    rot = cam.matrix_world.to_3x3()
    t = Vector(target)
    key.location = t + rot @ (Vector((-0.7, 0.85, 0.9)).normalized() * distance)
    fill.location = t + rot @ (Vector((0.8, -0.55, 0.9)).normalized() * distance)
    aim(key, t)
    aim(fill, t)


# --------------------------------------------------------------------------------------
# Clay materials & primitives
# --------------------------------------------------------------------------------------


def clay_material(token, sss_scale=0.05):
    key = (token, round(sss_scale, 3))
    if key in _MATERIALS:
        return _MATERIALS[key]
    mat = bpy.data.materials.new(f"Clay_{token}_{round(sss_scale, 3)}")
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = token_linear(token)
    bsdf.inputs["Roughness"].default_value = 0.65
    bsdf.inputs["Metallic"].default_value = 0.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.3
    bsdf.inputs["Subsurface Weight"].default_value = 0.08
    bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.6, 0.4)
    bsdf.inputs["Subsurface Scale"].default_value = sss_scale
    bsdf.inputs["Sheen Weight"].default_value = 0.1
    bsdf.inputs["Coat Weight"].default_value = 0.0
    _MATERIALS[key] = mat
    return mat


def _link(obj):
    coll = _current_collection or bpy.context.scene.collection
    coll.objects.link(obj)
    return obj


def _select_only(obj):
    for o in bpy.context.view_layer.objects:
        if o is not None:
            o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


def finish(obj, token, bevel_frac=0.08, bevel=True, segments=3, angle=30.0, sss=None):
    _select_only(obj)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    dims = [d for d in obj.dimensions if d > 1e-6]
    smallest = min(dims) if dims else 0.1
    mat = clay_material(token, sss if sss is not None else max(0.01, 0.12 * smallest))
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    if bevel:
        mod = obj.modifiers.new("Bevel", type="BEVEL")
        mod.segments = segments
        mod.width = bevel_frac * smallest
        mod.limit_method = "ANGLE"
        mod.angle_limit = radians(angle)
        mod.use_clamp_overlap = True
        mod.harden_normals = True
        mod.miter_outer = "MITER_SHARP"
    bpy.ops.object.shade_smooth()
    return obj


def new_mesh_object(name, bm):
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    _link(obj)
    return obj


def _rounded_rect_points(w, h, r, seg=8):
    r = min(r, w / 2 - 1e-4, h / 2 - 1e-4)
    pts = []
    corners = [
        (w / 2 - r, h / 2 - r, 0),
        (-w / 2 + r, h / 2 - r, 90),
        (-w / 2 + r, -h / 2 + r, 180),
        (w / 2 - r, -h / 2 + r, 270),
    ]
    for cx, cy, start in corners:
        for i in range(seg + 1):
            a = radians(start + 90 * i / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def extrude_profile(name, pts2d, thickness, token, bevel_frac=0.08, bevel=True, segments=3):
    bm = bmesh.new()
    verts = [bm.verts.new((x, y, 0.0)) for x, y in pts2d]
    bm.faces.new(verts)
    bm.faces.ensure_lookup_table()
    res = bmesh.ops.extrude_face_region(bm, geom=[bm.faces[0]])
    top_verts = [g for g in res["geom"] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, vec=(0, 0, thickness), verts=top_verts)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    obj = new_mesh_object(name, bm)
    return finish(obj, token, bevel_frac=bevel_frac, bevel=bevel, segments=segments)


def slab(name, w, h, t, token, radius=None, bevel_frac=0.3, location=(0, 0, 0), rotation=(0, 0, 0), segments=3):
    if radius is None:
        radius = min(w, h) * 0.18
    pts = _rounded_rect_points(w, h, radius)
    obj = extrude_profile(name, pts, t, token, bevel_frac=bevel_frac, segments=segments)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.translate(bm, vec=(0, 0, -t / 2), verts=bm.verts[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return obj


def box(name, size, token, location=(0, 0, 0), rotation=(0, 0, 0), bevel_frac=0.3):
    bpy.ops.mesh.primitive_cube_add(size=1.0)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.scale = size
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel_frac=bevel_frac)


def cylinder(name, radius, depth, token, location=(0, 0, 0), rotation=(0, 0, 0), verts=48, bevel_frac=0.08):
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=radius, depth=depth)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel_frac=bevel_frac)


def sphere(name, radius, token, location=(0, 0, 0), scale=(1, 1, 1), rotation=(0, 0, 0), segments=48):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=max(8, segments // 2), radius=radius)
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    finish(obj, token, bevel=False)
    obj.scale = scale
    return obj


def torus_link(name, major_r, minor_r, token, location=(0, 0, 0), rotation=(0, 0, 0), scale=(1.0, 1.0, 1.0)):
    bpy.ops.mesh.primitive_torus_add(
        major_radius=major_r,
        minor_radius=minor_r,
        major_segments=48,
        minor_segments=24,
    )
    obj = bpy.context.active_object
    bpy.context.scene.collection.objects.unlink(obj)
    _link(obj)
    obj.name = name
    obj.scale = scale
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return finish(obj, token, bevel=False)


def boolean_cut(obj, cutter, bevel_width=None):
    mod = obj.modifiers.new("Cut", type="BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    bevel = obj.modifiers.get("Bevel")
    if bevel is not None:
        if bevel_width is not None:
            bevel.width = bevel_width
        _select_only(obj)
        with bpy.context.temp_override(object=obj):
            bpy.ops.object.modifier_move_to_index(modifier=mod.name, index=0)
    cutter.hide_render = True
    cutter.hide_viewport = True
    cutter.display_type = "WIRE"
    return obj


def qr_finder(name, size, thickness, outer_token, inner_token="clay", dot_token=None, location=(0, 0, 0), parent=None):
    """Builds a chunky clay QR finder square (outer rounded frame + inner cream inset + core block)."""
    if dot_token is None:
        dot_token = outer_token
    root = bpy.data.objects.new(name, None)
    _link(root)
    outer = slab(name + "_o", size, size, thickness, outer_token, radius=size * 0.24, bevel_frac=0.25)
    mid = slab(name + "_m", size * 0.64, size * 0.64, thickness * 0.65, inner_token,
               radius=size * 0.14, bevel_frac=0.25, location=(0, 0, thickness * 0.34))
    core = slab(name + "_c", size * 0.34, size * 0.34, thickness * 0.75, dot_token,
                radius=size * 0.08, bevel_frac=0.25, location=(0, 0, thickness * 0.56))
    for p in (outer, mid, core):
        p.parent = root
    root.location = location
    if parent is not None:
        root.parent = parent
    return root


def cursor_arrow(name, scale=1.0, thickness=0.14, token="gold", location=(0, 0, 0), rotation=(0, 0, 0), parent=None):
    """Chunky rounded clay pointer cursor (KursorQR signature motif)."""
    pts = [
        (0.0, 0.45 * scale),
        (-0.34 * scale, -0.34 * scale),
        (-0.04 * scale, -0.18 * scale),
        (0.10 * scale, -0.44 * scale),
        (0.24 * scale, -0.36 * scale),
        (0.10 * scale, -0.10 * scale),
        (0.36 * scale, -0.06 * scale),
    ]
    obj = extrude_profile(name, pts, thickness, token, bevel_frac=0.32, segments=3)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.translate(bm, vec=(0, 0, -thickness / 2), verts=bm.verts[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    if parent is not None:
        obj.parent = parent
    return obj


def phone(name, w, h, t, body="primary", screen="clay", radius=None, camera_dot=False,
          location=(0, 0, 0), rotation=(0, 0, 0), bezel=0.07):
    root = bpy.data.objects.new(name, None)
    _link(root)
    if radius is None:
        radius = w * 0.17
    body_obj = slab(name + "_body", w, h, t, body, radius=radius)
    sw, sh = w - 2 * bezel, h - 2 * bezel - (0.06 if camera_dot else 0.0)
    screen_obj = slab(name + "_screen", sw, sh, t * 0.5, screen, radius=max(0.02, radius - bezel),
                      location=(0, -(0.03 if camera_dot else 0.0), t * 0.5))
    parts = [body_obj, screen_obj]
    if camera_dot:
        dot = sphere(name + "_cam", 0.03, "primaryDeep", location=(0, h / 2 - bezel * 0.55, t * 0.5 + 0.015))
        parts.append(dot)
    for p in parts:
        p.parent = root
    root.location = location
    root.rotation_euler = [radians(a) for a in rotation]
    return root


def shield_mesh(name, w, h, t, token="primary", location=(0, 0, 0), rotation=(0, 0, 0)):
    """Rounded crest shield profile extruded in clay."""
    pts = [
        (0.0, h * 0.50),
        (-w * 0.44, h * 0.36),
        (-w * 0.48, h * 0.02),
        (-w * 0.34, -h * 0.30),
        (0.0, -h * 0.50),
        (w * 0.34, -h * 0.30),
        (w * 0.48, h * 0.02),
        (w * 0.44, h * 0.36),
    ]
    obj = extrude_profile(name, pts, t, token, bevel_frac=0.35, segments=3)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bmesh.ops.translate(bm, vec=(0, 0, -t / 2), verts=bm.verts[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.location = location
    obj.rotation_euler = [radians(a) for a in rotation]
    return obj


# --------------------------------------------------------------------------------------
# Camera framing & calibration
# --------------------------------------------------------------------------------------


def _bbox_points(objs):
    pts = []
    for o in objs:
        if o.type != "MESH" or o.hide_render:
            continue
        for c in o.bound_box:
            pts.append(o.matrix_world @ Vector(c))
    return pts


def all_mesh_objects(coll):
    return [o for o in coll.all_objects if o.type == "MESH" and not o.hide_render]


def frame_ortho(cam, objs, res_x, res_y, fill=0.82, rx=54.7, rz=45.0, target=None):
    cam.rotation_euler = (radians(rx), 0.0, radians(rz))
    bpy.context.view_layer.update()
    rot = cam.rotation_euler.to_matrix()
    inv = rot.inverted()
    pts = _bbox_points(objs)
    local = [inv @ p for p in pts]
    xs = [p.x for p in local]
    ys = [p.y for p in local]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    ext_x, ext_y = max(xs) - min(xs), max(ys) - min(ys)
    aspect = res_y / res_x
    if res_x >= res_y:
        scale = max(ext_x, ext_y / aspect) / fill
    else:
        scale = max(ext_y, ext_x * aspect) / fill
    cam.data.ortho_scale = scale
    centre_local = Vector((cx, cy, 0))
    if target is not None:
        centre_local = inv @ Vector(target)
        centre_local.z = 0
    centre_world = rot @ centre_local
    cam.location = centre_world + rot @ Vector((0, 0, 12.0))
    bpy.context.view_layer.update()
    return centre_world


def frame_persp(cam, objs, res_x, res_y, fill=0.84, rx=65.0, rz=14.0, target=None, roll=0.0):
    cam.rotation_euler = (radians(rx), 0.0, radians(rz))
    bpy.context.view_layer.update()
    rot = cam.rotation_euler.to_matrix()
    inv = rot.inverted()
    pts = _bbox_points(objs)
    local = [inv @ p for p in pts]
    centre_local = Vector((
        (min(p.x for p in local) + max(p.x for p in local)) / 2,
        (min(p.y for p in local) + max(p.y for p in local)) / 2,
        (min(p.z for p in local) + max(p.z for p in local)) / 2,
    ))
    if target is not None:
        centre_local = inv @ Vector(target)
    sensor = cam.data.sensor_width
    f = cam.data.lens
    if res_x >= res_y:
        tan_x = sensor / (2 * f)
        tan_y = tan_x * res_y / res_x
    else:
        tan_y = sensor / (2 * f)
        tan_x = tan_y * res_x / res_y
    t_needed = 0.0
    for p in local:
        q = p - centre_local
        t_needed = max(t_needed, abs(q.x) / (tan_x * fill) + q.z, abs(q.y) / (tan_y * fill) + q.z)
    cam.location = rot @ (centre_local + Vector((0, 0, t_needed)))
    if roll:
        cam.rotation_euler = (rot @ Matrix.Rotation(radians(roll), 3, "Z")).to_euler()
    bpy.context.view_layer.update()
    return rot @ centre_local


def calibrate_tokens(iterations=4, verbose=True):
    global _current_collection
    scene = bpy.context.scene
    tokens = list(TOKENS_HEX.keys())
    targets = {t: hex_to_linear(TOKENS_HEX[t])[:3] for t in tokens}
    for t in tokens:
        TOKEN_BASE[t] = list(targets[t])
    tmp_path = os.path.join(bpy.app.tempdir or HERE, "kursorqr_calibration.png")
    n = len(tokens)
    old_samples = scene.eevee.taa_render_samples
    scene.eevee.taa_render_samples = min(old_samples, 16)
    for it in range(iterations):
        _MATERIALS.clear()
        coll = bpy.data.collections.new("Calibration")
        scene.collection.children.link(coll)
        _current_collection = coll
        step = 0.24
        for i, t in enumerate(tokens):
            slab(t, 0.2, 0.2, 0.05, t, radius=0.01, location=((i - (n - 1) / 2) * step, 0, 0))
        _current_collection = None
        bpy.context.view_layer.update()
        res_x, res_y = n * 40, 40
        scene.render.resolution_x, scene.render.resolution_y = res_x, res_y
        cam = bpy.data.objects["IconCamera"]
        centre = frame_ortho(cam, all_mesh_objects(coll), res_x, res_y, fill=1.0, rx=0, rz=0)
        scene.camera = cam
        place_lights(cam, bpy.data.objects["KeyLight"], bpy.data.objects["FillLight"],
                     target=centre, distance=LIGHT_DISTANCE)
        scene.render.filepath = tmp_path
        bpy.ops.render.render(write_still=True)
        img = bpy.data.images.load(tmp_path)
        w, h = img.size
        px = np.array(img.pixels[:], dtype=np.float64).reshape(h, w, 4)
        bpy.data.images.remove(img)
        max_err = 0.0
        for i, t in enumerate(tokens):
            cx = int((i + 0.5) / n * w)
            got = px[h // 2 - 3:h // 2 + 4, cx - 3:cx + 4, :3].mean(axis=(0, 1))
            want = targets[t]
            base = TOKEN_BASE[t]
            for k in range(3):
                ratio = max(0.5, min(2.0, want[k] / max(got[k], 1e-4)))
                base[k] = max(0.0, min(1.0, base[k] * ratio))
            err = max(abs(linear_to_srgb(got[k]) - linear_to_srgb(want[k])) for k in range(3)) * 255
            max_err = max(max_err, err)
        if verbose:
            print(f"[clay] calibration pass {it + 1}: max error {max_err:.1f}/255")
        for o in list(coll.objects):
            mesh = o.data
            bpy.data.objects.remove(o, do_unlink=True)
            bpy.data.meshes.remove(mesh)
        bpy.data.collections.remove(coll)
        bpy.context.view_layer.update()
    _MATERIALS.clear()
    scene.eevee.taa_render_samples = old_samples
    if os.path.exists(tmp_path):
        try:
            os.remove(tmp_path)
        except OSError:
            pass


# --------------------------------------------------------------------------------------
# KursorQR bespoke 3D clay asset builders
# --------------------------------------------------------------------------------------


def build_logo():
    """Chunky Deep Rust squircle with three embossed Pearl QR finder blocks + warm Gold cursor."""
    slab("logo_base", 2.0, 2.0, 0.24, "primary", radius=0.48, bevel_frac=0.14)
    qr_finder("logo_tl", 0.58, 0.14, "clay", inner_token="primary", dot_token="goldLight",
              location=(-0.44, 0.44, 0.15))
    qr_finder("logo_tr", 0.58, 0.14, "clay", inner_token="primary", dot_token="goldLight",
              location=(0.44, 0.44, 0.15))
    qr_finder("logo_bl", 0.58, 0.14, "clay", inner_token="primary", dot_token="goldLight",
              location=(-0.44, -0.44, 0.15))
    cursor_arrow("logo_cursor", scale=0.82, thickness=0.18, token="gold",
                 location=(0.40, -0.36, 0.21), rotation=(0, 0, 22))


def build_hero_qr_scene():
    """Signature Landing Hero composition: sculptural cream QR clay card flanked by leaning
    forest-green iPhone & Galaxy slabs, floating gold cursor beacon, and tiny route tiles."""
    # Central hero QR slab
    qr_root = bpy.data.objects.new("hero_qr_root", None)
    _link(qr_root)
    card = slab("hero_qr_card", 1.75, 1.75, 0.20, "clay", radius=0.28, bevel_frac=0.28)
    card.parent = qr_root
    qr_finder("hq_tl", 0.46, 0.10, "primary", inner_token="clay", dot_token="primaryDeep",
              location=(-0.46, 0.46, 0.12), parent=qr_root)
    qr_finder("hq_tr", 0.46, 0.10, "primary", inner_token="clay", dot_token="primaryDeep",
              location=(0.46, 0.46, 0.12), parent=qr_root)
    qr_finder("hq_bl", 0.46, 0.10, "primary", inner_token="clay", dot_token="primaryDeep",
              location=(-0.46, -0.46, 0.12), parent=qr_root)
    # Embossed clay QR data modules
    dots = [
        (0.0, 0.48), (0.0, 0.24), (0.0, -0.44),
        (-0.46, 0.0), (-0.22, 0.0), (0.24, 0.0), (0.48, 0.0),
        (0.24, -0.24), (0.48, -0.24), (0.48, -0.48), (0.22, -0.48),
    ]
    for i, (dx, dy) in enumerate(dots):
        d = slab(f"hq_dot_{i}", 0.15, 0.15, 0.09, "primaryLight" if i % 3 == 0 else "primary",
                 radius=0.055, bevel_frac=0.25, location=(dx, dy, 0.115))
        d.parent = qr_root
    # Center gold clay badge
    badge = slab("hq_center", 0.40, 0.40, 0.13, "gold", radius=0.14, bevel_frac=0.28, location=(0, 0, 0.14))
    badge.parent = qr_root
    qr_root.location = (0.0, 0.0, 0.95)
    qr_root.rotation_euler = (radians(76), radians(-4), radians(-6))

    # Left leaning iPhone clay slab
    iphone = phone("hero_iphone", 0.92, 1.82, 0.16, body="primaryDeep", screen="clay",
                   radius=0.18, location=(-1.42, -0.26, 0.92), rotation=(80, -6, 16))
    # Tiny gold notification pill on iPhone
    p1 = slab("hero_ip_pill", 0.44, 0.20, 0.07, "gold", radius=0.09, location=(0, 0.34, 0.13))
    p1.parent = iphone

    # Right leaning Galaxy clay slab
    galaxy = phone("hero_galaxy", 0.90, 1.80, 0.16, body="primary", screen="clay",
                   radius=0.22, camera_dot=True, location=(1.44, -0.20, 0.86), rotation=(82, 7, -18))
    p2 = slab("hero_ga_pill", 0.44, 0.20, 0.07, "mint", radius=0.09, location=(0, 0.30, 0.13))
    p2.parent = galaxy

    # Floating gold cursor hovering cleanly in front top-right of the QR slab
    cursor_arrow("hero_cursor", scale=0.72, thickness=0.16, token="gold",
                 location=(0.88, -0.34, 1.96), rotation=(72, 10, -18))

    # Floating mini clay accent tiles for balance
    t1 = slab("hero_float_l", 0.56, 0.56, 0.10, "butter", radius=0.16,
              location=(-1.06, -0.22, 2.08), rotation=(72, -16, 14))
    sphere("hero_float_l_dot", 0.12, "gold", location=(0, 0, 0.09)).parent = t1

    t2 = slab("hero_float_r", 0.62, 0.44, 0.10, "mint", radius=0.14,
              location=(0.94, -0.44, -0.04), rotation=(76, 10, -14))
    sphere("hero_float_r_dot", 0.10, "primary", location=(-0.12, 0, 0.08)).parent = t2
    sphere("hero_float_r_dot2", 0.10, "gold", location=(0.12, 0, 0.08)).parent = t2


def build_feature_routing():
    """Clay phone slab with two directional route arrows (iOS / Android split)."""
    phone("feat_phone", 0.92, 1.65, 0.18, body="primary", screen="clay",
          radius=0.18, location=(-0.22, 0, 0.85), rotation=(78, 0, 10))
    # Two stacked route capsules floating beside it
    slab("route_ios", 0.82, 0.34, 0.16, "gold", radius=0.15,
         location=(0.45, 0.26, 1.18), rotation=(78, 0, -8))
    slab("route_and", 0.82, 0.34, 0.16, "sage", radius=0.15,
         location=(0.52, 0.22, 0.66), rotation=(78, 0, -8))


def build_feature_studio():
    """Clay QR tile with three colorful clay palette beads."""
    slab("studio_tile", 1.45, 1.45, 0.24, "clay", radius=0.30)
    qr_finder("st_f1", 0.44, 0.12, "primary", inner_token="clay", dot_token="primaryDeep",
              location=(-0.34, 0.32, 0.15))
    qr_finder("st_f2", 0.44, 0.12, "primaryLight", inner_token="clay", dot_token="primary",
              location=(-0.34, -0.32, 0.15))
    sphere("st_bead1", 0.22, "gold", location=(0.36, 0.34, 0.26), scale=(1, 1, 0.72))
    sphere("st_bead2", 0.22, "coral", location=(0.40, -0.10, 0.26), scale=(1, 1, 0.72))
    sphere("st_bead3", 0.20, "primary", location=(0.12, -0.40, 0.26), scale=(1, 1, 0.72))


def build_feature_gdpr():
    """Forest-green clay shield with embossed gold checkmark."""
    shield_mesh("gdpr_shield", 1.55, 1.85, 0.30, "primary")
    box("gdpr_chk_a", (0.42, 0.18, 0.16), "gold", location=(-0.18, -0.10, 0.20), rotation=(0, 0, -45))
    box("gdpr_chk_b", (0.78, 0.18, 0.16), "gold", location=(0.16, 0.06, 0.20), rotation=(0, 0, 45))


def build_metric_links():
    """Two interlocking clay chain links in forest green and gold."""
    torus_link("link_a", 0.46, 0.15, "primary", location=(-0.30, 0.0, 0.0),
               rotation=(25, 15, 35), scale=(1.35, 0.85, 1.0))
    torus_link("link_b", 0.46, 0.15, "gold", location=(0.30, 0.0, 0.08),
               rotation=(-55, -15, 35), scale=(1.35, 0.85, 1.0))


def build_metric_scans():
    """Cream clay QR scanner frame with bright gold scan beam."""
    slab("scan_bg", 1.45, 1.45, 0.20, "clay", radius=0.28)
    # 4 corner L brackets approximated by corner blocks
    for i, (cx, cy) in enumerate([(-0.44, 0.44), (0.44, 0.44), (-0.44, -0.44), (0.44, -0.44)]):
        slab(f"sc_c{i}", 0.34, 0.34, 0.12, "primary", radius=0.10, location=(cx, cy, 0.13))
    slab("scan_beam", 1.24, 0.18, 0.16, "gold", radius=0.09, location=(0, 0, 0.20))


def build_metric_ios():
    phone("met_ios", 0.92, 1.78, 0.20, body="primaryDeep", screen="clay",
          radius=0.18, location=(0, 0, 0.90), rotation=(78, 0, -10))


def build_metric_android():
    phone("met_and", 0.92, 1.78, 0.20, body="primary", screen="mint",
          radius=0.24, camera_dot=True, location=(0, 0, 0.90), rotation=(78, 0, 10))


def build_empty_qr_links():
    """Tilted cream clay QR frame with floating gold plus badge."""
    slab("emp_card", 1.75, 1.75, 0.18, "clay", radius=0.32, location=(0, 0, 0.0), rotation=(0, 0, -6))
    slab("emp_well", 1.28, 1.28, 0.10, "sand", radius=0.22, location=(0, 0, 0.10), rotation=(0, 0, -6))
    # Floating gold plus puck
    cylinder("emp_puck", 0.42, 0.18, "gold", location=(0.56, 0.54, 0.32))
    box("emp_plus_h", (0.42, 0.12, 0.12), "clay", location=(0.56, 0.54, 0.43))
    box("emp_plus_v", (0.12, 0.42, 0.12), "clay", location=(0.56, 0.54, 0.43))


def build_verify_envelope():
    """Chunky cream clay envelope with forest-green inner flap and gold wax seal."""
    slab("env_body", 1.80, 1.24, 0.26, "clay", radius=0.22)
    # V-flap ridges
    box("env_flap_l", (1.02, 0.14, 0.12), "clayDeep", location=(-0.38, 0.14, 0.16), rotation=(0, 0, -34))
    box("env_flap_r", (1.02, 0.14, 0.12), "clayDeep", location=(0.38, 0.14, 0.16), rotation=(0, 0, 34))
    # Gold wax seal
    cylinder("env_seal", 0.28, 0.14, "gold", location=(0, -0.06, 0.22))
    sphere("env_seal_gem", 0.11, "primary", location=(0, -0.06, 0.31), scale=(1, 1, 0.6))


def build_icon_studio():
    slab("ico_st_base", 1.5, 1.5, 0.24, "primary", radius=0.32)
    sphere("ico_st_1", 0.24, "gold", location=(-0.30, 0.28, 0.24), scale=(1, 1, 0.7))
    sphere("ico_st_2", 0.24, "coral", location=(0.32, 0.22, 0.24), scale=(1, 1, 0.7))
    sphere("ico_st_3", 0.24, "clay", location=(-0.10, -0.32, 0.24), scale=(1, 1, 0.7))


def build_icon_link():
    build_metric_links()


def build_icon_account():
    """Sculptural clay user avatar bust."""
    sphere("acc_head", 0.42, "gold", location=(0, 0.44, 0.22))
    slab("acc_body", 1.32, 0.76, 0.42, "primary", radius=0.36, location=(0, -0.36, 0.18))


def build_icon_shield():
    build_feature_gdpr()


def build_toast_check():
    box("chk_s", (0.72, 0.28, 0.28), "clay", location=(-0.34, -0.18, 0), rotation=(0, 0, -45))
    box("chk_l", (1.26, 0.28, 0.28), "clay", location=(0.22, 0.05, 0), rotation=(0, 0, 45))


def build_toast_error():
    box("err_a", (1.36, 0.28, 0.28), "clay", rotation=(0, 0, 45))
    box("err_b", (1.36, 0.28, 0.28), "clay", rotation=(0, 0, -45))


# --------------------------------------------------------------------------------------
# Render driver
# --------------------------------------------------------------------------------------


def render_asset(name, build_fn, size, camera="iso", fill=0.82, rx=None, rz=None, light_distance=None, roll=0.0):
    global _current_collection
    scene = bpy.context.scene
    if OPTS["only"] and name not in OPTS["only"]:
        return
    coll = bpy.data.collections.new(name)
    scene.collection.children.link(coll)
    _current_collection = coll
    build_fn()
    _current_collection = None
    bpy.context.view_layer.update()

    objs = all_mesh_objects(coll)
    res_x = max(16, int(round(size[0] * 2 * OPTS["scale"])))
    res_y = max(16, int(round(size[1] * 2 * OPTS["scale"])))
    scene.render.resolution_x = res_x
    scene.render.resolution_y = res_y

    if camera == "persp":
        cam = bpy.data.objects["HeroCamera"]
        centre = frame_persp(cam, objs, res_x, res_y, fill=fill,
                             rx=62.0 if rx is None else rx,
                             rz=10.0 if rz is None else rz,
                             roll=roll)
    else:
        cam = bpy.data.objects["IconCamera"]
        centre = frame_ortho(cam, objs, res_x, res_y, fill=fill,
                             rx=46.0 if rx is None else rx,
                             rz=32.0 if rz is None else rz)

    scene.camera = cam
    place_lights(cam, bpy.data.objects["KeyLight"], bpy.data.objects["FillLight"],
                 target=centre, distance=light_distance or LIGHT_DISTANCE)

    out_path = os.path.join(OUT_DIR, f"{name}.png")
    scene.render.filepath = out_path
    bpy.ops.render.render(write_still=True)
    print(f"[clay] rendered {name}.png ({res_x}x{res_y})")

    # Park collection on a grid for the saved .blend file and hide for next render
    idx = len(ASSET_COLLECTIONS)
    gx = (idx % 5) * GRID_STEP
    gy = (idx // 5) * GRID_STEP
    for o in coll.objects:
        if o.parent is None:
            o.location = (o.location.x + gx, o.location.y + gy, o.location.z)
    coll.hide_render = True
    ASSET_COLLECTIONS.append((coll, (gx, gy)))


ASSETS = [
    ("kursorqr_logo_3d", build_logo, (256, 256), "iso", {"rx": 0, "rz": 0, "fill": 0.94}),
    ("hero_qr_scene", build_hero_qr_scene, (720, 560), "persp", {"fill": 0.86, "rx": 64, "rz": 8, "roll": -2.5, "light_distance": 6.5}),
    ("feature_routing", build_feature_routing, (56, 56), "iso", {"rx": 58, "rz": 18, "fill": 0.84}),
    ("feature_studio", build_feature_studio, (56, 56), "iso", {"rx": 36, "rz": 22, "fill": 0.86}),
    ("feature_gdpr", build_feature_gdpr, (56, 56), "iso", {"rx": 24, "rz": -14, "fill": 0.86}),
    ("metric_links", build_metric_links, (40, 40), "iso", {"rx": 34, "rz": 18, "fill": 0.86}),
    ("metric_scans", build_metric_scans, (40, 40), "iso", {"rx": 32, "rz": 20, "fill": 0.86}),
    ("metric_ios", build_metric_ios, (40, 40), "iso", {"rx": 60, "rz": 22, "fill": 0.84}),
    ("metric_android", build_metric_android, (40, 40), "iso", {"rx": 60, "rz": -20, "fill": 0.84}),
    ("empty_qr_links", build_empty_qr_links, (200, 200), "iso", {"rx": 38, "rz": 18, "fill": 0.86}),
    ("verify_envelope", build_verify_envelope, (88, 88), "iso", {"rx": 32, "rz": -14, "fill": 0.86}),
    ("icon_studio", build_icon_studio, (40, 40), "iso", {"rx": 34, "rz": 20, "fill": 0.86}),
    ("icon_link", build_icon_link, (40, 40), "iso", {"rx": 34, "rz": 18, "fill": 0.86}),
    ("icon_account", build_icon_account, (40, 40), "iso", {"rx": 26, "rz": -14, "fill": 0.86}),
    ("icon_shield", build_icon_shield, (40, 40), "iso", {"rx": 24, "rz": -14, "fill": 0.86}),
    ("toast_check", build_toast_check, (28, 28), "iso", {"rx": 20, "rz": 0, "fill": 0.82}),
    ("toast_error", build_toast_error, (28, 28), "iso", {"rx": 20, "rz": 0, "fill": 0.82}),
]


# --------------------------------------------------------------------------------------
# Seamless 256x256 paper grain tile
# --------------------------------------------------------------------------------------


def _periodic_value_noise(size, cells, rng):
    grid = rng.random((cells, cells))
    x = np.linspace(0, cells, size, endpoint=False)
    xi = np.floor(x).astype(int)
    xf = x - xi
    s = xf * xf * (3 - 2 * xf)
    xi0 = xi % cells
    xi1 = (xi + 1) % cells
    g00 = grid[np.ix_(xi0, xi0)]
    g10 = grid[np.ix_(xi1, xi0)]
    g01 = grid[np.ix_(xi0, xi1)]
    g11 = grid[np.ix_(xi1, xi1)]
    sy = s[:, None]
    sx = s[None, :]
    top = g00 * (1 - sx) + g01 * sx
    bot = g10 * (1 - sx) + g11 * sx
    return top * (1 - sy) + bot * sy


def write_grain_tile(size=256):
    if OPTS["only"] and "grain_tile" not in OPTS["only"]:
        return
    rng = np.random.default_rng(2026)
    noise = np.zeros((size, size))
    amp_total = 0.0
    for cells, amp in ((16, 0.35), (32, 0.45), (64, 0.6), (128, 0.8)):
        noise += _periodic_value_noise(size, cells, rng) * amp
        amp_total += amp
    noise /= amp_total
    fine = rng.random((size, size))
    v = 0.55 * (noise - 0.5) + 0.45 * (fine - 0.5)
    v = v / (v.std() + 1e-9) * 0.1 + 0.5
    v = np.clip(v, 0.0, 1.0)
    img = bpy.data.images.new("grain_tile", size, size, alpha=False, float_buffer=False)
    img.colorspace_settings.name = "Non-Color"
    px = np.empty((size, size, 4), dtype=np.float32)
    px[..., 0] = v
    px[..., 1] = v
    px[..., 2] = v
    px[..., 3] = 1.0
    img.pixels.foreach_set(px.ravel())
    img.filepath_raw = os.path.join(OUT_DIR, "grain_tile.png")
    img.file_format = "PNG"
    img.save()
    print(f"[clay] wrote {img.filepath_raw}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    reset_scene()
    setup_lights_and_cameras()
    calibrate_tokens()
    for name, builder, size, camera, kw in ASSETS:
        render_asset(name, builder, size, camera=camera, **kw)
    write_grain_tile()

    for coll, _ in ASSET_COLLECTIONS:
        coll.hide_render = False
    if OPTS["blend"] and not OPTS["only"] and not OPTS["out"]:
        bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH, compress=True)
        print(f"[clay] saved {BLEND_PATH}")
    print("[clay] done")


if __name__ == "__main__":
    main()
