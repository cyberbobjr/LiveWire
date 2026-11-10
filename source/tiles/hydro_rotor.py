"""Standalone recipe for the animated water wheel (added in 1.8.0).

Restricts build_livewire_tiles.py to the water wheel base tiles (8-11, now drawn
without their wheel) and the four wheel frames (overlays 104-119), so the depth map
tool and install_hydro_rotor.py touch nothing else. Sprite IDs never move.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_livewire_tiles as base  # noqa: E402

KEYS = ("hydro", "hydro_rotor0", "hydro_rotor1", "hydro_rotor2", "hydro_rotor3")
#: Base tiles redrawn in place (pixels, depth and the CustomItem property change).
REPLACED = (8, 9, 10, 11)

materials = base.materials
build_group = base.build_group


def tile_groups():
    return [g for g in base.tile_groups() if g["key"] in KEYS]


def indices():
    return sorted(i for g in tile_groups() for i in g["indices"])


def added():
    return [i for i in indices() if i not in REPLACED]


def build(subject, mats):
    base.build_hydro(base.Kit(subject, mats), wheel=True)
