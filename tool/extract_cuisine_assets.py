#!/usr/bin/env python3
"""Extract cuisine circle illustrations from the reference screenshot."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw

SOURCE = Path(
    "/Users/apple/.cursor/projects/Users-apple-MadeByMaa-customer/assets/"
    "WhatsApp_Image_2026-05-30_at_00.48.25-e7995c3d-6b73-47a8-826f-f56ea4ec0e91.png"
)
OUT_SIZE = 128

# (name, center_x, center_y, radius) — hand-calibrated from the screenshot grid.
CUISINES: list[tuple[str, int, int, int]] = [
    ("north_indian", 52, 272, 30),
    ("bengali", 181, 272, 30),
    ("south_indian", 289, 270, 28),
    ("rajasthani", 418, 274, 31),
    ("chinese", 52, 664, 34),
    ("bihari", 173, 664, 34),
    ("gujarati", 297, 664, 34),
    ("mughlai", 419, 664, 34),
    ("odisha", 52, 516, 34),
    ("kerala", 175, 516, 34),
    ("tamil", 297, 516, 34),
    ("punjabi", 421, 516, 34),
]

OUT_DIRS = [
    Path("/Users/apple/MadeByMaa/customer/assets/images/cuisines"),
    Path("/Users/apple/Ecommerce Websites/optica2/public/uploads/cuisines"),
]


def extract_one(img: Image.Image, cx: int, cy: int, radius: int) -> Image.Image:
    size = radius * 2
    left, top = cx - radius, cy - radius
    crop = img.crop((left, top, left + size, top + size))
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result.paste(crop, (0, 0), mask)
    return result.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Source screenshot not found: {SOURCE}")

    img = Image.open(SOURCE).convert("RGBA")
    for out_dir in OUT_DIRS:
        out_dir.mkdir(parents=True, exist_ok=True)

    for name, cx, cy, radius in CUISINES:
        png = extract_one(img, cx, cy, radius)
        for out_dir in OUT_DIRS:
            png.save(out_dir / f"{name}.png", "PNG")
        print(f"saved {name} @ ({cx},{cy}) r={radius}")

    print(f"Done — {len(CUISINES)} cuisines written to {len(OUT_DIRS)} dirs.")


if __name__ == "__main__":
    main()
