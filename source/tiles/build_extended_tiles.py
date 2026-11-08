"""LiveWire Extended tiles (batman_livewireext_01, tiledef 7175) for Build 42.21.

PLACEHOLDER: an outdoor power terminal drawn from simple shapes (concrete base,
grey post, cabinet with a yellow band), final model later (Blender). Original
work: nothing taken from another mod.

Contract with the Lua code (LWX_Terminal.lua): never renumber these indices.
  0-3   power terminal   S E N W
  4-7   reserved (blank)

Needs Pillow and pz-sprite-forge (MIT, https://github.com/Leeheejin/pz-sprite-forge):
    set PZ_FORGE=<path to your pz-sprite-forge clone>
    python source/tiles/build_extended_tiles.py <project-root>
-> Contents/mods/batman_LiveWireExtended/common/media/texturepacks/batman_livewireext_01.pack
   Contents/mods/batman_LiveWireExtended/common/media/batman_livewireext_01.tiles
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw

FORGE = Path(os.environ.get("PZ_FORGE", "pz-sprite-forge"))
sys.path.insert(0, str(FORGE))

SHEET = "batman_livewireext_01"
TILEDEF_ID = 7175
MOD_ID = "batman_LiveWireExtended"
CELL_W, CELL_H = 128, 256
TOTAL = 8
FACING_NAMES = ["S", "E", "N", "W"]
PROPS = {"GroupName": "LiveWire Extended", "CustomName": "Terminal", "IsMoveAble": "",
         "solidtrans": "", "BlocksPlacement": "", "Material": "MetalPlates",
         "PickUpWeight": "40", "PickUpTool": "Electrician"}

# Floor diamond of a 2x tile: 128 wide, 64 high, bottom vertex at y = 256.
CX, CY = 64, 224


def iso(x: float, y: float, z: float) -> tuple[float, float]:
    """Tile-local coordinates (x east, y south, in tile units; z up in pixels) to pixels."""
    return CX + (x - y) * 64, CY + (x + y) * 32 - z


def box(d: ImageDraw.ImageDraw, x0, y0, x1, y1, z0, z1, top, left, right) -> None:
    """Axis-aligned box seen from the south-east camera: top, south (left) and east (right) faces."""
    d.polygon([iso(x0, y1, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x0, y1, z1)], fill=left)
    d.polygon([iso(x1, y0, z0), iso(x1, y1, z0), iso(x1, y1, z1), iso(x1, y0, z1)], fill=right)
    d.polygon([iso(x0, y0, z1), iso(x1, y0, z1), iso(x1, y1, z1), iso(x0, y1, z1)], fill=top)


def terminal(facing: int) -> Image.Image:
    img = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # Concrete pad, post, cabinet.
    box(d, -0.25, -0.25, 0.25, 0.25, 0, 8, (170, 168, 160, 255), (140, 138, 130, 255), (120, 118, 112, 255))
    box(d, -0.06, -0.06, 0.06, 0.06, 8, 70, (150, 155, 160, 255), (115, 120, 125, 255), (95, 100, 105, 255))
    box(d, -0.18, -0.12, 0.18, 0.12, 70, 120, (190, 195, 200, 255), (150, 155, 162, 255), (125, 130, 138, 255))
    # Yellow band and the door on the facing side (S and E visible; N and W show the back).
    band = (230, 180, 40, 255)
    d.polygon([iso(-0.18, 0.12, 104), iso(0.18, 0.12, 104), iso(0.18, 0.12, 110), iso(-0.18, 0.12, 110)], fill=band)
    d.polygon([iso(0.18, -0.12, 104), iso(0.18, 0.12, 104), iso(0.18, 0.12, 110), iso(0.18, -0.12, 110)], fill=band)
    if facing == 0:  # S: door on the south face
        d.polygon([iso(-0.12, 0.12, 76), iso(0.12, 0.12, 76), iso(0.12, 0.12, 100), iso(-0.12, 0.12, 100)],
                  fill=(60, 64, 70, 255))
    elif facing == 1:  # E: door on the east face
        d.polygon([iso(0.18, -0.08, 76), iso(0.18, 0.08, 76), iso(0.18, 0.08, 100), iso(0.18, -0.08, 100)],
                  fill=(60, 64, 70, 255))
    return img


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: python build_extended_tiles.py <project-root>")
    project = Path(sys.argv[1])
    from pzforge.modgen import used_tiledef_ids
    from pzforge.sheet import Cell, Sheet, pack_sheet
    from pzforge.tiledef import TileDefinitions, Tile, Tileset

    roots = [Path(p) for p in os.environ.get("PZ_TILEDEF_ROOTS", "").split(os.pathsep) if p]
    taken = used_tiledef_ids(roots + [Path.home() / "Zomboid" / "mods", Path.home() / "Zomboid" / "Workshop"])
    owners = [o for o in taken.get(TILEDEF_ID, []) if SHEET not in o]
    if owners:
        raise SystemExit(f"tiledef {TILEDEF_ID} already used by {owners}")
    blank = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    images = {i: terminal(i) for i in range(4)}
    cells = [Cell(images.get(i, blank), index=i) for i in range(TOTAL)]
    sheet = Sheet(SHEET, CELL_W, CELL_H, 8, cells)
    tiles = [Tile({**PROPS, "Facing": FACING_NAMES[i]} if i < 4 else {}) for i in range(TOTAL)]
    tdefs = TileDefinitions([Tileset(SHEET, f"{SHEET}.png", 8, TOTAL // 8, 1, tiles)])
    media = project / "Contents" / "mods" / MOD_ID / "common" / "media"
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)
    pack_sheet(sheet).write(media / "texturepacks" / f"{SHEET}.pack")
    tdefs.write(media / f"{SHEET}.tiles")
    icons = project / "Contents" / "mods" / MOD_ID / "42.21" / "media" / "textures"
    icons.mkdir(parents=True, exist_ok=True)
    images[0].crop((24, 120, 104, 240)).resize((32, 48)).crop((0, 8, 32, 40)).save(icons / "Item_LWXTerminal.png")
    sheet.image().save(project / "source" / "tiles" / f"{SHEET}_sheet.png")
    print(f"packed {len(images)} sprites into {media}")


if __name__ == "__main__":
    main()
