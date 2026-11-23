#!/usr/bin/env python3
"""Create OPTIONAL two-tone Brim review artwork without changing approved assets.

Uses Violet as a colour-region guide, while Blue/Mint geometry, RGB and alpha
come from the existing colourway. This is art-direction experimentation,
not a new renderer, expression builder or production acceptance.

Developer-only requirement: Pillow.
Example from repository root:
    python3 tools/refine_brim_accents.py
"""
from __future__ import annotations

import argparse
import colorsys
from pathlib import Path

from PIL import Image

ACCESSORIES = ("none", "scarf")
# Desired complementary highlights and restrained intensity per colourway.
# Violet already contains blue/cyan accents; it is the unmodified reference.
ACCENTS = {
    "blue": (0.500, 0.90, 13 / 255),  # aqua highlights
    "mint": (103.5 / 180, 0.75, 15 / 255),  # sky-blue highlights
}


def smoothstep(value: float) -> float:
    value = max(0.0, min(1.0, value))
    return value * value * (3.0 - 2.0 * value)


def add_accents(guide: Image.Image, base: Image.Image, colourway: str) -> Image.Image:
    """Reintroduce secondary hues where the Violet source has cooler details.

    This is a soft per-pixel *colour mask*, not a composited accessory overlay.
    The canvas, base pose, mouth, horn, scarf geometry and RGBA alpha are
    unchanged. Reject misaligned source files rather than guess.
    """
    if colourway not in ACCENTS:
        raise ValueError(f"Unknown colourway: {colourway}")
    guide, base = guide.convert("RGBA"), base.convert("RGBA")
    if guide.size != base.size:
        raise ValueError("Violet guide and target artwork dimensions differ")
    if guide.getchannel("A").tobytes() != base.getchannel("A").tobytes():
        raise ValueError("Guide/target alpha masks differ; alignment is unsafe")

    target_hue, strength, saturation_boost = ACCENTS[colourway]
    pixels = []
    for (gr, gg, gb, ga), (r, g, b, alpha) in zip(guide.getdata(), base.getdata()):
        if alpha == 0:
            pixels.append((r, g, b, alpha))
            continue
        guide_hue, guide_sat, _ = colorsys.rgb_to_hsv(gr / 255, gg / 255, gb / 255)
        # Original Violet body is purple, cooler accents tend blue/cyan.
        # Preserve warm cream, horns, claws and uncoloured highlights.
        if not 85 / 180 < guide_hue < 160 / 180:
            pixels.append((r, g, b, alpha))
            continue

        cool = 1 - smoothstep((guide_hue - 112 / 180) / (32 / 180))
        chroma = smoothstep((guide_sat - 30 / 255) / (95 / 255))
        weight = cool * chroma * strength
        if weight < 0.002:
            pixels.append((r, g, b, alpha))
            continue

        hue, saturation, value = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        hue = hue * (1 - weight) + target_hue * weight
        saturation = min(1.0, saturation + saturation_boost * weight)
        rr, green, blue = colorsys.hsv_to_rgb(hue, saturation, value)
        pixels.append((round(rr * 255), round(green * 255), round(blue * 255), alpha))

    result = Image.new("RGBA", base.size)
    result.putdata(pixels)
    assert result.getchannel("A").tobytes() == base.getchannel("A").tobytes()
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--assets",
        type=Path,
        default=Path("assets/avatar_prototype"),
        help="Directory holding the approved Violet, Blue and Mint candidate files",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("artwork_review/accent_candidates"),
        help="Review directory (never overwrites approved sources by default)",
    )
    args = parser.parse_args()
    for accessory in ACCESSORIES:
        violet = args.assets / f"brim_v1_violet_gentle_{accessory}.webp"
        with Image.open(violet) as source:
            guide = source.convert("RGBA")
        for colourway in ACCENTS:
            current = args.assets / f"brim_v1_{colourway}_gentle_{accessory}.webp"
            with Image.open(current) as image:
                base = image.convert("RGBA")
            candidate = add_accents(guide, base, colourway)
            output = args.output / current.name
            output.parent.mkdir(parents=True, exist_ok=True)
            candidate.save(output, "WEBP", lossless=True, method=6)
            with Image.open(output) as check:
                assert check.getchannel("A").tobytes() == base.getchannel("A").tobytes()
            print(f"Review candidate: {output}")
    print("Original avatar assets remain unchanged; do not deploy candidates unreviewed.")


if __name__ == "__main__":
    main()
