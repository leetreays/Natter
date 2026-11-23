#!/usr/bin/env python3
"""Read-only Brim V1 asset audit. Run from the repository root.

    python3 tools/audit_brim_assets.py

Requires Pillow (developer tooling only): python3 -m pip install Pillow
Does not modify artwork, Flutter files, or Git state.
"""
from __future__ import annotations

import hashlib
import sys
from pathlib import Path

try:
    from PIL import Image, UnidentifiedImageError
except ImportError:
    print("Pillow is required for artwork QA. Install: python3 -m pip install Pillow")
    raise SystemExit(2)

COLOURS = ("violet", "blue", "mint")
EXPRESSIONS = ("gentle", "playful", "cheeky")
ACCESSORIES = ("none", "scarf", "satchel")
SIZE = (512, 512)
ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "avatar_prototype"


def main() -> int:
    expected = {
        f"brim_v1_{colour}_{expression}_{accessory}.webp"
        for colour in COLOURS
        for expression in EXPRESSIONS
        for accessory in ACCESSORIES
    }
    failures: list[str] = []
    total_bytes = 0
    alpha_by_accessory: dict[str, bytes] = {}
    digest_by_name: dict[str, str] = {}
    sizes_by_colour: dict[str, int] = {name: 0 for name in COLOURS}

    for colour in COLOURS:
        for accessory in ACCESSORIES:
            for expression in EXPRESSIONS:
                name = f"brim_v1_{colour}_{expression}_{accessory}.webp"
                path = ASSETS / name
                if not path.is_file():
                    failures.append(f"Missing asset: {path}")
                    continue
                try:
                    with Image.open(path) as image:
                        if image.format != "WEBP":
                            failures.append(f"Not a WebP file: {name}")
                            continue
                        if image.size != SIZE:
                            failures.append(f"Wrong canvas {image.size}: {name}")
                            continue
                        rgba = image.convert("RGBA")
                        rgba.load()
                except (OSError, UnidentifiedImageError) as error:
                    failures.append(f"Cannot decode {name}: {error}")
                    continue

                alpha = rgba.getchannel("A")
                minimum, maximum = alpha.getextrema()
                if minimum != 0 or maximum != 255:
                    failures.append(
                        f"Expected transparent background and opaque artwork: {name}"
                    )
                if rgba.getbbox() is None:
                    failures.append(f"Empty artwork: {name}")
                # All expressions and colourways for the same accessory are
                # produced from pixel-locked masters; detect accidental redraws.
                fingerprint = hashlib.sha256(alpha.tobytes()).digest()
                previous = alpha_by_accessory.setdefault(accessory, fingerprint)
                if previous != fingerprint:
                    failures.append(f"Silhouette/alpha differs for {accessory}: {name}")
                digest_by_name[name] = hashlib.sha256(path.read_bytes()).hexdigest()
                size = path.stat().st_size
                total_bytes += size
                sizes_by_colour[colour] += size

    extras = sorted(
        path.name for path in ASSETS.glob("brim_v1_*.webp")
        if path.name not in expected
    )
    if extras:
        print(f"Note: {len(extras)} non-V1-catalogue local trial images were ignored.")
        print("  Do not include old 'delighted' artwork in release commits.")
    if len(digest_by_name) != 27:
        failures.append(
            f"Validated {len(digest_by_name)}/27 required files."
        )
    if len(set(digest_by_name.values())) != len(digest_by_name):
        failures.append("Duplicate image files detected among approved variants.")

    if failures:
        print("BRIM ARTWORK AUDIT FAILED")
        for failure in failures:
            print(" - " + failure)
        return 1

    print("BRIM ARTWORK AUDIT PASSED: all 27 images decode as 512x512 WebP.")
    print("Every colour/expression shares the exact approved alpha per accessory.")
    for colour in COLOURS:
        print(
            f"  {colour.title():6} 9 files, "
            f"{sizes_by_colour[colour]/1024/1024:.2f} MiB"
        )
    print(f"  Total: {total_bytes/1024/1024:.2f} MiB compressed.")
    print("  RGBA decode footprint if all 27 are cached: about 27 MiB.")
    print("  This audits artwork, not runtime network performance or animation.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
