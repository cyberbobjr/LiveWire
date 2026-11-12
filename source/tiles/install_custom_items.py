"""Give every facing of every Live Wire and LiveWire Extended tile its CustomItem (the object's own moveable item).

Without it, picking up a device turned to a facing other than its item's WorldObjectSprite gives a
generic moveable named after the sprite (Base.batman_livewire_01_13 for an inverter facing east:
ISMoveableSpriteProps.instanceItem, ISMoveableSpriteProps.lua:215-226), which the dismantle recipes and
the device code do not recognise. Only the CustomItem property is added; every other property and every
sprite stay as they are.

Usage (from the LiveWire folder): python source/tiles/install_custom_items.py --forge <pz-sprite-forge dir>
build_livewire_tiles.py (PROPS) and build_extended_tiles.py (tile_props) carry the same property, so a full
rebuild keeps it.
"""
import argparse
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
MODS = HERE.parents[1] / "Contents/mods"
TILES = MODS / "batman_LiveWire/common/media/batman_livewire_01.tiles"
X_TILES = MODS / "batman_LiveWireExtended/common/media/batman_livewireext_01.tiles"
sys.path.insert(0, str(HERE))


def wanted_base():
    import build_livewire_tiles as recipe
    out = {}
    for rng, props in recipe.PROPS:
        item = props.get("CustomItem")
        assert item, f"no CustomItem in PROPS for tiles {rng}"
        for i in rng:
            out[i] = item
    return recipe.SHEET, out


def wanted_extended():
    import build_extended_tiles as recipe
    out = {i: recipe.tile_props(i)["CustomItem"] for i in range(recipe.TOTAL) if recipe.tile_props(i)}
    return recipe.SHEET, out


def install(path, sheet, wanted):
    from pzforge.tiledef import Tile, TileDefinitions

    tdefs = TileDefinitions.read(path)
    tileset = tdefs.tilesets[0]
    assert tileset.name == sheet, tileset.name
    changed = 0
    for i, item in wanted.items():
        old = dict(tileset.tiles[i].props)
        want = {**old, "CustomItem": item}
        if old != want:
            assert {k: v for k, v in old.items() if k != "CustomItem"} == {k: v for k, v in want.items() if k != "CustomItem"}
            tileset.tiles[i] = Tile(want)
            changed += 1
    tdefs.write(path)
    again = TileDefinitions.read(path).tilesets[0]
    for i, item in wanted.items():
        assert dict(again.tiles[i].props).get("CustomItem") == item, i
    print(f"{sheet}: CustomItem set on {changed} tiles")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--forge", type=Path, required=True)
    args = parser.parse_args()
    os.environ["PZ_FORGE"] = str(args.forge)
    sys.path.insert(0, str(args.forge))
    install(TILES, *wanted_base())
    install(X_TILES, *wanted_extended())


if __name__ == "__main__":
    main()
