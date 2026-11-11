"""Require a screwdriver to place every Live Wire and LiveWire Extended tile; keep every pixel.

Adds PlaceTool = Electrician (Base.Screwdriver, ISMoveableDefinitions.lua:313) to each tile
that already has PickUpTool = Electrician, in the two .tiles files only (texture packs and
depth maps are untouched). No PlaceLevel/PickUpLevel: the vanilla moveable cursor then asks
for the screwdriver but no Electrical level (ISMoveableSpriteProps.lua:480-494, 1959).
build_livewire_tiles.py and build_extended_tiles.py write the same property on a rebuild.

    python source/tiles/install_place_tool.py --forge <pz-sprite-forge clone>
"""
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
FILES = [
    ROOT / "Contents/mods/batman_LiveWire/common/media/batman_livewire_01.tiles",
    ROOT / "Contents/mods/batman_LiveWireExtended/common/media/batman_livewireext_01.tiles",
]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--forge", type=Path, required=True)
    args = parser.parse_args()
    sys.path.insert(0, str(args.forge))
    from pzforge.tiledef import TileDefinitions

    for path in FILES:
        tdefs = TileDefinitions.read(path)
        changed = 0
        for tileset in tdefs.tilesets:
            for tile in tileset.tiles:
                if tile.props.get("PickUpTool") == "Electrician" and tile.props.get("PlaceTool") != "Electrician":
                    tile.props["PlaceTool"] = "Electrician"
                    changed += 1
        if changed:
            tdefs.write(path)
        print(f"{path.name}: PlaceTool added to {changed} tiles")


if __name__ == "__main__":
    main()
