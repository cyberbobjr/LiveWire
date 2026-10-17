"""Item icons of the mod, drawn with Pillow (original artwork, no game asset reused).

    python source/icons/make_item_icons.py

Writes media/textures/Item_LiveWireSolarCell.png and Item_LiveWireSoundproofKit.png (64 x 64 RGBA, like
Item_LiveWireWindTurbine.png). Each icon is drawn at 4x on a transparent canvas, outlined, then reduced.
"""
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "Contents", "mods", "batman_LiveWire", "42.21", "media", "textures")
S = 256  # drawing size, reduced to 64

OUTLINE = (24, 26, 30, 255)


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def quad_point(q, u, v):
    """Point at (u, v) in [0, 1]^2 of the quad q = (top-left, top-right, bottom-right, bottom-left)."""
    top = lerp(q[0], q[1], u)
    bottom = lerp(q[3], q[2], u)
    return lerp(top, bottom, v)


def outlined(im, width=10):
    """Dark outline around the opaque shape, like the game's item icons."""
    alpha = im.getchannel("A").point(lambda a: 255 if a > 40 else 0)
    grown = alpha.filter(ImageFilter.MaxFilter(width * 2 + 1))
    ring = ImageChops.subtract(grown, alpha)
    base = Image.new("RGBA", im.size, (0, 0, 0, 0))
    base.paste(Image.new("RGBA", im.size, OUTLINE), (0, 0), ring)
    base.alpha_composite(im)
    return base


def finish(im, name):
    im = outlined(im)
    bb = im.getbbox()
    im = im.crop(bb)
    side = max(im.size) + 16
    sq = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    sq.paste(im, ((side - im.width) // 2, (side - im.height) // 2))
    sq = sq.resize((64, 64), Image.LANCZOS)
    path = os.path.join(OUT, name)
    sq.save(path)
    print("wrote", os.path.relpath(path, ROOT))


def solar_cell():
    """A single photovoltaic cell seen at an angle: blue wafer, silver busbars, two solder tabs."""
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    q = [(70, 40), (226, 78), (186, 214), (30, 176)]  # wafer
    edge = [(q[0][0], q[0][1]), (q[1][0], q[1][1]), (q[2][0], q[2][1] + 12), (q[3][0], q[3][1] + 12)]
    d.polygon(edge, fill=(120, 128, 140, 255))  # thickness
    d.polygon(q, fill=(28, 58, 120, 255))
    # Light gradient across the wafer: lighter strip toward the top edge.
    for i in range(10):
        t0, t1 = i / 10, (i + 1) / 10
        c = (28 + int(30 * (1 - t0)), 58 + int(40 * (1 - t0)), 120 + int(60 * (1 - t0)), 255)
        d.polygon([quad_point(q, 0, t0), quad_point(q, 1, t0), quad_point(q, 1, t1), quad_point(q, 0, t1)], fill=c)
    # Fine grid fingers.
    for k in range(1, 12):
        v = k / 12
        d.line([quad_point(q, 0.02, v), quad_point(q, 0.98, v)], fill=(150, 170, 205, 255), width=2)
    # Busbars.
    for u in (0.33, 0.66):
        d.line([quad_point(q, u, 0), quad_point(q, u, 1)], fill=(225, 228, 232, 255), width=7)
    # Solder tabs sticking out at the bottom.
    for u in (0.33, 0.66):
        a = quad_point(q, u, 1)
        d.line([a, (a[0] - 10, a[1] + 34)], fill=(210, 212, 216, 255), width=8)
    finish(im, "Item_LiveWireSolarCell.png")


def soundproof_kit():
    """Two stacked acoustic foam panels (egg-crate pattern) held by a strap."""
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)

    def panel(y0, top_col, side_col):
        top = [(30, y0 + 40), (128, y0), (226, y0 + 40), (128, y0 + 80)]
        d.polygon([top[3], top[2], (226, y0 + 70), (128, y0 + 110)], fill=side_col)  # right side
        d.polygon([top[0], top[3], (128, y0 + 110), (30, y0 + 70)],
                  fill=tuple(max(0, c - 18) for c in side_col[:3]) + (255,))  # left side
        d.polygon(top, fill=top_col)
        # Egg-crate bumps: small diamonds with a light and a dark face.
        for i in range(4):
            for j in range(4):
                c = quad_point(top, (i + 0.5) / 4, (j + 0.5) / 4)
                r = 9
                d.polygon([(c[0], c[1] - r), (c[0] + r * 1.6, c[1]), (c[0], c[1] + r)],
                          fill=tuple(min(255, x + 28) for x in top_col[:3]) + (255,))
                d.polygon([(c[0], c[1] - r), (c[0] - r * 1.6, c[1]), (c[0], c[1] + r)],
                          fill=tuple(max(0, x - 22) for x in top_col[:3]) + (255,))

    panel(110, (92, 96, 104, 255), (70, 74, 82, 255))
    panel(70, (104, 108, 116, 255), (78, 82, 90, 255))
    # Strap around the stack.
    d.polygon([(150, 60), (166, 68), (166, 196), (150, 188)], fill=(150, 98, 52, 255))
    d.polygon([(166, 68), (184, 60), (184, 188), (166, 196)], fill=(122, 78, 40, 255))
    d.rectangle((158, 120, 176, 136), fill=(205, 208, 212, 255))  # buckle
    finish(im, "Item_LiveWireSoundproofKit.png")


if __name__ == "__main__":
    solar_cell()
    soundproof_kit()
