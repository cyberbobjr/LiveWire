"""Animate the water wheel (1.8.0): redraw tiles 8-11 without their wheel, add the four
wheel frames 104-119; preserve every other tile, pixel, depth texel and property.

1. Render the groups listed in hydro_rotor.KEYS with build_livewire_tiles.py
   (Blender, headless) into <render-dir>:
       blender -b --factory-startup -P source/tiles/build_livewire_tiles.py -- <render-dir>
           hydro hydro_rotor0 hydro_rotor1 hydro_rotor2 hydro_rotor3
2. Build <render-dir>/depth.json with the depth tool (Blender step) and the
   hydro_rotor.py recipe:
       blender -b --factory-startup -P <skill>/scripts/build_depthmap.py --
           source/tiles/hydro_rotor.py <render-dir>/depth.json
3. python source/tiles/install_hydro_rotor.py <render-dir> --forge <forge-dir>
       --depth-tool <skill>/scripts/build_depthmap.py

Sprite IDs never move: tiles 8-11 keep their index and gain the CustomItem property
(the item keeps its own icon, like the wind turbine); the pack, the depth map and the
tile definitions grow to recipe.TOTAL cells. Cells outside hydro_rotor.indices() keep
their pixels, depth and properties (the existing definitions are read back and
extended, never regenerated). The first backups and a preview stay in <render-dir>.
"""
import argparse
import importlib.util
import json
import math
import os
import sys
from io import BytesIO
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("render_dir", type=Path)
    parser.add_argument("--forge", type=Path, required=True)
    parser.add_argument("--depth-tool", type=Path, required=True)
    args = parser.parse_args()
    os.environ["PZ_FORGE"] = str(args.forge)
    sys.path.insert(0, str(args.forge))
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import build_livewire_tiles as recipe
    import hydro_rotor
    from PIL import Image
    from pzforge.packfile import TexturePack
    from pzforge.sheet import Cell, Sheet, pack_sheet
    from pzforge.tiledef import Tile, TileDefinitions

    root = Path(__file__).resolve().parents[2]
    media = root / "Contents/mods/batman_LiveWire/common/media"
    pack_path = media / "texturepacks/batman_livewire_01.pack"
    depth_path = media / "depthmaps/DEPTH_batman_livewire_01.png"
    tiles_path = media / f"{recipe.SHEET}.tiles"
    work = args.render_dir.resolve()
    changed = hydro_rotor.indices()
    replaced = list(hydro_rotor.REPLACED)
    added = hydro_rotor.added()
    total = recipe.TOTAL
    rows = total // 8

    def cells(pack):
        result = {}
        for page in pack.pages:
            atlas = Image.open(BytesIO(page.png)).convert("RGBA")
            for e in page.entries:
                img = Image.new("RGBA", (128, 256))
                img.paste(atlas.crop((e.x, e.y, e.x + e.w, e.y + e.h)), (e.ox, e.oy))
                result[int(e.name.rsplit("_", 1)[1])] = img
        return result

    # --- tile definitions: keep the existing tiles, add CustomItem to 8-11, append the new ones
    tdefs = TileDefinitions.read(tiles_path)
    tileset = tdefs.tilesets[0]
    old_count = len(tileset.tiles)
    assert tileset.name == recipe.SHEET and old_count <= min(added), (tileset.name, old_count)
    old_tiles_bytes = tiles_path.read_bytes()
    old_props = [dict(t.props) for t in tileset.tiles]
    for i in replaced:
        want = recipe.tile_props(i)
        assert {k: v for k, v in want.items() if k != "CustomItem"} == old_props[i], (i, old_props[i])
        tileset.tiles[i] = Tile(want)
    while len(tileset.tiles) < total:
        tileset.tiles.append(Tile(recipe.tile_props(len(tileset.tiles))))
    tileset.rows = rows

    # --- sprites
    original = pack_path.read_bytes()
    before = cells(TexturePack.loads(original))
    assert not (set(before) & set(added)), "cells already installed"
    for i in range(total):
        before.setdefault(i, Image.new("RGBA", (128, 256)))
    after = {i: img.copy() for i, img in before.items()}
    for group in hydro_rotor.tile_groups():
        styled = recipe.styled_cells(work / group["key"], work / "_styled", group["overlay"])
        for i, img in zip(group["indices"], styled):
            assert img.getbbox(), f"empty sprite {i}"
            after[i] = img
    packed = pack_sheet(Sheet(recipe.SHEET, 128, 256, 8, [Cell(after[i], index=i) for i in range(total)]))
    verified = cells(TexturePack.loads(packed.dumps()))
    for i in range(total):
        if i not in verified:
            assert after[i].getbbox() is None, f"cell {i} lost"
            continue
        assert verified[i].tobytes() == after[i].tobytes(), f"cell {i} altered by packing"
        if i not in changed:
            assert verified[i].tobytes() == before[i].tobytes(), f"cell {i} changed"

    # --- depth map, grown to the new row count; cells 8-11 and 104-119 recomputed
    spec = importlib.util.spec_from_file_location("lw_depth_tool", args.depth_tool)
    depth = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(depth)
    data = json.loads((work / "depth.json").read_text())
    old_depth = Image.open(depth_path).convert("RGBA")
    old_rows = old_depth.height // 256
    new_depth = Image.new("RGBA", (8 * 128, rows * 256))
    new_depth.paste(old_depth, (0, 0))
    reports = {}
    for i in changed:
        tile = Image.new("RGBA", (128, 256))
        values, drawn, stats = depth.tile_depth(data["tiles"][str(i)], after[i].getchannel("A"), 128, 256)
        assert stats["unfilled"] == 0 and stats["stray"] == 0, (i, stats)
        for y in range(256):
            for x in range(128):
                d = values[y][x]
                if d is not None and drawn(x, y):
                    value = math.floor(min(1, max(0, d)) * 255)
                    tile.putpixel((x, y), (value, value, value, 255))
        reports[i] = stats
        new_depth.paste(tile, ((i % 8) * 128, (i // 8) * 256))
    for i in range(old_rows * 8):
        if i in changed:
            continue
        box = ((i % 8) * 128, (i // 8) * 256, (i % 8 + 1) * 128, (i // 8 + 1) * 256)
        assert old_depth.crop(box).tobytes() == new_depth.crop(box).tobytes(), f"depth cell {i} changed"

    # Keep the first backups even when replaying this installation.
    for name, content in (("original.pack", original), ("original.tiles", old_tiles_bytes)):
        if not (work / name).exists():
            (work / name).write_bytes(content)
    if not (work / "original-depth.png").exists():
        old_depth.save(work / "original-depth.png")
    packed.write(pack_path)
    new_depth.save(depth_path)
    tdefs.write(tiles_path)
    reread = TileDefinitions.read(tiles_path).tilesets[0]
    assert len(reread.tiles) == total and reread.rows == rows
    for i in range(old_count):
        want = recipe.tile_props(i) if i in replaced else old_props[i]
        assert dict(reread.tiles[i].props) == want, f"tile {i} properties changed"
    (work / f"{recipe.SHEET}.tiles.txt").write_text(tdefs.to_text(), encoding="ascii")

    # Preview: the old tile, then base + each wheel frame, for the four facings.
    preview = Image.new("RGBA", (128 * 4, 256 * 5), (70, 70, 70, 255))
    for f in range(4):
        preview.alpha_composite(before[8 + f], (f * 128, 0))
        for frame in range(4):
            img = after[8 + f].copy()
            img.alpha_composite(after[104 + 4 * frame + f])
            preview.alpha_composite(img, (f * 128, (frame + 1) * 256))
    preview.save(work / "hydro-frames.png")
    (work / "asset-report.json").write_text(json.dumps(reports, indent=2), encoding="ascii")
    print(f"OK: {old_count} existing cells kept; redrawn {replaced}; added {added}; "
          f"sheet now {total} cells ({rows} rows)")


if __name__ == "__main__":
    main()
