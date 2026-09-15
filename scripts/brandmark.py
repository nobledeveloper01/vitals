#!/usr/bin/env python3
"""
Draw the Vitals mark at every size the platforms want, and the README's.

The mark: a rounded square in the brand gradient — teal into violet at 135° —
with a single pulse line in white: flat, one beat up, one down, flat, ending
in a dot. The dot is the reading; the line is the trend it sits on. Drawn
here, not exported from a tool, so `make brandmark` reproduces every asset
and `make brandmark-check` fails when one drifts.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
TEAL, VIOLET = (0x0F, 0x6E, 0x7A), (0x5B, 0x3F, 0xA8)
TEAL_D, VIOLET_D = (0x5F, 0xD3, 0xDF), (0xB3, 0x9C, 0xFF)


def gradient(size, a, b):
    im = Image.new("RGB", (size, size))
    px = im.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
    return im


def mark(size, dark=False, ground=None):
    """The mark alone, on a transparent ground unless one is given."""
    s = size * 4  # drawn large, downsampled: the pulse line stays crisp
    grad = gradient(s, *(TEAL_D, VIOLET_D) if dark else (TEAL, VIOLET))
    mask = Image.new("L", (s, s), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, s - 1, s - 1), radius=int(s * 0.24), fill=255)
    im = Image.new("RGBA", (s, s), ground or (0, 0, 0, 0))
    im.paste(grad, (0, 0), mask)
    d = ImageDraw.Draw(im)
    w = int(s * 0.055)
    y0 = s * 0.56
    pts = [(s * 0.18, y0), (s * 0.40, y0), (s * 0.47, s * 0.30), (s * 0.55, s * 0.74), (s * 0.62, y0), (s * 0.74, y0)]
    d.line(pts, fill=(255, 255, 255, 255), width=w, joint="curve")
    r = int(s * 0.05)
    cx, cy = s * 0.80, y0
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 255, 255, 255))
    return im.resize((size, size), Image.LANCZOS)


def main():
    check = "--check" in sys.argv
    out = {
        ROOT / "docs/mark.png": mark(256),
        ROOT / "app/assets/mark/mark.png": mark(512),
        ROOT / "app/assets/mark/mark-dark.png": mark(512, dark=True),
    }
    # iOS: the 1024 app icon; Android: the launcher sizes.
    out[ROOT / "app/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"] = mark(1024, ground=(15, 110, 122, 255)).convert("RGB")
    for dpi, px in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
        out[ROOT / f"app/android/app/src/main/res/mipmap-{dpi}/ic_launcher.png"] = mark(px, ground=(15, 110, 122, 255)).convert("RGB")
    drift = []
    for path, im in out.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        if check:
            if not path.exists():
                drift.append(f"missing {path.relative_to(ROOT)}")
                continue
            old = Image.open(path).convert("RGBA")
            new = im.convert("RGBA")
            if old.size != new.size:
                drift.append(f"size {path.relative_to(ROOT)}")
                continue
            diff = sum(abs(a - b) for pa, pb in zip(old.getdata(), new.getdata()) for a, b in zip(pa, pb))
            if diff > old.size[0] * old.size[1] * 4 * 2:
                drift.append(f"drifted {path.relative_to(ROOT)}")
        else:
            im.save(path)
    if check:
        for d in drift:
            print(f"\033[0;31m✗\033[0m {d}")
        if drift:
            print("\033[0;31mbrand mark drifted\033[0m — run `make brandmark` and commit what it draws")
            return 1
        print(f"\033[0;32m✓\033[0m the mark is what the script draws, at {len(out)} sizes")
    else:
        print(f"drew the mark at {len(out)} sizes")
    return 0


if __name__ == "__main__":
    sys.exit(main())
