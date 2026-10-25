"""Make crafting/item icons from this mod's existing tile artwork.

python source/icons/extract_equipment_icons.py --forge <pz-sprite-forge>

Uses the local pack codec and Pillow; never edits the pack or tile definitions.
The turbine already has its own icon with blades and is deliberately preserved.
"""
import argparse
from io import BytesIO
from pathlib import Path
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MEDIA = ROOT / 'Contents/mods/batman_LiveWire'
SPRITES = {'SolarPanel': 0, 'WaterWheel': 8, 'Inverter': 12, 'PowerBank': 16,
           'Breaker': 20, 'BatteryAlarm': 22, 'WaterPump': 72}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--forge', required=True, type=Path)
    args = parser.parse_args()
    sys.path.insert(0, str(args.forge))
    from pzforge.packfile import TexturePack

    pack = TexturePack.read(MEDIA / 'common/media/texturepacks/batman_livewire_01.pack')
    sprites = {}
    for page in pack.pages:
        atlas = Image.open(BytesIO(page.png)).convert('RGBA')
        for entry in page.entries:
            sprites[entry.name] = atlas.crop((entry.x, entry.y, entry.x+entry.w, entry.y+entry.h))
    out = MEDIA / '42.21/media/textures'
    for name, index in SPRITES.items():
        sprite = sprites[f'batman_livewire_01_{index}']
        bounds = sprite.getbbox()
        if not bounds:
            raise ValueError(f'Empty sprite for {name}')
        sprite = sprite.crop(bounds)
        sprite.thumbnail((60, 60), Image.Resampling.LANCZOS)
        icon = Image.new('RGBA', (64, 64))
        icon.alpha_composite(sprite, ((64-sprite.width)//2, (64-sprite.height)//2))
        icon.save(out / f'Item_LiveWire{name}.png')
        print(f'Generated Item_LiveWire{name}.png')


if __name__ == '__main__':
    main()
