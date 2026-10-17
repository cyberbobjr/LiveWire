"""Live Wire app icon for the Computer Mod desktop (64 x 64): a yellow lightning
bolt on a dark rounded square. Run: python source/ui/make_app_icon.py"""
from PIL import Image, ImageDraw

S = 4  # supersampling
img = Image.new("RGBA", (64 * S, 64 * S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle((2 * S, 2 * S, 62 * S, 62 * S), radius=10 * S, fill=(28, 34, 40, 255),
                    outline=(120, 200, 120, 255), width=2 * S)
bolt = [(36, 8), (16, 36), (30, 36), (24, 56), (48, 26), (34, 26), (42, 8)]
d.polygon([(x * S, y * S) for x, y in bolt], fill=(250, 210, 40, 255), outline=(120, 90, 0, 255))
img.resize((64, 64), Image.LANCZOS).save("Contents/mods/batman_LiveWire/42.21/media/ui/LiveWire/App.png")
