"""Generate the Live Wire placeholder 3D models: simple boxes and cylinders (.glb)
and flat-colour textures (.png).

Run: python3 -I tools/make_placeholder_models.py
Output: Contents/mods/batman_LiveWire/42.21/media/models_X/LiveWire/*.glb
        Contents/mods/batman_LiveWire/42.21/media/textures/LiveWire/*.png

The game loads .glb meshes from media/models_X (FileTask_AbstractLoadModel.java:63-122).
Sizes are in metres, Y up (glTF convention). The in-game scale of a .glb item model
is an assumption to check in game (scale = 1.0 in LiveWire_models.txt).
These are placeholders until the final Blender models exist.
"""
import json
import math
import os
import struct
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MEDIA = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media")
MODELS = os.path.join(MEDIA, "models_X", "LiveWire")
TEXTURES = os.path.join(MEDIA, "textures", "LiveWire")


def box(w, h, d):
    """Axis-aligned box resting on y = 0. Returns positions, normals, uvs, indices."""
    x, z = w / 2, d / 2
    faces = [
        ((0, 1, 0), [(-x, h, -z), (x, h, -z), (x, h, z), (-x, h, z)]),
        ((0, -1, 0), [(-x, 0, z), (x, 0, z), (x, 0, -z), (-x, 0, -z)]),
        ((0, 0, 1), [(-x, 0, z), (-x, h, z), (x, h, z), (x, 0, z)]),
        ((0, 0, -1), [(x, 0, -z), (x, h, -z), (-x, h, -z), (-x, 0, -z)]),
        ((1, 0, 0), [(x, 0, z), (x, h, z), (x, h, -z), (x, 0, -z)]),
        ((-1, 0, 0), [(-x, 0, -z), (-x, h, -z), (-x, h, z), (-x, 0, z)]),
    ]
    pos, nor, uv, idx = [], [], [], []
    for n, quad in faces:
        base = len(pos)
        for i, p in enumerate(quad):
            pos.append(p)
            nor.append(n)
            uv.append([(0, 0), (0, 1), (1, 1), (1, 0)][i])
        idx += [base, base + 1, base + 2, base, base + 2, base + 3]
    return pos, nor, uv, idx


def cylinder(r, h, seg=16):
    """Vertical cylinder resting on y = 0."""
    pos, nor, uv, idx = [], [], [], []
    for i in range(seg + 1):
        a = 2 * math.pi * i / seg
        c, s = math.cos(a), math.sin(a)
        pos += [(r * c, 0, r * s), (r * c, h, r * s)]
        nor += [(c, 0, s), (c, 0, s)]
        uv += [(i / seg, 0), (i / seg, 1)]
    for i in range(seg):
        a, b = 2 * i, 2 * i + 2
        idx += [a, a + 1, b + 1, a, b + 1, b]
    for y, ny in ((h, 1), (0, -1)):
        centre = len(pos)
        pos.append((0, y, 0))
        nor.append((0, ny, 0))
        uv.append((0.5, 0.5))
        for i in range(seg + 1):
            a = 2 * math.pi * i / seg
            pos.append((r * math.cos(a), y, r * math.sin(a)))
            nor.append((0, ny, 0))
            uv.append((0.5 + 0.5 * math.cos(a), 0.5 + 0.5 * math.sin(a)))
        for i in range(seg):
            p, q = centre + 1 + i, centre + 2 + i
            idx += [centre, q, p] if ny > 0 else [centre, p, q]
    return pos, nor, uv, idx


def write_glb(path, mesh):
    pos, nor, uv, idx = mesh
    blob = b"".join(struct.pack("<3f", *p) for p in pos)
    off_nor = len(blob)
    blob += b"".join(struct.pack("<3f", *n) for n in nor)
    off_uv = len(blob)
    blob += b"".join(struct.pack("<2f", *t) for t in uv)
    off_idx = len(blob)
    blob += b"".join(struct.pack("<H", i) for i in idx)
    while len(blob) % 4:
        blob += b"\x00"
    mins = [min(p[k] for p in pos) for k in range(3)]
    maxs = [max(p[k] for p in pos) for k in range(3)]
    n = len(pos)
    gltf = {
        "asset": {"version": "2.0", "generator": "LiveWire placeholder"},
        "scene": 0,
        "scenes": [{"nodes": [0]}],
        "nodes": [{"mesh": 0, "name": os.path.splitext(os.path.basename(path))[0]}],
        "meshes": [{"primitives": [{
            "attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2},
            "indices": 3, "mode": 4}]}],
        "buffers": [{"byteLength": len(blob)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": 0, "byteLength": off_nor, "target": 34962},
            {"buffer": 0, "byteOffset": off_nor, "byteLength": off_uv - off_nor, "target": 34962},
            {"buffer": 0, "byteOffset": off_uv, "byteLength": off_idx - off_uv, "target": 34962},
            {"buffer": 0, "byteOffset": off_idx, "byteLength": len(idx) * 2, "target": 34963},
        ],
        "accessors": [
            {"bufferView": 0, "componentType": 5126, "count": n, "type": "VEC3", "min": mins, "max": maxs},
            {"bufferView": 1, "componentType": 5126, "count": n, "type": "VEC3"},
            {"bufferView": 2, "componentType": 5126, "count": n, "type": "VEC2"},
            {"bufferView": 3, "componentType": 5123, "count": len(idx), "type": "SCALAR"},
        ],
    }
    js = json.dumps(gltf, separators=(",", ":")).encode("ascii")
    while len(js) % 4:
        js += b" "
    total = 12 + 8 + len(js) + 8 + len(blob)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sII", b"glTF", 2, total))
        f.write(struct.pack("<I4s", len(js), b"JSON"))
        f.write(js)
        f.write(struct.pack("<I4s", len(blob), b"BIN\x00"))
        f.write(blob)


def write_texture(path, rgb):
    img = Image.new("RGB", (32, 32), rgb)
    # A darker border makes the shape readable.
    px = img.load()
    dark = tuple(max(0, int(c * 0.6)) for c in rgb)
    for i in range(32):
        for j in (0, 31):
            px[i, j] = dark
            px[j, i] = dark
    img.save(path)


# name: (mesh, colour)
PLACEHOLDERS = {
    "VoltageTester": (box(0.07, 0.03, 0.14), (230, 190, 40)),
    "SolarPanelKit": (box(0.60, 0.04, 0.40), (40, 70, 140)),
    "WindTurbineKit": (cylinder(0.10, 0.70), (200, 200, 205)),
    "InverterKit": (box(0.30, 0.18, 0.22), (90, 95, 100)),
    "HeavyInverterKit": (box(0.40, 0.24, 0.30), (60, 64, 70)),
    "BreakerKit": (box(0.20, 0.06, 0.26), (200, 205, 210)),
    "SolarCell": (box(0.10, 0.005, 0.10), (30, 50, 110)),
}


def main():
    os.makedirs(MODELS, exist_ok=True)
    os.makedirs(TEXTURES, exist_ok=True)
    for name, (mesh, colour) in PLACEHOLDERS.items():
        write_glb(os.path.join(MODELS, name + ".glb"), mesh)
        write_texture(os.path.join(TEXTURES, name + ".png"), colour)
    print("wrote %d placeholder models" % len(PLACEHOLDERS))
    return 0


if __name__ == "__main__":
    sys.exit(main())
