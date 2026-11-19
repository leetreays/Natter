#!/usr/bin/env python3
"""Build 14 missing Blue/Mint Brim trials from approved Violet assets.

Uses the four existing Blue/Mint Gentle None/Scarf WebPs as colour references.
Runs locally in Codespaces (requires Pillow); never edits approved inputs.
Outputs are candidate artwork, NOT automatically production-approved.
"""
from __future__ import annotations

import argparse
import heapq
import os
import tempfile
from pathlib import Path

from PIL import Image

COLOURS = ("blue", "mint")
EXPRESSIONS = ("gentle", "playful", "cheeky")
ACCESSORIES = ("none", "scarf", "satchel")
SIZE = (512, 512)


def filename(colour: str, expression: str, accessory: str) -> str:
    return f"brim_v1_{colour}_{expression}_{accessory}.webp"


def read(assets: Path, colour: str, expression: str, accessory: str) -> Image.Image:
    path = assets / filename(colour, expression, accessory)
    if not path.is_file():
        raise ValueError(f"Missing required artwork: {path}")
    with Image.open(path) as opened:
        image = opened.convert("RGBA")
    if image.size != SIZE:
        raise ValueError(f"Expected {SIZE} canvas: {path} has {image.size}")
    return image


def same_alpha(a: Image.Image, b: Image.Image, label: str) -> None:
    if a.getchannel("A").tobytes() != b.getchannel("A").tobytes():
        raise ValueError(f"Pixel-alignment check failed (alpha differs): {label}")


class Palette:
    """Learn colour translations from exact corresponding pixels in approved pairs."""

    def __init__(self, pairs: list[tuple[Image.Image, Image.Image]]):
        exact: dict[tuple[int, int, int], list[int]] = {}
        bins: dict[tuple[int, int, int], list[int]] = {}
        for source, target in pairs:
            same_alpha(source, target, "approved source and colour reference")
            for v, t in zip(source.getdata(), target.getdata()):
                if v[3] < 96:
                    continue
                rgb = v[:3]
                item = exact.setdefault(rgb, [0, 0, 0, 0])
                item[0] += t[0]
                item[1] += t[1]
                item[2] += t[2]
                item[3] += 1
                cell = (v[0] >> 4, v[1] >> 4, v[2] >> 4)
                bucket = bins.setdefault(cell, [0, 0, 0, 0])
                for k in range(3):
                    bucket[k] += t[k] - v[k]
                bucket[3] += 1
        if not exact:
            raise ValueError("No usable reference palette samples")
        self.exact = {
            rgb: tuple(round(item[k] / item[3]) for k in range(3))
            for rgb, item in exact.items()
        }
        self.bins = [
            (cell, tuple(item[k] / item[3] for k in range(3)))
            for cell, item in bins.items()
        ]
        self.fallback_cache: dict[tuple[int, int, int], tuple[float, float, float]] = {}
        self.output_cache: dict[tuple[int, int, int], tuple[int, int, int]] = {}

    def translate(self, rgb: tuple[int, int, int]) -> tuple[int, int, int]:
        if rgb in self.output_cache:
            return self.output_cache[rgb]
        r, g, b = rgb
        # Keep satchel leather/gold, cream anatomy, and pink tongue warm.
        if (r > b * 1.18 and r > g * 1.02) or max(rgb) - min(rgb) < 12:
            result = rgb
        elif rgb in self.exact:
            result = self.exact[rgb]
        else:
            cell = (r >> 4, g >> 4, b >> 4)
            change = self.fallback_cache.get(cell)
            if change is None:
                closest = heapq.nsmallest(
                    6, self.bins,
                    key=lambda item: sum(
                        (cell[k] - item[0][k]) ** 2 for k in range(3)
                    ),
                )
                weights = [
                    1 / (1 + sum(
                        (cell[k] - entry[0][k]) ** 2 for k in range(3)
                    ))
                    for entry in closest
                ]
                change = tuple(
                    sum(weights[i] * entry[1][k] for i, entry in enumerate(closest))
                    / sum(weights)
                    for k in range(3)
                )
                self.fallback_cache[cell] = change
            result = tuple(
                max(0, min(255, round(rgb[k] + change[k])))
                for k in range(3)
            )
        self.output_cache[rgb] = result
        return result


def create_variant(
    source: Image.Image,
    violet_base: Image.Image,
    approved_reference: Image.Image,
    palette: Palette,
) -> tuple[Image.Image, int, int]:
    same_alpha(source, violet_base, "Violet variant versus Violet base")
    same_alpha(source, approved_reference, "Violet variant versus approved reference")
    pixels = []
    anchored = transformed = 0
    for current, base, dest in zip(
        source.getdata(), violet_base.getdata(), approved_reference.getdata()
    ):
        if current[3] == 0:
            pixels.append(current)
        elif current == base:
            pixels.append(dest)
            anchored += 1
        else:
            pixels.append((*palette.translate(current[:3]), current[3]))
            transformed += 1
    result = Image.new("RGBA", SIZE)
    result.putdata(pixels)
    same_alpha(result, source, "output versus Violet source")
    return result, anchored, transformed


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--assets", type=Path, default=Path("assets/avatar_prototype")
    )
    args = parser.parse_args()
    assets: Path = args.assets
    try:
        violet = {
            (expression, accessory): read(assets, "violet", expression, accessory)
            for expression in EXPRESSIONS for accessory in ACCESSORIES
        }
        # Approved references remain unchanged, never regenerated.
        references = {
            (colour, accessory): read(assets, colour, "gentle", accessory)
            for colour in COLOURS for accessory in ("none", "scarf")
        }
        targets = [
            (colour, expression, accessory)
            for colour in COLOURS for expression in EXPRESSIONS
            for accessory in ACCESSORIES
            if not (expression == "gentle" and accessory != "satchel")
        ]
        existing = [
            str(assets / filename(*choice))
            for choice in targets if (assets / filename(*choice)).exists()
        ]
        if existing:
            raise ValueError(
                "Refusing to overwrite existing candidate files. Review them first:\n  "
                + "\n  ".join(existing)
            )
        for colour in COLOURS:
            for accessory in ("none", "scarf"):
                same_alpha(
                    violet["gentle", accessory], references[colour, accessory],
                    f"{colour} {accessory}"
                )
        report = []
        with tempfile.TemporaryDirectory() as temp:
            temporary = Path(temp)
            for colour in COLOURS:
                palette = Palette([
                    (violet["gentle", accessory], references[colour, accessory])
                    for accessory in ("none", "scarf")
                ])
                for target_colour, expression, accessory in targets:
                    if colour != target_colour:
                        continue
                    # Satchel has the None geometry; Scarf is independently fitted.
                    anchor = "scarf" if accessory == "scarf" else "none"
                    image, anchored, changed = create_variant(
                        violet[expression, accessory],
                        violet["gentle", anchor],
                        references[colour, anchor], palette
                    )
                    output = temporary / filename(colour, expression, accessory)
                    image.save(output, format="WEBP", lossless=True, method=6)
                    with Image.open(output) as saved:
                        same_alpha(
                            saved.convert("RGBA"), violet[expression, accessory],
                            f"{colour}/{expression}/{accessory} saved WebP"
                        )
                    report.append(
                        f"{output.name}: {anchored} approved-reference pixels; "
                        f"{changed} locally transformed"
                    )
            # Publish outputs only after ALL candidates pass validation.
            assets.mkdir(parents=True, exist_ok=True)
            for colour, expression, accessory in targets:
                name = filename(colour, expression, accessory)
                os.replace(temporary / name, assets / name)
        print("Generated 14 new Blue/Mint Brim trial assets; references untouched.")
        for line in report:
            print("  " + line)
        print("Review ALL 27 combinations in Avatar Lab before approving colourways.")
        return 0
    except (ValueError, OSError) as exc:
        print(f"ARTWORK GENERATION STOPPED: {exc}")
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
