#!/usr/bin/env python3
"""Deploy high-quality cuisine illustration PNGs to app assets and backend uploads."""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ASSETS = Path("/Users/apple/.cursor/projects/Users-apple-MadeByMaa-customer/assets")
OUT_SIZE = 512
OUT_DIRS = [
    Path("/Users/apple/MadeByMaa/customer/assets/images/cuisines"),
    Path("/Users/apple/Ecommerce Websites/optica2/public/uploads/cuisines"),
]

# source filename prefix -> (slug, display name)
CUISINES: list[tuple[str, str, str]] = [
    ("north_indian-", "north_indian", "North Indian"),
    ("bengali-", "bengali", "Bengali"),
    ("south_indian-", "south_indian", "South Indian"),
    ("rajasthani-", "rajasthani", "Rajasthani"),
    ("chinese-", "chinese", "Chinese"),
    ("bihari-", "bihari", "Bihari"),
    ("gujarti-", "gujarati", "Gujarati"),
    ("mughali-", "mughlai", "Mughlai"),
    ("Odisha-", "odisha", "Odisha"),
    ("kerala-", "kerala", "Kerala"),
    ("tamil-", "tamil", "Tamil"),
    ("punjabi-", "punjabi", "Punjabi"),
    ("Maharashtrian-", "maharashtrian", "Maharashtrian"),
]


def find_source(prefix: str) -> Path | None:
    for path in ASSETS.glob(f"{prefix}*"):
        if path.is_file():
            return path
    return None


def to_png(src: Path, dest: Path) -> None:
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    side = min(w, h)
    left, top = (w - side) // 2, (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    img = img.resize((OUT_SIZE, OUT_SIZE), Image.Resampling.LANCZOS)
    img.save(dest, "PNG")


def main() -> None:
    for out_dir in OUT_DIRS:
        out_dir.mkdir(parents=True, exist_ok=True)

    for prefix, slug, name in CUISINES:
        src = find_source(prefix)
        if src is None:
            existing = OUT_DIRS[0] / f"{slug}.png"
            if existing.exists():
                print(f"skip {name}: no new source, keeping existing {slug}.png")
                continue
            print(f"WARN {name}: source not found ({prefix}*)")
            continue

        for out_dir in OUT_DIRS:
            to_png(src, out_dir / f"{slug}.png")
        print(f"saved {name} <- {src.name}")


if __name__ == "__main__":
    main()
