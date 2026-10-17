"""Live Wire tiles (batman_livewire_01, tiledef 7174) for Build 42.21.

Placeholder equipment made of simple geometric shapes (final models come later).
Contract with the Lua code (LW_Defs.lua): never renumber these indices.

  0-3     solar panel          S E N W   (outdoors)
  4-7     wind turbine         S E N W   (outdoors)
  8-11    water wheel          S E N W   (next to water)
  12-15   inverter             S E N W
  16-19   power bank           S E N W   (container livewirepowerbank)
  20-21   breaker panel        S E (wall object: north wall, west wall)
  22-23   low battery alarm    S E (wall object: north wall, west wall)

Overlays (attachedAnimSprite, set by the client, LW_Visuals.lua; no properties):
  24-27   inverter running: lit screen and green light   S E N W
  28-31   inverter fault: red light                      S E N W
  32-35   power bank connected: green light              S E N W
  36-39   solar panel connected: green light             S E N W
  40-43   wind turbine connected: green light            S E N W
  44-47   water wheel connected: green light             S E N W
  48-63   wind turbine blades, frame f (0-3), facing k:  48 + 4 * f + k
  64-65   breaker tripped: red lamp                      S E
  66-67   alarm ringing: lit beacon                      S E
The wind turbine tiles 4-7 have no blades: the client always draws a blade frame.

Needs pz-sprite-forge (MIT, https://github.com/Leeheejin/pz-sprite-forge).
1. Render every cell, headless:
       set PZ_FORGE=E:\\pz-tools\\pz-sprite-forge
       blender -b --factory-startup -P source/tiles/build_livewire_tiles.py -- <cells-dir> [<group>... preview]
2. Style and package (Python with Pillow):
       python source/tiles/build_livewire_tiles.py package <cells-dir> <project-root> [--no-preview]
   -> Contents/mods/batman_LiveWire/common/media/texturepacks/batman_livewire_01.pack
      Contents/mods/batman_LiveWire/common/media/batman_livewire_01.tiles
3. Depth map (skill pz-blender-assets, scripts/build_depthmap.py):
       blender -b --factory-startup -P <skill>/scripts/build_depthmap.py -- source/tiles/build_livewire_tiles.py depth.json
       python <skill>/scripts/build_depthmap.py depth.json <mod>/common/media/texturepacks/batman_livewire_01.pack
           batman_livewire_01 <mod>/common/media/depthmaps/DEPTH_batman_livewire_01.png
"""
from __future__ import annotations

import json
import math
import os
import sys
from pathlib import Path

try:
    import bpy
    from mathutils import Vector
except ImportError:  # packaging step, plain Python
    bpy = None

FORGE = Path(os.environ.get("PZ_FORGE", "pz-sprite-forge"))
sys.path.insert(0, str(FORGE / "blender"))
sys.path.insert(0, str(FORGE))
if bpy is not None:
    import pz_sprite_forge as F  # noqa: E402

SHEET = "batman_livewire_01"
TILEDEF_ID = 7174
MOD_ID = "batman_LiveWire"

#: Wall objects: gap between the back of the object and the tile edge (wall face).
WALL_GAP = 0.035

PAINTS = {
    "steel": ("metal", (0.55, 0.57, 0.60)),
    "darksteel": ("metal", (0.20, 0.21, 0.23)),
    "cabinet": ("metal", (0.62, 0.64, 0.62)),
    "bankbody": ("metal", (0.18, 0.30, 0.22)),
    "cell": ("metal", (0.06, 0.10, 0.28)),
    "cellgrid": ("metal", (0.70, 0.72, 0.76)),
    "blade": ("fabric", (0.88, 0.88, 0.86)),
    "wood": ("wood", (0.45, 0.27, 0.12)),
    "darkwood": ("wood", (0.30, 0.18, 0.08)),
    "battery": ("fabric", (0.08, 0.08, 0.09)),
    "red": ("fabric", (0.75, 0.08, 0.06)),
    "green": ("fabric", (0.10, 0.70, 0.18)),
    "screen": ("fabric", (0.15, 0.55, 0.30)),
    "yellow": ("fabric", (0.90, 0.72, 0.06)),
    "black": ("fabric", (0.03, 0.03, 0.035)),
    "white": ("fabric", (0.88, 0.88, 0.84)),
    "copper": ("metal", (0.72, 0.42, 0.20)),
    "ledoff": ("fabric", (0.10, 0.12, 0.10)),
    "screenoff": ("fabric", (0.05, 0.08, 0.07)),
    "greenlit": ("fabric", (0.40, 1.00, 0.40)),
    "screenlit": ("fabric", (0.55, 1.00, 0.70)),
    "redlit": ("fabric", (1.00, 0.30, 0.18)),
}


def materials() -> dict:
    return {key: F.forge_material(f"batman_lw_{key}", cls, paint)
            for key, (cls, paint) in PAINTS.items()}


# --------------------------------------------------------------------------- #
# Mesh kit (data API only: works headless and in a dedicated MCP scene)
# --------------------------------------------------------------------------- #

class Kit:
    """Parts parented to an anchor (the forge subject or a sub-empty)."""

    def __init__(self, anchor, mats):
        self.anchor, self.mats = anchor, mats

    def empty(self, name, loc=(0, 0, 0), rot=(0, 0, 0)) -> "Kit":
        obj = bpy.data.objects.new(name, None)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent, obj.location, obj.rotation_euler = self.anchor, loc, rot
        return Kit(obj, self.mats)

    def mesh(self, name, verts, faces, mat, loc=(0, 0, 0), rot=(0, 0, 0), smooth=False):
        me = bpy.data.meshes.new(name)
        me.from_pydata([tuple(v) for v in verts], [], faces)
        me.update()
        if smooth:
            for poly in me.polygons:
                poly.use_smooth = True
        obj = bpy.data.objects.new(name, me)
        bpy.context.scene.collection.objects.link(obj)
        obj.data.materials.append(self.mats[mat])
        obj.parent, obj.location, obj.rotation_euler = self.anchor, loc, rot
        return obj

    def box(self, name, c, size, mat, rot=(0, 0, 0), bevel=0.0):
        sx, sy, sz = (s / 2 for s in size)
        verts = [(x, y, z) for z in (-sz, sz) for y in (-sy, sy) for x in (-sx, sx)]
        faces = [(0, 2, 3, 1), (4, 5, 7, 6), (0, 1, 5, 4), (2, 6, 7, 3), (0, 4, 6, 2), (1, 3, 7, 5)]
        obj = self.mesh(name, verts, faces, mat, c, rot)
        if bevel:
            mod = obj.modifiers.new("bevel", "BEVEL")
            mod.width, mod.segments = min(size) * bevel, 2
        return obj

    def cyl(self, name, c, r, depth, mat, rot=(0, 0, 0), segs=24, caps=True):
        verts = [(r * math.cos(2 * math.pi * j / segs), r * math.sin(2 * math.pi * j / segs), z)
                 for z in (-depth / 2, depth / 2) for j in range(segs)]
        faces = [(j, (j + 1) % segs, segs + (j + 1) % segs, segs + j) for j in range(segs)]
        if caps:
            faces += [tuple(reversed(range(segs))), tuple(range(segs, 2 * segs))]
        return self.mesh(name, verts, faces, mat, c, rot)

    def _aligned(self, obj, p0, p1):
        a, b = Vector(p0), Vector(p1)
        obj.location = (a + b) / 2
        obj.rotation_euler = (b - a).to_track_quat("Z", "Y").to_euler()
        return obj

    def rod(self, name, p0, p1, r, mat, segs=10):
        length = (Vector(p1) - Vector(p0)).length
        return self._aligned(self.cyl(name, (0, 0, 0), r, length, mat, segs=segs), p0, p1)

    def beam(self, name, p0, p1, w, d, mat):
        length = (Vector(p1) - Vector(p0)).length
        return self._aligned(self.box(name, (0, 0, 0), (w, d, length), mat), p0, p1)


def mark_holdout(root) -> None:
    """Hide the base parts of an overlay render (they still occlude the overlay)."""
    stack = list(root.children)
    while stack:
        obj = stack.pop()
        stack.extend(obj.children)
        obj.is_holdout = True


def clear_subject(subject) -> None:
    stack, doomed = list(subject.children), []
    while stack:
        obj = stack.pop()
        stack.extend(obj.children)
        doomed.append(obj)
    for obj in doomed:
        data = obj.data
        bpy.data.objects.remove(obj, do_unlink=True)
        if data is not None and data.users == 0:
            bpy.data.meshes.remove(data)


# --------------------------------------------------------------------------- #
# Equipment (front towards -Y, origin at the tile centre on the floor)
# --------------------------------------------------------------------------- #

def build_solar(k: Kit):
    """Ground-mounted panel tilted towards the front, on a steel frame."""
    tilt = math.radians(35)
    w, h, t = 0.92, 0.66, 0.035
    zc = 0.52
    panel = k.empty("solar_panel", (0, 0.02, zc), (-tilt, 0, 0))
    panel.box("solar_frame", (0, 0, 0), (w, t, h), "cellgrid")
    cols, rows = 4, 3
    cw, ch = (w - 0.06) / cols, (h - 0.06) / rows
    for i in range(cols):
        for j in range(rows):
            x = -w / 2 + 0.03 + cw * (i + 0.5)
            z = -h / 2 + 0.03 + ch * (j + 0.5)
            panel.box(f"solar_cell_{i}_{j}", (x, -t / 2 - 0.004, z), (cw - 0.014, 0.01, ch - 0.014), "cell")
    # frame: two A legs and a cross bar
    for sx in (-1, 1):
        x = sx * (w / 2 - 0.08)
        k.beam(f"solar_leg_front_{sx}", (x, -0.18, 0.0), (x, -0.16, 0.30), 0.035, 0.035, "steel")
        k.beam(f"solar_leg_back_{sx}", (x, 0.30, 0.0), (x, 0.22, 0.70), 0.035, 0.035, "steel")
        k.box(f"solar_foot_{sx}", (x, 0.06, 0.012), (0.06, 0.62, 0.024), "darksteel")
    k.beam("solar_brace", (-w / 2 + 0.08, 0.26, 0.36), (w / 2 - 0.08, 0.26, 0.36), 0.03, 0.03, "steel")
    k.box("solar_junction", (0.30, 0.25, 0.30), (0.12, 0.06, 0.10), "darksteel")
    k.box("solar_status", (0.40, -0.17, 0.08), (0.08, 0.06, 0.08), "darksteel")
    k.box("solar_led", (0.40, -0.2015, 0.09), (0.07, 0.003, 0.07), "ledoff")


def build_solar_led(k: Kit):
    build_solar(k)
    mark_holdout(k.anchor)
    return [k.box("solar_led_on", (0.40, -0.2045, 0.09), (0.075, 0.003, 0.075), "greenlit")]


WIND_TOP = 1.90
WIND_HUB_Y = -0.22


def wind_blades(k: Kit, frame: int):
    """Three blades turned by 30 degrees per frame (four frames cover 120 degrees)."""
    rotor = k.empty(f"wind_rotor_{frame}", (0, WIND_HUB_Y - 0.02, WIND_TOP + 0.06),
                    (0, math.radians(15 + 30 * frame), 0))
    for b in range(3):
        a = math.radians(90 + 120 * b)
        blade = rotor.empty(f"wind_blade_{frame}_{b}", (0, 0, 0), (0, -a + math.radians(90), 0))
        blade.box(f"wind_blade_mesh_{frame}_{b}", (0, 0, 0.32), (0.07, 0.02, 0.58), "blade")
    return rotor


def build_wind(k: Kit, blades=True):
    """Small turbine on a mast, tail to the back. The tiles have no blades (blades=False):
    they are overlays animated by the client."""
    top = WIND_TOP
    k.box("wind_base", (0, 0, 0.03), (0.42, 0.42, 0.06), "darksteel")
    for a in (45, 135, 225, 315):
        r = math.radians(a)
        k.rod(f"wind_stay_{a}", (0.36 * math.cos(r), 0.36 * math.sin(r), 0.0), (0, 0, 0.9), 0.008, "steel")
    k.rod("wind_mast", (0, 0, 0.05), (0, 0, top), 0.045, "steel")
    k.box("wind_nacelle", (0, 0.02, top + 0.06), (0.16, 0.42, 0.16), "cabinet", bevel=0.25)
    k.rod("wind_tailboom", (0, 0.2, top + 0.06), (0, 0.55, top + 0.08), 0.015, "steel")
    k.box("wind_tail", (0, 0.58, top + 0.10), (0.012, 0.18, 0.24), "cabinet")
    hub_y = WIND_HUB_Y
    k.rod("wind_hub", (0, hub_y + 0.03, top + 0.06), (0, hub_y - 0.06, top + 0.06), 0.06, "darksteel")
    k.box("wind_status", (0.12, -0.15, 0.10), (0.08, 0.06, 0.08), "darksteel")
    k.box("wind_led", (0.12, -0.1815, 0.11), (0.07, 0.003, 0.07), "ledoff")
    if blades:
        wind_blades(k, 0)


def build_wind_led(k: Kit):
    build_wind(k, blades=False)
    mark_holdout(k.anchor)
    return [k.box("wind_led_on", (0.12, -0.1845, 0.11), (0.075, 0.003, 0.075), "greenlit")]


def build_wind_rotor(frame: int):
    def fn(k: Kit):
        build_wind(k, blades=False)
        mark_holdout(k.anchor)
        return [wind_blades(k, frame)]
    return fn


def build_hydro(k: Kit):
    """Paddle wheel in a wooden frame with a small generator box; wheel to the front."""
    zc, r = 0.50, 0.44
    wheel = k.empty("hydro_wheel", (0, -0.12, zc))
    # two rims (axle along X)
    for sx in (-1, 1):
        wheel.cyl(f"hydro_rim_{sx}", (sx * 0.16, 0, 0), r, 0.035, "darkwood", rot=(0, math.radians(90), 0), segs=32)
        wheel.cyl(f"hydro_rim_in_{sx}", (sx * 0.16, 0, 0), r - 0.05, 0.04, "wood",
                  rot=(0, math.radians(90), 0), segs=32)
    for p in range(10):
        a = 2 * math.pi * p / 10
        y, z = (r - 0.04) * math.cos(a), (r - 0.04) * math.sin(a)
        wheel.box(f"hydro_paddle_{p}", (0, y, z), (0.36, 0.03, 0.14), "wood", rot=(-a, 0, 0))
    for p in range(5):
        a = math.pi * p / 5
        wheel.rod(f"hydro_spoke_{p}", (0, (r - 0.06) * math.cos(a), (r - 0.06) * math.sin(a)),
                  (0, -(r - 0.06) * math.cos(a), -(r - 0.06) * math.sin(a)), 0.015, "darkwood")
    k.rod("hydro_axle", (-0.36, -0.12, zc), (0.36, -0.12, zc), 0.03, "steel")
    for sx in (-1, 1):
        x = sx * 0.30
        k.beam(f"hydro_post_a_{sx}", (x, -0.40, 0.0), (x, -0.12, zc + 0.02), 0.05, 0.05, "darkwood")
        k.beam(f"hydro_post_b_{sx}", (x, 0.16, 0.0), (x, -0.12, zc + 0.02), 0.05, 0.05, "darkwood")
        k.box(f"hydro_sill_{sx}", (x, -0.12, 0.02), (0.07, 0.62, 0.04), "darkwood")
    k.box("hydro_generator", (0.40, -0.12, zc), (0.14, 0.18, 0.18), "cabinet", bevel=0.2)
    k.box("hydro_genplate", (0.40, -0.12, zc - 0.13), (0.18, 0.24, 0.04), "darksteel")
    k.rod("hydro_genpost", (0.40, -0.12, 0.0), (0.40, -0.12, zc - 0.15), 0.025, "steel")
    k.box("hydro_status", (0.40, -0.36, 0.05), (0.08, 0.06, 0.10), "darksteel")
    k.box("hydro_led", (0.40, -0.3915, 0.07), (0.07, 0.003, 0.07), "ledoff")


def build_hydro_led(k: Kit):
    build_hydro(k)
    mark_holdout(k.anchor)
    return [k.box("hydro_led_on", (0.40, -0.3945, 0.07), (0.075, 0.003, 0.075), "greenlit")]


def build_inverter(k: Kit):
    """Floor cabinet with a small screen, status lights and vents on the front."""
    w, d, h = 0.56, 0.38, 0.92
    k.box("inv_body", (0, 0, h / 2 + 0.04), (w, d, h), "cabinet", bevel=0.04)
    k.box("inv_plinth", (0, 0, 0.02), (w - 0.04, d - 0.04, 0.04), "darksteel")
    fy = -d / 2 - 0.006
    k.box("inv_screen_frame", (0, fy, 0.74), (0.30, 0.012, 0.16), "darksteel")
    k.box("inv_screen", (0, fy - 0.004, 0.74), (0.26, 0.01, 0.12), "screenoff")
    k.box("inv_led_green", (-0.12, fy - 0.004, 0.60), (0.04, 0.012, 0.035), "ledoff")
    k.box("inv_led_red", (-0.05, fy - 0.004, 0.60), (0.04, 0.012, 0.035), "ledoff")
    k.box("inv_switch", (0.13, fy - 0.01, 0.60), (0.06, 0.02, 0.08), "black")
    for v in range(5):
        k.box(f"inv_vent_{v}", (0, fy - 0.002, 0.22 + v * 0.055), (0.38, 0.008, 0.022), "darksteel")
    k.box("inv_warning", (0, fy - 0.004, 0.46), (0.14, 0.008, 0.07), "yellow")
    k.box("inv_warning_mark", (0, fy - 0.008, 0.46), (0.02, 0.006, 0.045), "black")
    k.rod("inv_cable", (0.20, d / 2 - 0.05, 0.94), (0.20, d / 2 - 0.05, 1.05), 0.02, "black")


INV_FY = -0.38 / 2 - 0.006


def build_inverter_on(k: Kit):
    build_inverter(k)
    mark_holdout(k.anchor)
    fy = INV_FY
    screen = k.box("inv_screen_on", (0, fy - 0.0105, 0.74), (0.262, 0.003, 0.122), "screenlit")
    led = k.box("inv_led_green_on", (-0.12, fy - 0.0115, 0.60), (0.042, 0.003, 0.037), "greenlit")
    return [screen, led]


def build_inverter_fault(k: Kit):
    build_inverter(k)
    mark_holdout(k.anchor)
    return [k.box("inv_led_red_on", (-0.05, INV_FY - 0.0115, 0.60), (0.042, 0.003, 0.037), "redlit")]


def build_powerbank(k: Kit):
    """Open-top battery rack holding four car batteries (opens like a crate)."""
    w, d, h = 0.86, 0.52, 0.42
    t = 0.03
    k.box("bank_floor", (0, 0, 0.05), (w, d, 0.06), "bankbody")
    k.box("bank_front", (0, -d / 2 + t / 2, h / 2), (w, t, h), "bankbody")
    k.box("bank_back", (0, d / 2 - t / 2, h / 2), (w, t, h), "bankbody")
    for sx in (-1, 1):
        k.box(f"bank_side_{sx}", (sx * (w / 2 - t / 2), 0, h / 2), (t, d, h), "bankbody")
    k.box("bank_label", (0, -d / 2 - 0.004, h - 0.10), (0.30, 0.008, 0.10), "yellow")
    k.box("bank_label_mark", (0, -d / 2 - 0.009, h - 0.10), (0.16, 0.006, 0.03), "black")
    bw = (w - 2 * t - 0.05) / 4
    for b in range(4):
        x = -w / 2 + t + 0.01 + bw * (b + 0.5) + 0.01 * b
        k.box(f"bank_battery_{b}", (x, 0.0, 0.08 + 0.15), (bw - 0.02, d - 2 * t - 0.06, 0.30), "battery",
              bevel=0.05)
        k.cyl(f"bank_term_pos_{b}", (x - bw * 0.25, -0.08, 0.40), 0.018, 0.04, "red")
        k.cyl(f"bank_term_neg_{b}", (x + bw * 0.25, -0.08, 0.40), 0.018, 0.04, "darksteel")
    k.rod("bank_bus", (-w / 2 + 0.08, -0.08, 0.43), (w / 2 - 0.08, -0.08, 0.43), 0.01, "copper")
    k.box("bank_led", (0.32, -d / 2 - 0.004, h - 0.10), (0.075, 0.008, 0.075), "ledoff")


def build_powerbank_led(k: Kit):
    build_powerbank(k)
    mark_holdout(k.anchor)
    return [k.box("bank_led_on", (0.32, -0.52 / 2 - 0.0095, 0.42 - 0.10), (0.08, 0.003, 0.08), "greenlit")]


BRK_W, BRK_D, BRK_H, BRK_Z = 0.30, 0.08, 0.40, 1.40


def build_breaker(k: Kit):
    """Small wall breaker box on the north wall (y = +0.5)."""
    w, d, h, zc = BRK_W, BRK_D, BRK_H, BRK_Z
    yb = 0.5 - WALL_GAP - d / 2
    k.box("brk_body", (0, yb, zc), (w, d, h), "cabinet", bevel=0.06)
    fy = yb - d / 2 - 0.004
    k.box("brk_door", (0, fy, zc), (w - 0.04, 0.008, h - 0.04), "steel")
    for col in range(4):
        x = -0.09 + col * 0.06
        k.box(f"brk_switch_{col}", (x, fy - 0.010, zc + 0.04), (0.03, 0.016, 0.06), "black")
    k.box("brk_main", (-0.05, fy - 0.012, zc - 0.10), (0.08, 0.02, 0.06), "red")
    k.box("brk_lamp", (0.07, fy - 0.006, zc - 0.10), (0.065, 0.006, 0.065), "ledoff")
    k.rod("brk_conduit", (0.10, yb, zc + h / 2), (0.10, yb, zc + h / 2 + 0.20), 0.016, "darksteel")


def build_breaker_trip(k: Kit):
    build_breaker(k)
    mark_holdout(k.anchor)
    yb = 0.5 - WALL_GAP - BRK_D / 2
    fy = yb - BRK_D / 2 - 0.004
    return [k.box("brk_lamp_on", (0.07, fy - 0.0105, BRK_Z - 0.10), (0.07, 0.003, 0.07), "redlit")]


def build_alarm(k: Kit):
    """Small wall box with a red beacon and a speaker grille (north wall)."""
    w, d, h = 0.34, 0.11, 0.26
    zc = 1.55
    yb = 0.5 - WALL_GAP - d / 2
    k.box("alm_body", (0, yb, zc), (w, d, h), "white", bevel=0.08)
    fy = yb - d / 2
    k.cyl("alm_beacon", (0, yb - 0.01, zc + h / 2 + 0.05), 0.07, 0.10, "red")
    for g in range(4):
        k.box(f"alm_grille_{g}", (-0.05, fy - 0.004, zc - 0.07 + g * 0.045), (0.15, 0.008, 0.018), "black")
    k.box("alm_led", (0.10, fy - 0.004, zc), (0.035, 0.008, 0.035), "green")


def build_alarm_ring(k: Kit):
    build_alarm(k)
    mark_holdout(k.anchor)
    yb = 0.5 - WALL_GAP - 0.11 / 2
    return [k.cyl("alm_beacon_on", (0, yb - 0.01, 1.55 + 0.26 / 2 + 0.05), 0.078, 0.108, "redlit")]


GROUPS = [
    ("solar", [0, 1, 2, 3], build_solar),
    ("wind", [4, 5, 6, 7], lambda k: build_wind(k, blades=False)),
    ("hydro", [8, 9, 10, 11], build_hydro),
    ("inverter", [12, 13, 14, 15], build_inverter),
    ("powerbank", [16, 17, 18, 19], build_powerbank),
    ("breaker", [20, 21], build_breaker),
    ("alarm", [22, 23], build_alarm),
]

# Overlays drawn over a base tile (base rendered as a holdout).
OVERLAYS = [
    ("inverter_on", [24, 25, 26, 27], build_inverter_on),
    ("inverter_fault", [28, 29, 30, 31], build_inverter_fault),
    ("powerbank_led", [32, 33, 34, 35], build_powerbank_led),
    ("solar_led", [36, 37, 38, 39], build_solar_led),
    ("wind_led", [40, 41, 42, 43], build_wind_led),
    ("hydro_led", [44, 45, 46, 47], build_hydro_led),
] + [(f"wind_rotor{f}", [48 + 4 * f + i for i in range(4)], build_wind_rotor(f)) for f in range(4)] + [
    ("breaker_trip", [64, 65], build_breaker_trip),
    ("alarm_ring", [66, 67], build_alarm_ring),
]
ALL_GROUPS = GROUPS + OVERLAYS
OVERLAY_KEYS = {key for key, _, _ in OVERLAYS}


def tile_groups() -> list[dict]:
    """Every render group: key, sprite indices in facing order (S, E[, N, W]), builder."""
    return [{"key": key, "indices": idx, "overlay": key in OVERLAY_KEYS, "build": fn}
            for key, idx, fn in ALL_GROUPS]


def build_group(subject, mats, group) -> list:
    """Clear the subject and build one group; returns the overlay objects' names."""
    clear_subject(subject)
    overlay = group["build"](Kit(subject, mats)) or []
    names = set()
    stack = [getattr(part, "anchor", part) for part in overlay]
    while stack:
        obj = stack.pop()
        names.add(obj.name)
        stack.extend(obj.children)
    return sorted(names)


def build(subject, mats) -> None:
    """Showcase of every object (editable .blend, preview)."""
    k = Kit(subject, mats)
    spots = {"solar": (-2.2, -0.6), "wind": (-1.1, 0.4), "hydro": (0.0, -0.8), "inverter": (1.1, 0.4),
             "powerbank": (2.2, -0.4), "breaker": (0.5, 1.0), "alarm": (1.6, 1.0)}
    for key, _, fn in GROUPS:
        x, y = spots[key]
        if key == "wind":
            build_wind(k.empty("show_wind", (x, y, 0)), blades=True)
        else:
            fn(k.empty(f"show_{key}", (x, y, 0)))


# --------------------------------------------------------------------------- #
# Rendering (Blender)
# --------------------------------------------------------------------------- #

def render_preview(scene, subject, mats, out: str) -> None:
    clear_subject(subject)
    build(subject, mats)
    k = Kit(subject, mats)
    floor_mat = F.forge_material("batman_lw_floor", "wood", (0.30, 0.29, 0.26))
    wall_mat = F.forge_material("batman_lw_wallpv", "brick", (0.55, 0.55, 0.52))
    k.mats = dict(mats, floor=floor_mat, wallpv=wall_mat)
    k.box("pv_floor", (0.0, 0.0, -0.01), (12.0, 9.0, 0.02), "floor")
    k.box("pv_wall", (0.0, 1.55, 1.6), (12.0, 0.1, 3.2), "wallpv")
    cam = bpy.data.objects.new("LW_PreviewCam", bpy.data.cameras.new("LW_PreviewCam"))
    scene.collection.objects.link(cam)
    cam.data.lens = 40
    target = Vector((0.0, 0.1, 0.8))
    cam.location = target + Vector((0.9, -2.0, 1.0)).normalized() * 7.2
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    saved = (scene.camera, scene.render.resolution_x, scene.render.resolution_y, scene.render.filepath,
             scene.render.film_transparent)
    try:
        scene.camera = cam
        scene.render.resolution_x = scene.render.resolution_y = 512
        scene.render.film_transparent = False
        scene.render.filepath = out
        bpy.ops.render.render(write_still=True)
    finally:
        (scene.camera, scene.render.resolution_x, scene.render.resolution_y, scene.render.filepath,
         scene.render.film_transparent) = saved


def main() -> None:
    out = Path(sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "build/livewire_cells")
    only = sys.argv[sys.argv.index("--") + 2:] if "--" in sys.argv else []
    if not bpy.app.background:
        raise SystemExit("render headless only (forge rig names are global)")
    scene = bpy.context.scene
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    F.register()
    scene.render.engine = "CYCLES"
    props = scene.pz_forge
    props.footprint_x = props.footprint_y = 1
    props.show_guide = False
    props.contrast_boost = 1.0
    props.toon_shading = True
    F.build_rig(bpy.context)
    scene.cycles.samples = 16
    scene.cycles.use_denoising = False
    subject = bpy.data.objects[F.SUBJECT_NAME]
    mats = materials()
    for group in tile_groups():
        if only and group["key"] not in only:
            continue
        build_group(subject, mats, group)
        props.sheet_name = group["key"]
        props.facings = str(len(group["indices"]))
        props.output_dir = str(out / group["key"])
        manifest = F.render_cells(bpy.context)
        print(f"rendered {group['key']}: {len(manifest['cells'])} cells")
    if not only or "preview" in only:
        render_preview(scene, subject, mats, str(out / "preview.png"))
        print(f"rendered preview to {out / 'preview.png'}")


# --------------------------------------------------------------------------- #
# Packaging (plain Python with Pillow + pzforge)
# --------------------------------------------------------------------------- #

#: Electrician = screwdriver and the Electrical skill (ISMoveableDefinitions.lua:313);
#: PickUpLevel is also the level required to place (ISMoveableSpriteProps.lua:485-494).
_TOOLS = {"PickUpTool": "Electrician", "PlaceTool": "Electrician"}
PROPS = [
    (range(0, 4), {"CustomName": "Solar Panel", "solidtrans": "", "BlocksPlacement": "",
                   "Material": "MetalPlates", "PickUpWeight": "90", "PickUpLevel": "3", **_TOOLS}),
    # CustomItem: the tile has no blades, the item keeps its own icon (Moveable.java:128-141).
    (range(4, 8), {"CustomName": "Wind Turbine", "solidtrans": "", "BlocksPlacement": "",
                   "Material": "MetalPlates", "PickUpWeight": "150", "PickUpLevel": "6",
                   "CustomItem": "Base.Mov_LiveWire_WindTurbine", **_TOOLS}),
    (range(8, 12), {"CustomName": "Water Wheel", "solidtrans": "", "BlocksPlacement": "",
                    "Material": "Wood", "PickUpWeight": "150", "PickUpLevel": "7", **_TOOLS}),
    (range(12, 16), {"CustomName": "Inverter", "solidtrans": "", "BlocksPlacement": "",
                     "Material": "MetalPlates", "PickUpWeight": "120", "PickUpLevel": "5", **_TOOLS}),
    (range(16, 20), {"CustomName": "Power Bank", "solidtrans": "", "BlocksPlacement": "", "IsLow": "",
                     "container": "livewirepowerbank", "ContainerCapacity": "50", "ContainerPosition": "Low",
                     "Material": "MetalPlates", "PickUpWeight": "100", "PickUpLevel": "2", **_TOOLS}),
    (range(20, 22), {"CustomName": "Breaker Panel", "MoveType": "WallObject", "Material": "MetalPlates",
                     "PickUpWeight": "30", "PickUpLevel": "3", **_TOOLS}),
    (range(22, 24), {"CustomName": "Battery Alarm", "MoveType": "WallObject", "Material": "MetalPlates",
                     "PickUpWeight": "10", "PickUpLevel": "2", **_TOOLS}),
]
FACING_NAMES = ["S", "E", "N", "W"]
TOTAL = 72


def styled_cells(group_dir: Path, work: Path, overlay: bool = False) -> list:
    """Run pzforge build on one group; return its styled cells in facing order."""
    from PIL import Image
    from pzforge import cli
    dist = work / group_dir.name
    args = ["build", str(group_dir), "--out", str(dist), "--mod-id", "lw", "--tiledef-id", str(TILEDEF_ID)]
    if overlay:
        # Small lit parts: keep the toon render (tone matching would grey them).
        args += ["--style-strength", "0"]
    if cli.main(args) != 0:
        raise RuntimeError(f"pzforge build failed for {group_dir}")
    sheet = Image.open(next(dist.rglob(f"{group_dir.name}.png"))).convert("RGBA")
    count = len(json.loads((group_dir / "manifest.json").read_text())["cells"])
    cells = [sheet.crop(((i % 8) * 128, (i // 8) * 256, (i % 8) * 128 + 128, (i // 8) * 256 + 256))
             for i in range(count)]
    glow = GLOW.get(group_dir.name)
    if glow:
        cells = [light_up(c, glow) for c in cells]
    return cells


#: Lit overlays: the toon render greys bright colours, so their pixels are pushed
#: towards a saturated light colour (keeping 25 % of the shading).
GLOW = {
    "inverter_on": (120, 255, 150), "inverter_fault": (255, 50, 30), "powerbank_led": (60, 255, 60),
    "solar_led": (60, 255, 60), "wind_led": (60, 255, 60), "hydro_led": (60, 255, 60),
    "breaker_trip": (255, 40, 20), "alarm_ring": (255, 50, 25),
}


def light_up(img, colour):
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(0.25 * r + 0.75 * colour[0]), int(0.25 * g + 0.75 * colour[1]),
                            int(0.25 * b + 0.75 * colour[2]), a)
    return img


def tile_props(i: int) -> dict:
    for rng_, extra in PROPS:
        if i in rng_:
            n = len(rng_)
            return {"GroupName": "Live Wire", "IsMoveAble": "", **extra,
                    "Facing": FACING_NAMES[(i - rng_.start) % n]}
    return {}


def write_wind_icon(base, blades, project: Path) -> None:
    """Inventory icon of the wind turbine (its tile has no blades): base + blade frame,
    cropped and fitted into 64 x 64."""
    from PIL import Image
    img = base.copy()
    img.alpha_composite(blades)
    box = img.getbbox()
    img = img.crop(box)
    side = max(img.width, img.height)
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
    out = project / "Contents" / "mods" / MOD_ID / "42.21" / "media" / "textures" / "Item_LiveWireWindTurbine.png"
    out.parent.mkdir(parents=True, exist_ok=True)
    sq.resize((64, 64), Image.LANCZOS).save(out)


def package(cells_dir: Path, project: Path, write_preview: bool = True) -> None:
    from PIL import Image
    from pzforge.modgen import used_tiledef_ids
    from pzforge.sheet import Cell, Sheet, pack_sheet
    from pzforge.tiledef import TileDefinitions, Tile, Tileset

    roots = [Path(p) for p in os.environ.get("PZ_TILEDEF_ROOTS", "").split(os.pathsep) if p]
    taken = used_tiledef_ids(roots + [Path.home() / "Zomboid" / "mods", Path.home() / "Zomboid" / "Workshop"])
    owners = [o for o in taken.get(TILEDEF_ID, []) if SHEET not in o]
    if owners:
        raise SystemExit(f"tiledef {TILEDEF_ID} already used by {owners}")
    work = cells_dir / "_styled"
    images: dict[int, Image.Image] = {}
    missing = [key for key, _, _ in ALL_GROUPS if not (cells_dir / key / "manifest.json").exists()]
    if missing:
        raise SystemExit(f"groups not rendered: {missing}")
    for key, idx, _ in ALL_GROUPS:
        for facing, img in enumerate(styled_cells(cells_dir / key, work, key in OVERLAY_KEYS)):
            images[idx[facing]] = img
    write_wind_icon(images[4], images[48], project)
    blank = Image.new("RGBA", (128, 256), (0, 0, 0, 0))
    cells = [Cell(images.get(i, blank), index=i) for i in range(TOTAL)]
    sheet = Sheet(SHEET, 128, 256, 8, cells)
    tiles = [Tile(tile_props(i)) for i in range(TOTAL)]
    tdefs = TileDefinitions([Tileset(SHEET, f"{SHEET}.png", 8, TOTAL // 8, 1, tiles)])
    media = project / "Contents" / "mods" / MOD_ID / "common" / "media"
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)
    pack_sheet(sheet).write(media / "texturepacks" / f"{SHEET}.pack")
    tdefs.write(media / f"{SHEET}.tiles")
    (cells_dir / f"{SHEET}.tiles.txt").write_text(tdefs.to_text(), encoding="ascii")
    sheet.image().save(cells_dir / f"{SHEET}_sheet.png")
    (media / "tileGeometry.txt").write_text("tileGeometry\n{\n    VERSION = 2,\n}\n", encoding="ascii")
    if write_preview:
        preview = Image.open(cells_dir / "preview.png").convert("RGB").resize((256, 256), Image.LANCZOS)
        preview.save(project / "preview.png", optimize=True)
    print(f"packed {len(images)} sprites into {media}")


if __name__ == "__main__":
    if bpy is None:
        if len(sys.argv) not in (4, 5) or sys.argv[1] != "package" or sys.argv[4:] not in ([], ["--no-preview"]):
            raise SystemExit("usage: python build_livewire_tiles.py package <cells-dir> <project-root> [--no-preview]")
        package(Path(sys.argv[2]), Path(sys.argv[3]), write_preview="--no-preview" not in sys.argv)
    else:
        main()
