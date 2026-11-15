#!/usr/bin/env python3
"""Derive a pixel-locked Mint Brim test pair from the accepted Blue assets.

Development utility only; not part of the app or Flutter build.
Requires Pillow: python3 -m pip install Pillow

Run from the repository root, after installing accepted Blue/Gentle images:
    python3 tools/recolour_brim_palette.py

This is intentionally *not* a general character builder. It preserves the
original Blue geometry, expression, scarf and transparent silhouette.
"""
from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required for this developer-only artwork script. "
        "Install with: python3 -m pip install Pillow"
    ) from exc


ACCESSORIES = ("none", "scarf")
TARGET_HUE = 0.455  # Mint / seafoam, in HSV hue units.
COLOURWAY = "mint"


def clamp01(value: float) -> float:
    return max(0.0, min(1.0, value))


def remap_pixel(r: int, g: int, b: int) -> tuple[int, int, int]:
    """Transform blue/cyan material, not cream horns, belly or embroidery.

    Shadows and texture remain from the source image. Only pixels that are
    clearly blue-dominant and saturated can change hue. The weight fades
    smoothly near low-saturation detail and blue/beige material boundaries.
    """
    rn, gn, bn = r / 255.0, g / 255.0, b / 255.0
    h, saturation, value = colorsys.rgb_to_hsv(rn, gn, bn)
    if not 0.49 <= h <= 0.75:
        return r, g, b

    dominance = bn - rn
    weight = clamp01((dominance - 0.03) / 0.10)
    weight *= clamp01((saturation - 0.11) / 0.18)
    weight = weight * weight * (3.0 - 2.0 * weight)
    if weight <= 0:
        return r, g, b

    target = TARGET_HUE + 0.22 * (h - 0.60)
    hue = (h * (1.0 - weight) + target * weight) % 1.0
    sat = clamp01(saturation * (1.0 - 0.12 * weight) + 0.04 * weight)
    val = clamp01(value * (1.0 + 0.035 * weight))
    rr, gg, bb = colorsys.hsv_to_rgb(hue, sat, val)
    return round(255 * rr), round(255 * gg), round(255 * bb)


def recolour(source: Path, destination: Path) -> None:
    with Image.open(source) as original:
        rgba = original.convert("RGBA")

    # Same rules for both accessory states: never redraw, move or rescale.
    result = []
    cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}
    for r, g, b, alpha in rgba.getdata():
        if alpha == 0:
            result.append((r, g, b, alpha))
            continue
        rgb = (r, g, b)
        replacement = cache.get(rgb)
        if replacement is None:
            replacement = remap_pixel(r, g, b)
            cache[rgb] = replacement
        result.append((*replacement, alpha))

    output = Image.new("RGBA", rgba.size)
    output.putdata(result)
    assert output.size == rgba.size
    assert output.getbbox() == rgba.getbbox()
    assert output.getchannel("A").tobytes() == rgba.getchannel("A").tobytes()

    destination.parent.mkdir(parents=True, exist_ok=True)
    output.save(destination, format="WEBP", lossless=True, method=6)
    with Image.open(destination) as saved:
        verified = saved.convert("RGBA")
        assert verified.size == rgba.size
        assert verified.getbbox() == rgba.getbbox()
        assert verified.getchannel("A").tobytes() == rgba.getchannel("A").tobytes()
    print(f"Created {destination} — alpha, canvas and bounds unchanged")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--assets",
        type=Path,
        default=Path("assets/avatar_prototype"),
        help="Directory containing approved Blue Brim assets",
    )
    assets = parser.parse_args().assets
    pairs = [
        (
            assets / f"brim_v1_blue_gentle_{accessory}.webp",
            assets / f"brim_v1_{COLOURWAY}_gentle_{accessory}.webp",
        )
        for accessory in ACCESSORIES
    ]
    missing = [str(src) for src, _ in pairs if not src.is_file()]
    if missing:
        raise SystemExit("Missing approved Blue source images: " + ", ".join(missing))
    for source, destination in pairs:
        recolour(source, destination)
    print("Mint/Gentle trial assets generated; production app unchanged.")


if __name__ == "__main__":
    main()
