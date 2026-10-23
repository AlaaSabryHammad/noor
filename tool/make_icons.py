"""Draws the NOOR app icon (emerald field, gold eight-point khatam) and writes
the Android mipmaps and the iOS AppIcon set.

Run from the project root:  python tool/make_icons.py
Requires Pillow.
"""
import json
import math
import os

from PIL import Image, ImageDraw

SS = 4  # supersampling factor
SIZE = 1024
EMERALD_TOP, EMERALD_BOTTOM = (11, 117, 101), (5, 62, 55)
GOLD, GOLD_SOFT = (224, 196, 134), (200, 164, 93)


def gradient(n):
    img = Image.new("RGB", (n, n))
    px = img.load()
    for y in range(n):
        for x in range(n):
            t = (x + y) / (2 * (n - 1))  # diagonal, like the in-app hero surface
            px[x, y] = tuple(round(a + (b - a) * t) for a, b in zip(EMERALD_TOP, EMERALD_BOTTOM))
    return img


def star_points(cx, cy, r):
    """Union outline of a square and its 45° rotation (16 vertices)."""
    inner = r * math.cos(math.pi / 4) / math.cos(math.pi / 8)
    pts = []
    for i in range(16):
        a = -math.pi / 2 + i * math.pi / 8
        rad = r if i % 2 == 0 else inner
        pts.append((cx + math.cos(a) * rad, cy + math.sin(a) * rad))
    return pts


def draw_icon():
    n = SIZE * SS
    img = gradient(n // 4).resize((n, n), Image.BILINEAR)  # gradient is smooth; build small and upscale
    d = ImageDraw.Draw(img, "RGBA")
    c = n / 2
    # faint repeating khatam pattern, as on the hero cards
    cell = n / 8
    for gy in range(-1, 9):
        for gx in range(-1, 9):
            px, py = gx * cell + cell / 2, gy * cell + cell / 2
            s = cell * 0.18
            d.rectangle([px - s, py - s, px + s, py + s], outline=(255, 255, 255, 22), width=SS * 2)
            dd = s * math.sqrt(2)
            d.polygon([(px, py - dd), (px + dd, py), (px, py + dd), (px - dd, py)], outline=(255, 255, 255, 22), width=SS * 2)
    # soft glow behind the star
    glow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([c - n * 0.33, c - n * 0.33, c + n * 0.33, c + n * 0.33], fill=GOLD + (40,))
    img = Image.alpha_composite(img.convert("RGBA"), glow)
    # The star is drawn on its own layer: Pillow does not blend alpha when drawing straight onto an RGBA image.
    fill = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    pts = star_points(c, c, n * 0.30)
    ImageDraw.Draw(fill).polygon(pts, fill=GOLD + (46,))
    img = Image.alpha_composite(img, fill)
    lines = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lines)
    ld.line(pts + [pts[0]], fill=GOLD + (255,), width=SS * 16, joint="curve")
    pts2 = star_points(c, c, n * 0.17)
    ld.line(pts2 + [pts2[0]], fill=GOLD_SOFT + (255,), width=SS * 8, joint="curve")
    ld.ellipse([c - n * 0.035, c - n * 0.035, c + n * 0.035, c + n * 0.035], fill=GOLD + (255,))
    img = Image.alpha_composite(img, lines)
    return img.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)


def save(img, path, px):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.resize((px, px), Image.LANCZOS).save(path, "PNG", optimize=True)


def main():
    icon = draw_icon()
    save(icon, "assets/icon/noor_icon.png", 1024)
    # Android launcher icons
    for folder, px in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
        save(icon, f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png", px)
    # iOS: every entry of the existing AppIcon set (opaque RGB, as the App Store requires)
    base = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.load(open(f"{base}/Contents.json", encoding="utf-8"))
    for item in contents["images"]:
        if "filename" not in item:
            continue
        w = float(item["size"].split("x")[0])
        scale = int(item["scale"].rstrip("x"))
        save(icon, f"{base}/{item['filename']}", round(w * scale))
    print("icons written")


if __name__ == "__main__":
    main()
