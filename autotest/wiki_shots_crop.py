"""Crop the raw wiki captures of a pzdev run into docs/images/screenshots.

Captures come from autotest/lw_wiki_hooks.lua (scenarios wiki_shots_base.json and
wiki_shots_ext.json), 1280 x 720, named wiki_<name>-<lang>.png in the run folder.

    python autotest/wiki_shots_crop.py runs/<run> [runs/<run> ...]
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs" / "images" / "screenshots"

# name (or name-lang) -> crop box (left, top, right, bottom) on the 1280 x 720 capture
BOXES = {
    "solar-menu": (380, 180, 1260, 610),
    "pump-barrels": (420, 200, 1010, 560),
    "consumers-public-grid": (240, 50, 1280, 630),
    "inverter-mains": (110, 90, 980, 560),
    "inverter-public-grid": (110, 90, 980, 560),
    "dismantle-recipe": (0, 0, 1005, 575),
    "connect-building": (240, 50, 1280, 560),
    "board-window": (115, 55, 905, 622),
    "board-window-fr": (115, 55, 905, 653),
    "board-tint": (0, 55, 1280, 652),
    "zone-tool": (60, 55, 1280, 635),
}
LIMIT = 1_500_000


def crop(src: Path) -> Path:
    stem = src.stem[len("wiki_"):]
    name, lang = stem.rsplit("-", 1)
    box = BOXES.get(f"{name}-{lang}", BOXES[name])
    img = Image.open(src).convert("RGB").crop(box)
    dst = OUT / f"{name}-{lang}.png"
    img.save(dst, optimize=True)
    if dst.stat().st_size > LIMIT:
        img.quantize(colors=256, method=Image.Quantize.MEDIANCUT).save(dst, optimize=True)
    return dst


def main(runs: list[str]) -> int:
    OUT.mkdir(parents=True, exist_ok=True)
    for run in runs:
        for src in sorted(Path(run).glob("wiki_*.png")):
            dst = crop(src)
            print(f"{dst.relative_to(ROOT)}  {dst.stat().st_size // 1024} KB")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
