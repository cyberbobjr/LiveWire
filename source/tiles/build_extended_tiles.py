"""LiveWire Extended tiles (batman_livewireext_01, tiledef 7175) for Build 42.21.

PLACEHOLDER: an outdoor power terminal drawn from simple shapes (concrete base,
grey post, cabinet with a yellow band) and three wall breaker boards (grey box,
rows of dark breakers), final models later (Blender). Original work: nothing
taken from another mod.

Contract with the Lua code (LWX_Terminal.lua): never renumber these indices.
  0-3   power terminal   S E N W
  4-7   reserved (blank)
  8-9   breaker board,  8 modules   S E (wall object: north wall, west wall)
  10-11 breaker board, 16 modules   S E
  12-13 breaker board, 24 modules   S E
  14-15 reserved (blank)

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
TOTAL = 16
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


BOARDS = {8: (8, 0.36, 46), 10: (16, 0.56, 62), 12: (24, 0.76, 80)}  # index: modules, width, height px
BOARD_PROPS = {"GroupName": "LiveWire Extended", "IsMoveAble": "", "MoveType": "WallObject", "Material": "MetalPlates",
               "PickUpTool": "Electrician"}


def board(modules: int, width: float, height: int, facing: int) -> Image.Image:
    """Grey wall box with rows of breakers; facing 0 on the north wall, 1 on the west wall."""
    img = Image.new("RGBA", (CELL_W, CELL_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    z0, z1, depth, half = 96, 96 + height, 0.07, width / 2
    body = ((200, 202, 204, 255), (165, 168, 172, 255), (140, 143, 148, 255))
    dark, lever = (55, 58, 62, 255), (225, 225, 220, 255)
    rows = modules // 8
    if facing == 0:  # against the north wall: front face looks south
        y0 = -0.5
        box(d, -half, y0, half, y0 + depth, z0, z1, *body)
        for r in range(rows):
            zt = z1 - 10 - r * (height - 14) / rows
            for m in range(8):
                xa = -half + 0.04 + m * (width - 0.08) / 8
                xb = xa + (width - 0.08) / 8 - 0.012
                d.polygon([iso(xa, y0 + depth, zt - 12), iso(xb, y0 + depth, zt - 12),
                           iso(xb, y0 + depth, zt), iso(xa, y0 + depth, zt)], fill=dark)
                d.line([iso((xa + xb) / 2, y0 + depth, zt - 9), iso((xa + xb) / 2, y0 + depth, zt - 3)], fill=lever)
    else:  # against the west wall: front face looks east
        x0 = -0.5
        box(d, x0, -half, x0 + depth, half, z0, z1, *body)
        for r in range(rows):
            zt = z1 - 10 - r * (height - 14) / rows
            for m in range(8):
                ya = -half + 0.04 + m * (width - 0.08) / 8
                yb = ya + (width - 0.08) / 8 - 0.012
                d.polygon([iso(x0 + depth, ya, zt - 12), iso(x0 + depth, yb, zt - 12),
                           iso(x0 + depth, yb, zt), iso(x0 + depth, ya, zt)], fill=dark)
                d.line([iso(x0 + depth, (ya + yb) / 2, zt - 9), iso(x0 + depth, (ya + yb) / 2, zt - 3)], fill=lever)
    return img


def breaker_icon(text: str, double: bool) -> Image.Image:
    """PLACEHOLDER inventory icon of a breaker: dark body, white lever, rating text."""
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    w = 22 if double else 13
    x0 = (32 - w) // 2
    d.rectangle([x0, 3, x0 + w - 1, 28], fill=(48, 50, 54, 255), outline=(20, 20, 22, 255))
    for k in range(2 if double else 1):
        lx = x0 + 3 + k * 10
        d.rectangle([lx, 7, lx + 6, 15], fill=(235, 235, 228, 255))
    d.text((x0 + 2, 18), text, fill=(240, 200, 60, 255))
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
    props = {i: {**PROPS, "Facing": FACING_NAMES[i]} for i in range(4)}
    for first, (modules, width, height) in BOARDS.items():
        for facing in range(2):
            images[first + facing] = board(modules, width, height, facing)
            props[first + facing] = {**BOARD_PROPS, "CustomName": f"Board{modules}",
                                     "PickUpWeight": str(10 + modules // 8 * 10), "Facing": FACING_NAMES[facing]}
    cells = [Cell(images.get(i, blank), index=i) for i in range(TOTAL)]
    sheet = Sheet(SHEET, CELL_W, CELL_H, 8, cells)
    tiles = [Tile(props.get(i, {})) for i in range(TOTAL)]
    tdefs = TileDefinitions([Tileset(SHEET, f"{SHEET}.png", 8, TOTAL // 8, 1, tiles)])
    media = project / "Contents" / "mods" / MOD_ID / "common" / "media"
    (media / "texturepacks").mkdir(parents=True, exist_ok=True)
    pack_sheet(sheet).write(media / "texturepacks" / f"{SHEET}.pack")
    tdefs.write(media / f"{SHEET}.tiles")
    icons = project / "Contents" / "mods" / MOD_ID / "42.21" / "media" / "textures"
    icons.mkdir(parents=True, exist_ok=True)
    images[0].crop((24, 120, 104, 240)).resize((32, 48)).crop((0, 8, 32, 40)).save(icons / "Item_LWXTerminal.png")
    icon = images[10].crop(images[10].getbbox())
    side = max(icon.size)
    framed = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    framed.paste(icon, ((side - icon.width) // 2, (side - icon.height) // 2))
    framed.resize((32, 32)).save(icons / "Item_LWXPanel.png")
    for name, text, double in (("15", "15", False), ("20", "20", False), ("30", "30", False), ("2P30", "2x30", True)):
        breaker_icon(text, double).save(icons / f"Item_LWXBreaker{name}.png")
    sheet.image().save(project / "source" / "tiles" / f"{SHEET}_sheet.png")
    print(f"packed {len(images)} sprites into {media}")


if __name__ == "__main__":
    main()
