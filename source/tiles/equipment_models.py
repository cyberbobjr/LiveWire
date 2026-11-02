"""Standalone recipe for the inverter cabinet cells (model contributed by PewPewCricket).

Restricts build_livewire_tiles.py to the cabinet groups (base tile 88-91 and its
overlays 92-103), so the depth map tool and install_equipment_models.py touch
nothing else. Existing sprite IDs, tile properties and persistent IDs stay unchanged.
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_livewire_tiles as base  # noqa: E402

KEYS = ("cabinet", "cabinet_on", "cabinet_fault", "cabinet_muffle")

materials = base.materials
build_group = base.build_group


def tile_groups():
    return [g for g in base.tile_groups() if g["key"] in KEYS]


def indices():
    return sorted(i for g in tile_groups() for i in g["indices"])


def build(subject, mats):
    base.build_group(subject, mats, tile_groups()[0])
