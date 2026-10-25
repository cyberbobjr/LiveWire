"""Standalone recipe for the added breaker power light and its B42 depth map.

Uses the existing enclosure as a holdout. Sprite IDs 84/85 were reserved blanks;
all placed tiles, properties and persistent IDs remain unchanged.
"""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_livewire_tiles as base

materials = base.materials
build_group = base.build_group

def tile_groups():
    return [g for g in base.tile_groups() if g['key'] == 'breaker_on']

def build(subject, mats):
    base.build_group(subject, mats, tile_groups()[0])
