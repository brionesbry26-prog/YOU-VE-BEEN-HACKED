#!/usr/bin/env python3
"""Generates the "I Love You" launcher icons: a minimal white heart on a
near-black background with a subtle red accent. Pure Python + Pillow.

Usage (from the project root): python3 tool/generate_icon.py
"""

import math
import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
BG = (5, 5, 5)
RED = (255, 23, 68)
SS = 4  # supersampling factor


def heart_points(cx, cy, scale):
    pts = []
    for i in range(720):
        t = 2 * math.pi * i / 720
        x = 16 * math.sin(t) ** 3
        y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)
        pts.append((cx + x * scale, cy - y * scale))
    return pts


def render(size, heart_ratio=0.56, background=True):
    """Returns an RGBA image; heart_ratio is the heart width / icon size."""
    s = size * SS
    img = Image.new("RGBA", (s, s), BG + (255,) if background else (0, 0, 0, 0))
    scale = s * heart_ratio / 32.0
    cx, cy = s / 2, s / 2 + s * 0.02

    # Subtle red accent: a soft red glow and a thin offset red echo.
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(glow).polygon(heart_points(cx, cy, scale * 1.04), fill=RED + (90,))
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.035))
    img = Image.alpha_composite(img, glow)
    echo = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    off = s * 0.014
    ImageDraw.Draw(echo).polygon(heart_points(cx + off, cy + off, scale), fill=RED + (210,))
    img = Image.alpha_composite(img, echo)

    white = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    ImageDraw.Draw(white).polygon(heart_points(cx, cy, scale), fill=(245, 245, 245, 255))
    img = Image.alpha_composite(img, white)
    return img.resize((size, size), Image.LANCZOS)


def save(img, path, rgb=False):
    path = os.path.join(ROOT, path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (img.convert("RGB") if rgb else img).save(path)
    print("wrote", os.path.relpath(path, ROOT), img.size[0])


def main():
    android = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for density, px in android.items():
        save(render(px), f"android/app/src/main/res/mipmap-{density}/ic_launcher.png")
        # Adaptive icon foreground: 108dp canvas, heart inside the 66dp safe zone.
        fg = round(px * 108 / 48)
        save(render(fg, heart_ratio=0.36, background=False),
             f"android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png")

    ios_dir = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    for name in sorted(os.listdir(os.path.join(ROOT, ios_dir))):
        if name.endswith(".png"):
            px = Image.open(os.path.join(ROOT, ios_dir, name)).size[0]
            save(render(px), f"{ios_dir}/{name}", rgb=True)  # iOS icons: no alpha

    for rel in ["web/favicon.png", "web/icons/Icon-192.png", "web/icons/Icon-512.png",
                "web/icons/Icon-maskable-192.png", "web/icons/Icon-maskable-512.png"]:
        px = Image.open(os.path.join(ROOT, rel)).size[0]
        ratio = 0.42 if "maskable" in rel else 0.56
        save(render(px, heart_ratio=ratio), rel)

    mac_dir = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    for name in sorted(os.listdir(os.path.join(ROOT, mac_dir))):
        if name.endswith(".png"):
            px = Image.open(os.path.join(ROOT, mac_dir, name)).size[0]
            save(render(px), f"{mac_dir}/{name}")

    save(render(512), "tool/icon_preview.png")


if __name__ == "__main__":
    main()
