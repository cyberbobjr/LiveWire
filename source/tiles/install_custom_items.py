"""Give every facing of every Live Wire device tile its CustomItem (the device's own moveable item).

Without it, picking up a device turned to a facing other than its item's WorldObjectSprite gives a
generic moveable named after the sprite (Base.batman_livewire_01_13 for an inverter facing east:
ISMoveableSpriteProps.instanceItem, ISMoveableSpriteProps.lua:215-226), which the dismantle recipes and
the device code do not recognise. Only the CustomItem property is added; every other property and every
sprite stay as they are.

Usage (from the LiveWire folder): python source/tiles/install_custom_items.py --forge <pz-sprite-forge dir>
build_livewire_tiles.py carries the same property (PROPS), so a full rebuild keeps it.
"""
import argparse
import os
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
TILES = HERE.parents[1] / "Contents/mods/batman_LiveWire/common/media/batman_livewire_01.tiles"
sys.path.insert(0, str(HERE))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--forge", type=Path, required=True)
    args = parser.parse_args()
    os.environ["PZ_FORGE"] = str(args.forge)
    sys.path.insert(0, str(args.forge))
    from pzforge.tiledef import Tile, TileDefinitions
    import build_livewire_tiles as recipe

    tdefs = TileDefinitions.read(TILES)
    tileset = tdefs.tilesets[0]
    assert tileset.name == recipe.SHEET, tileset.name
    changed = 0
    for rng, props in recipe.PROPS:
        item = props.get("CustomItem")
        assert item, f"no CustomItem in PROPS for tiles {rng}"
        for i in rng:
            old = dict(tileset.tiles[i].props)
            want = {**old, "CustomItem": item}
            if old != want:
                assert {k: v for k, v in old.items() if k != "CustomItem"} == {k: v for k, v in want.items() if k != "CustomItem"}
                tileset.tiles[i] = Tile(want)
                changed += 1
    tdefs.write(TILES)
    again = TileDefinitions.read(TILES).tilesets[0]
    for rng, props in recipe.PROPS:
        for i in rng:
            assert dict(again.tiles[i].props).get("CustomItem") == props["CustomItem"], i
    print(f"CustomItem set on {changed} tiles")


if __name__ == "__main__":
    main()
