#!/usr/bin/env python3
"""Install Zeev's complete nine-image Blue trial without touching Brim.

Usage:
    python3 tools/install_zeev_blue_art.py assets/Natter_Zeev_Blue_Nine_Trial_Pack.zip

Validates all assets before writing. Pillow is a developer-only dependency.
"""
from __future__ import annotations

import io
import os
import sys
import tempfile
import zipfile
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Missing Pillow: python3 -m pip install Pillow")
    raise SystemExit(2)

EXPRESSIONS = ("friendly", "playful", "cheeky")
ACCESSORIES = ("none", "scarf", "satchel")
PREFIX = "assets/avatar_prototype/"
EXPECTED = {
    PREFIX + f"zeev_v1_blue_{face}_{accessory}.webp"
    for face in EXPRESSIONS for accessory in ACCESSORIES
}
REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("Usage: python3 tools/install_zeev_blue_art.py <trial-zip>")
        return 2
    archive = Path(argv[1])
    if not archive.is_file():
        print(f"ZIP not found: {archive}")
        return 2
    pubspec = REPOSITORY_ROOT / "pubspec.yaml"
    if "    - assets/avatar_prototype/" not in pubspec.read_text():
        print("Flutter asset directory is not registered in pubspec.yaml.")
        return 2

    validated: dict[str, bytes] = {}
    try:
        with zipfile.ZipFile(archive) as bundle:
            members = bundle.namelist()
            if len(members) != 9 or set(members) != EXPECTED:
                missing = sorted(EXPECTED - set(members))
                extra = sorted(set(members) - EXPECTED)
                print(f"Expected nine specific Zeev assets. Missing: {missing}; extra: {extra}")
                return 2
            for name in sorted(EXPECTED):
                raw = bundle.read(name)
                if not (raw[:4] == b"RIFF" and raw[8:12] == b"WEBP"):
                    print(f"Invalid WebP container: {name}")
                    return 2
                with Image.open(io.BytesIO(raw)) as decoded:
                    if decoded.format != "WEBP" or decoded.size != (512, 512):
                        print(f"Unexpected image format or dimensions: {name}")
                        return 2
                    rgba = decoded.convert("RGBA")
                    if rgba.getchannel("A").getextrema() != (0, 255):
                        print(f"Expected transparent background: {name}")
                        return 2
                    rgba.load()
                validated[name] = raw
    except (OSError, zipfile.BadZipFile, ValueError) as error:
        print(f"Cannot install artwork ZIP: {error}")
        return 2

    # Stage every file in the same volume, then replace only the nine
    # approved-name Zeev destinations. Never clean or overwrite Brim or ZIPs.
    dest_dir = REPOSITORY_ROOT / PREFIX
    dest_dir.mkdir(parents=True, exist_ok=True)
    staged: list[tuple[Path, Path]] = []
    try:
        for name, raw in validated.items():
            fd, temp = tempfile.mkstemp(prefix=".zeev-", suffix=".webp", dir=dest_dir)
            with os.fdopen(fd, "wb") as output:
                output.write(raw)
            staged.append((Path(temp), REPOSITORY_ROOT / name))
        for temp, dest in staged:
            os.replace(temp, dest)
    finally:
        for temp, _ in staged:
            temp.unlink(missing_ok=True)

    print("Installed nine Zeev Blue artwork candidates; Brim and other files untouched.")
    print("Next: flutter test test/zeev_avatar_lab_test.dart")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
