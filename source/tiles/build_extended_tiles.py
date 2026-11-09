"""LiveWire Extended tiles (batman_livewireext_01, tiledef 7175) and item icons, Build 42.21.

Blender models rendered with pz-sprite-forge (MIT, https://github.com/Leeheejin/pz-sprite-forge),
same kit and materials as Live Wire (build_livewire_tiles.py). Original work: nothing taken
from another mod.

Contract with the Lua code (LWX_Terminal.lua, LWX_Panel.lua): never renumber these indices.
  0-3   power terminal                   S E N W   (outdoors)
  4-7   reserved (blank)
  8-9   breaker board,  8 modules        S E (wall object: north wall, west wall)
  10-11 breaker board, 16 modules        S E
  12-13 breaker board, 24 modules        S E
  14-15 reserved (blank)
Item icons (64 x 64, media/textures): Item_LWXTerminal, Item_LWXPanel, Item_LWXBreaker15/20/30/2P30,
Item_LWXTwilightSwitch.

1. Render, headless:
       set PZ_FORGE=<path to pz-sprite-forge>
       blender -b --factory-startup -P source/tiles/build_extended_tiles.py -- <cells-dir>
2. Style and package (Python with Pillow + pzforge):
       python source/tiles/build_extended_tiles.py package <cells-dir> <project-root>
3. Depth map (skill pz-blender-assets, scripts/build_depthmap.py):
       blender -b --factory-startup -P <skill>/scripts/build_depthmap.py -- source/tiles/build_extended_tiles.py depth.json
       python <skill>/scripts/build_depthmap.py depth.json <ext>/common/media/texturepacks/batman_livewireext_01.pack
           batman_livewireext_01 <ext>/common/media/depthmaps/DEPTH_batman_livewireext_01.png
"""
from __future__ import annotations

import json
import math
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import build_livewire_tiles as LW  # noqa: E402  (kit, materials, forge import)

bpy = LW.bpy
if bpy is not None:
    from mathutils import Vector  # noqa: E402
    F = LW.F

SHEET = "batman_livewireext_01"
TILEDEF_ID = 7175
MOD_ID = "batman_LiveWireExtended"
TOTAL = 16
FACING_NAMES = ["S", "E", "N", "W"]

EXTRA_PAINTS = {
    "concrete": ("brick", (0.56, 0.55, 0.51)),
    "utility": ("metal", (0.42, 0.50, 0.46)),
    "utilitydark": ("metal", (0.26, 0.31, 0.29)),
    "enclosure": ("metal", (0.80, 0.80, 0.77)),
    "frame": ("metal", (0.36, 0.38, 0.40)),
    "module": ("fabric", (0.93, 0.93, 0.90)),
    "glass": ("fabric", (0.10, 0.14, 0.16)),
    "blue": ("fabric", (0.12, 0.30, 0.75)),
    "orange": ("fabric", (0.95, 0.45, 0.06)),
}


def materials() -> dict:
    mats = LW.materials()
    for key, (cls, paint) in EXTRA_PAINTS.items():
        mats[key] = F.forge_material(f"batman_lwx_{key}", cls, paint)
    return mats


Kit = LW.Kit


def clear_subject(subject) -> None:
    """Live Wire's clear_subject, also for text objects (icon ratings)."""
    stack, doomed = list(subject.children), []
    while stack:
        obj = stack.pop()
        stack.extend(obj.children)
        doomed.append(obj)
    for obj in doomed:
        data, kind = obj.data, obj.type
        bpy.data.objects.remove(obj, do_unlink=True)
        if data is not None and data.users == 0:
            (bpy.data.curves if kind == "FONT" else bpy.data.meshes).remove(data)


# --------------------------------------------------------------------------- #
# Power terminal (front towards -Y, origin at the tile centre on the floor)
# --------------------------------------------------------------------------- #

def build_terminal(k: Kit):
    """Utility pedestal: concrete pad, steel post, weatherproof cabinet with a door."""
    k.box("t_pad", (0, 0.02, 0.05), (0.56, 0.48, 0.10), "concrete", bevel=0.04)
    k.box("t_post", (0, 0.05, 0.36), (0.13, 0.13, 0.54), "utilitydark", bevel=0.05)
    w, d, h, zc = 0.50, 0.30, 0.60, 0.92
    yc = 0.03
    k.box("t_body", (0, yc, zc), (w, d, h), "utility", bevel=0.03)
    k.box("t_roof", (0, yc + 0.01, zc + h / 2 + 0.03), (w + 0.07, d + 0.08, 0.05), "utilitydark", bevel=0.10)
    k.box("t_base", (0, yc, zc - h / 2 - 0.02), (w - 0.04, d - 0.04, 0.05), "utilitydark")
    fy = yc - d / 2 - 0.006
    k.box("t_door", (0, fy, zc - 0.01), (w - 0.07, 0.012, h - 0.08), "utility", bevel=0.02)
    for z in (zc + 0.18, zc - 0.18):
        k.cyl(f"t_hinge_{z:.2f}", (-w / 2 + 0.035, fy - 0.004, z), 0.012, 0.07, "steel")
    k.box("t_handle", (w / 2 - 0.07, fy - 0.016, zc - 0.03), (0.025, 0.02, 0.12), "darksteel", bevel=0.2)
    k.cyl("t_lock", (w / 2 - 0.07, fy - 0.012, zc + 0.07), 0.016, 0.012, "steel", rot=(math.pi / 2, 0, 0))
    # meter window and status light
    k.box("t_window_frame", (-0.06, fy - 0.010, zc + 0.14), (0.20, 0.008, 0.12), "darksteel")
    k.box("t_window", (-0.06, fy - 0.015, zc + 0.14), (0.17, 0.004, 0.09), "glass")
    k.box("t_meter", (-0.06, fy - 0.018, zc + 0.12), (0.10, 0.003, 0.03), "screen")
    k.box("t_led", (0.10, fy - 0.014, zc + 0.17), (0.035, 0.008, 0.035), "green")
    # hazard label
    k.box("t_label", (0.0, fy - 0.010, zc - 0.17), (0.13, 0.004, 0.11), "yellow")
    k.mesh("t_label_mark", [(-0.035, fy - 0.013, zc - 0.205), (0.035, fy - 0.013, zc - 0.205),
                            (0.0, fy - 0.013, zc - 0.135)], [(0, 1, 2)], "black")
    # side louvres
    for side in (-1, 1):
        x = side * (w / 2 + 0.004)
        for i in range(4):
            k.box(f"t_louvre_{side}_{i}", (x, yc + 0.02, zc + 0.12 - i * 0.05), (0.01, d - 0.12, 0.018), "utilitydark")
    # conduit into the pad, cable gland
    k.rod("t_conduit", (0.0, yc + d / 2 - 0.06, zc - h / 2), (0.0, yc + d / 2 - 0.06, 0.10), 0.03, "darksteel")
    k.cyl("t_gland", (0.0, yc + d / 2 - 0.06, 0.115), 0.045, 0.03, "steel")


# --------------------------------------------------------------------------- #
# Breaker boards (wall objects on the north wall, y = +0.5; front towards -Y)
# --------------------------------------------------------------------------- #

MODULE_W = 0.058
ROW_H = 0.20
BOARD_Z = 1.30


def board_size(modules: int) -> tuple[float, float]:
    rows = modules // 8
    return 8 * MODULE_W + 0.10, rows * ROW_H + 0.13


def build_board(modules: int):
    def fn(k: Kit):
        rows = modules // 8
        w, h = board_size(modules)
        d = 0.10
        yb = 0.5 - LW.WALL_GAP - d / 2
        zc = BOARD_Z
        k.box("b_body", (0, yb, zc), (w, d, h), "enclosure", bevel=0.05)
        k.box("b_back", (0, 0.5 - LW.WALL_GAP + 0.01, zc), (w + 0.03, 0.02, h + 0.03), "frame")
        fy = yb - d / 2
        # front frame around the opening
        k.box("b_frame_top", (0, fy - 0.006, zc + h / 2 - 0.03), (w - 0.02, 0.012, 0.035), "frame")
        k.box("b_frame_bottom", (0, fy - 0.006, zc - h / 2 + 0.03), (w - 0.02, 0.012, 0.035), "frame")
        for sx in (-1, 1):
            k.box(f"b_frame_side_{sx}", (sx * (w / 2 - 0.02), fy - 0.006, zc), (0.03, 0.012, h - 0.02), "frame")
        top = zc + h / 2 - 0.065
        for r in range(rows):
            rz = top - r * ROW_H - ROW_H / 2
            k.box(f"b_cover_{r}", (0, fy - 0.004, rz), (w - 0.07, 0.006, ROW_H - 0.01), "enclosure")
            k.box(f"b_rail_{r}", (0, fy - 0.008, rz), (8 * MODULE_W + 0.01, 0.004, 0.035), "darksteel")
            for m in range(8):
                x = -4 * MODULE_W + MODULE_W * (m + 0.5)
                k.box(f"b_mod_{r}_{m}", (x, fy - 0.030, rz), (MODULE_W - 0.005, 0.045, 0.13), "module", bevel=0.10)
                main = r == 0 and m == 0
                k.box(f"b_lever_{r}_{m}", (x, fy - 0.060, rz + 0.016), (0.020 if main else 0.016, 0.026, 0.040),
                      "red" if main else "black")
                k.box(f"b_dot_{r}_{m}", (x, fy - 0.054, rz - 0.042), (0.016, 0.003, 0.013),
                      "blue" if (m + r) % 3 == 0 else "orange" if (m + r) % 3 == 1 else "green")
            k.box(f"b_labels_{r}", (0, fy - 0.010, rz - ROW_H / 2 + 0.012), (8 * MODULE_W, 0.004, 0.014), "white")
        # conduits leaving the top
        for sx in (-1, 1):
            x = sx * (w / 2 - 0.08)
            k.rod(f"b_conduit_{sx}", (x, yb + 0.01, zc + h / 2), (x, yb + 0.01, zc + h / 2 + 0.30), 0.017, "darksteel")
    return fn


# --------------------------------------------------------------------------- #
# Inventory items (icons only)
# --------------------------------------------------------------------------- #

RATING_PAINT = {"15": "blue", "20": "yellow", "30": "green"}


def build_breaker_item(rating: str, poles: int):
    def fn(k: Kit):
        w = 0.018 * poles
        k.box("i_body", (0, 0, 0.045), (w, 0.07, 0.09), "module", bevel=0.12)
        k.box("i_front", (0, -0.006, 0.096), (w * 0.9, 0.045, 0.012), "module", bevel=0.2)
        for p in range(poles):
            x = -w / 2 + 0.009 + p * 0.018
            k.box(f"i_lever_{p}", (x, -0.008, 0.112), (0.008, 0.016, 0.022), "black")
        if poles > 1:
            k.box("i_tie", (0, -0.008, 0.120), (w * 0.7, 0.004, 0.004), "black")
        k.box("i_band", (0, -0.036, 0.072), (w * 0.85, 0.003, 0.014), RATING_PAINT[rating])
        k.box("i_rail", (0, 0.0, 0.002), (w + 0.03, 0.035, 0.004), "steel")
        text = bpy.data.curves.new("i_text", "FONT")
        text.body = rating
        text.size = 0.013 if poles == 1 else 0.017
        text.align_x = "CENTER"
        obj = bpy.data.objects.new("i_text", text)
        bpy.context.scene.collection.objects.link(obj)
        obj.parent = k.anchor
        obj.location = (0, -0.0362, 0.038)
        obj.rotation_euler = (math.pi / 2, 0, 0)
        obj.data.materials.append(k.mats["black"])
    return fn


def build_twilight_item(k: Kit):
    w = 0.036
    k.box("tw_body", (0, 0, 0.045), (w, 0.07, 0.09), "module", bevel=0.12)
    k.box("tw_front", (0, -0.006, 0.096), (w * 0.9, 0.045, 0.012), "module", bevel=0.2)
    k.cyl("tw_dial", (0, -0.036, 0.055), 0.010, 0.004, "darksteel", rot=(math.pi / 2, 0, 0))
    k.box("tw_mark", (0, -0.039, 0.060), (0.002, 0.002, 0.008), "white")
    k.cyl("tw_cell_base", (0.0, 0.0, 0.108), 0.011, 0.012, "darksteel")
    sphere = k.cyl("tw_cell", (0.0, 0.0, 0.118), 0.010, 0.010, "yellow", segs=16)
    sphere.modifiers.new("smooth", "SUBSURF").levels = 2
    k.box("tw_rail", (0, 0.0, 0.002), (w + 0.03, 0.035, 0.004), "steel")
    k.rod("tw_wire", (0.0, 0.03, 0.03), (0.04, 0.06, 0.0), 0.002, "black")


ICONS = [
    ("LWXBreaker15", build_breaker_item("15", 1), 0.16),
    ("LWXBreaker20", build_breaker_item("20", 1), 0.16),
    ("LWXBreaker30", build_breaker_item("30", 1), 0.16),
    ("LWXBreaker2P30", build_breaker_item("30", 2), 0.19),
    ("LWXTwilightSwitch", build_twilight_item, 0.19),
    ("LWXTerminal", build_terminal, 1.75),
    ("LWXPanel", None, 0.85),   # board of 16 modules, built off its wall
]


# --------------------------------------------------------------------------- #
# Groups (forge rendering, depth maps) and showcase
# --------------------------------------------------------------------------- #

GROUPS = [
    ("terminal", [0, 1, 2, 3], build_terminal),
    ("board8", [8, 9], build_board(8)),
    ("board16", [10, 11], build_board(16)),
    ("board24", [12, 13], build_board(24)),
]


def tile_groups() -> list[dict]:
    return [{"key": key, "indices": idx, "overlay": False, "build": fn} for key, idx, fn in GROUPS]


def build_group(subject, mats, group) -> list:
    clear_subject(subject)
    group["build"](Kit(subject, mats))
    return []


def build(subject, mats) -> None:
    k = Kit(subject, mats)
    build_terminal(k.empty("show_terminal", (-1.0, -0.6, 0)))
    for i, modules in enumerate((8, 16, 24)):
        build_board(modules)(k.empty(f"show_board{modules}", (-0.2 + i * 0.9, 0.5, 0)))


def render_icon(scene, subject, mats, name, fn, span, out: Path) -> None:
    """Perspective 3/4 view, transparent, Standard view transform, 256 px (scaled to 64 on packaging)."""
    clear_subject(subject)
    k = Kit(subject, mats)
    if fn is None:  # the board, away from its wall and centred
        build_board(16)(k.empty("icon_board", (0, -(0.5 - LW.WALL_GAP - 0.05), -BOARD_Z)))
    else:
        fn(k)
    bpy.context.view_layer.update()
    pts = []
    stack = list(subject.children)
    while stack:
        o = stack.pop()
        stack.extend(o.children)
        if o.type in ("MESH", "FONT"):
            pts += [o.matrix_world @ Vector(c) for c in o.bound_box]
    lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
    hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
    target = (lo + hi) / 2
    cam = bpy.data.objects.new("LWX_IconCam", bpy.data.cameras.new("LWX_IconCam"))
    scene.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = span
    cam.location = target + Vector((1.0, -1.6, 1.1)).normalized() * 4.0
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    saved = (scene.camera, scene.render.resolution_x, scene.render.resolution_y, scene.render.filepath,
             scene.render.film_transparent, scene.view_settings.view_transform, scene.view_settings.exposure)
    try:
        scene.camera = cam
        scene.render.resolution_x = scene.render.resolution_y = 256
        scene.render.film_transparent = True
        scene.view_settings.view_transform = "Standard"
        scene.view_settings.exposure = 0.7
        scene.render.filepath = str(out / f"Item_{name}.png")
        bpy.ops.render.render(write_still=True)
    finally:
        (scene.camera, scene.render.resolution_x, scene.render.resolution_y, scene.render.filepath,
         scene.render.film_transparent, scene.view_settings.view_transform, scene.view_settings.exposure) = saved
        bpy.data.objects.remove(cam, do_unlink=True)


def main() -> None:
    out = Path(sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else "build/lwx_cells")
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
    if not only or "icons" in only:
        (out / "icons").mkdir(parents=True, exist_ok=True)
        for name, fn, span in ICONS:
            render_icon(scene, subject, mats, name, fn, span, out / "icons")
            print(f"rendered icon {name}")


# --------------------------------------------------------------------------- #
# Packaging (plain Python with Pillow + pzforge)
# --------------------------------------------------------------------------- #

_TOOLS = {"PickUpTool": "Electrician"}
TERMINAL_PROPS = {"GroupName": "LiveWire Extended", "CustomName": "Terminal", "IsMoveAble": "",
                  "solidtrans": "", "BlocksPlacement": "", "Material": "MetalPlates", "PickUpWeight": "40", **_TOOLS}
BOARD_PROPS = {"GroupName": "LiveWire Extended", "IsMoveAble": "", "MoveType": "WallObject",
               "Material": "MetalPlates", **_TOOLS}


def tile_props(i: int) -> dict:
    if i < 4:
        return {**TERMINAL_PROPS, "Facing": FACING_NAMES[i]}
    for first, modules in ((8, 8), (10, 16), (12, 24)):
        if i in (first, first + 1):
            return {**BOARD_PROPS, "CustomName": f"Board{modules}", "PickUpWeight": str(10 + modules // 8 * 10),
                    "Facing": FACING_NAMES[i - first]}
    return {}


def styled_cells(group_dir: Path, work: Path) -> list:
    from PIL import Image
    from pzforge import cli
    dist = work / group_dir.name
    if cli.main(["build", str(group_dir), "--out", str(dist), "--mod-id", "lwx", "--tiledef-id", str(TILEDEF_ID)]) != 0:
        raise RuntimeError(f"pzforge build failed for {group_dir}")
    sheet = Image.open(next(dist.rglob(f"{group_dir.name}.png"))).convert("RGBA")
    count = len(json.loads((group_dir / "manifest.json").read_text())["cells"])
    return [sheet.crop(((i % 8) * 128, (i // 8) * 256, (i % 8) * 128 + 128, (i // 8) * 256 + 256))
            for i in range(count)]


def package(cells_dir: Path, project: Path) -> None:
    from PIL import Image
    from pzforge.modgen import used_tiledef_ids
    from pzforge.sheet import Cell, Sheet, pack_sheet
    from pzforge.tiledef import TileDefinitions, Tile, Tileset

    taken = used_tiledef_ids([Path.home() / "Zomboid" / "mods", Path.home() / "Zomboid" / "Workshop"])
    owners = [o for o in taken.get(TILEDEF_ID, []) if SHEET not in o]
    if owners:
        raise SystemExit(f"tiledef {TILEDEF_ID} already used by {owners}")
    images: dict[int, Image.Image] = {}
    work = cells_dir / "_styled"
    for key, idx, _ in GROUPS:
        for facing, img in enumerate(styled_cells(cells_dir / key, work)):
            images[idx[facing]] = img
    blank = Image.new("RGBA", (128, 256), (0, 0, 0, 0))
    cells = [Cell(images.get(i, blank), index=i) for i in range(TOTAL)]
    sheet = Sheet(SHEET, 128, 256, 8, cells)
    tdefs = TileDefinitions([Tileset(SHEET, f"{SHEET}.png", 8, TOTAL // 8, 1, [Tile(tile_props(i)) for i in range(TOTAL)])])
    media = project / "Contents" / "mods" / MOD_ID / "common" / "media"
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)
    pack_sheet(sheet).write(media / "texturepacks" / f"{SHEET}.pack")
    tdefs.write(media / f"{SHEET}.tiles")
    (media / "tileGeometry.txt").write_text("tileGeometry\n{\n    VERSION = 2,\n}\n", encoding="ascii")
    sheet.image().save(HERE / f"{SHEET}_sheet.png")
    icons = project / "Contents" / "mods" / MOD_ID / "42.21" / "media" / "textures"
    icons.mkdir(parents=True, exist_ok=True)
    for name, _, _ in ICONS:
        img = Image.open(cells_dir / "icons" / f"Item_{name}.png").convert("RGBA")
        box = img.getbbox()
        img = img.crop(box)
        side = max(img.size)
        square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
        square.paste(img, ((side - img.width) // 2, (side - img.height) // 2))
        square.resize((64, 64), Image.LANCZOS).save(icons / f"Item_{name}.png")
    print(f"packed {len(images)} sprites and {len(ICONS)} icons into {media} and {icons}")


if __name__ == "__main__":
    if bpy is None:
        if len(sys.argv) != 4 or sys.argv[1] != "package":
            raise SystemExit("usage: python build_extended_tiles.py package <cells-dir> <project-root>")
        package(Path(sys.argv[2]), Path(sys.argv[3]))
    else:
        main()
