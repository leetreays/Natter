#!/usr/bin/env python3
"""Install the two Brim feasibility images from the review ZIP.

Run from the Natter repository root:
    python3 tools/install_brim_prototype_art.py brim_prototype_asset_pack.zip

This changes *only the current local checkout*. Review and commit resulting
assets deliberately; it does not touch live Natter profiles or Firebase.
"""
from __future__ import annotations

import sys
import zipfile
from pathlib import Path


ASSETS = (
    "assets/avatar_prototype/brim_v1_violet_gentle_none.webp",
    "assets/avatar_prototype/brim_v1_violet_gentle_scarf.webp",
)
ASSET_DIRECTIVE = "    - assets/avatar_prototype/\n"
ASSET_ANCHOR = "    - assets/journey_seedling.png\n"


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 tools/install_brim_prototype_art.py <zip-file>")
        return 2

    repo_root = Path(__file__).resolve().parents[1]
    archive = Path(sys.argv[1]).expanduser().resolve()
    pubspec = repo_root / "pubspec.yaml"

    if not archive.is_file():
        print(f"Archive not found: {archive}")
        return 2

    content = pubspec.read_text(encoding="utf-8")
    if ASSET_DIRECTIVE not in content and ASSET_ANCHOR not in content:
        print("Unexpected pubspec.yaml: cannot find the expected asset list.")
        return 2

    with zipfile.ZipFile(archive) as z:
        missing = set(ASSETS) - set(z.namelist())
        if missing:
            print("Missing approved candidate image(s):", ", ".join(sorted(missing)))
            return 2

        # Validate bytes before changing any local files.
        selected = {}
        for name in ASSETS:
            data = z.read(name)
            if not (data.startswith(b"RIFF") and data[8:12] == b"WEBP"):
                print(f"Not a valid WebP container: {name}")
                return 2
            selected[name] = data

    for name, data in selected.items():
        destination = repo_root / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(data)
        print(f"Installed {name}")

    if ASSET_DIRECTIVE not in content:
        pubspec.write_text(
            content.replace(ASSET_ANCHOR, ASSET_ANCHOR + ASSET_DIRECTIVE, 1),
            encoding="utf-8",
        )
        print("Registered the avatar_prototype asset directory in pubspec.yaml")

    print("Next: flutter pub get; then run the isolated Brim lab.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
