"""Regression tests for safe Brim review-asset ZIP installation."""
from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile
from pathlib import Path


INSTALLER = Path(__file__).resolve().with_name("install_brim_prototype_art.py")
MINIMAL_WEBP = b"RIFF\x04\x00\x00\x00WEBP"
ASSET_PREFIX = "assets/avatar_prototype/"
VIOLET_SATCHEL = ASSET_PREFIX + "brim_v1_violet_gentle_satchel.webp"
VIOLET_NONE = ASSET_PREFIX + "brim_v1_violet_gentle_none.webp"
VIOLET_SCARF = ASSET_PREFIX + "brim_v1_violet_gentle_scarf.webp"


class BrimAssetInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.repo = Path(self.temporary.name)
        tools = self.repo / "tools"
        tools.mkdir()
        shutil.copyfile(INSTALLER, tools / INSTALLER.name)
        self.pubspec = self.repo / "pubspec.yaml"
        self.pubspec.write_text(
            "flutter:\n  assets:\n    - assets/journey_seedling.png\n",
            encoding="utf-8",
        )

    def install(self, files):
        archive = self.repo / "trial.zip"
        with zipfile.ZipFile(archive, "w") as bundle:
            for path, data in files.items():
                bundle.writestr(path, data)
        return subprocess.run(
            [sys.executable, str(self.repo / "tools" / INSTALLER.name), str(archive)],
            cwd=self.repo,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_satchel_only_preserves_existing_art_and_registers_directory(self):
        existing = self.repo / VIOLET_NONE
        existing.parent.mkdir(parents=True)
        existing.write_bytes(b"untouched existing artwork")

        response = self.install({VIOLET_SATCHEL: MINIMAL_WEBP})
        self.assertEqual(response.returncode, 0, response.stdout + response.stderr)
        self.assertEqual((self.repo / VIOLET_SATCHEL).read_bytes(), MINIMAL_WEBP)
        self.assertEqual(existing.read_bytes(), b"untouched existing artwork")
        self.assertEqual(
            self.pubspec.read_text().count("    - assets/avatar_prototype/\n"), 1
        )

        response = self.install({VIOLET_SATCHEL: MINIMAL_WEBP})
        self.assertEqual(response.returncode, 0)
        self.assertEqual(
            self.pubspec.read_text().count("    - assets/avatar_prototype/\n"), 1
        )

    def test_incomplete_none_scarf_pair_rejected_without_writes(self):
        original = self.pubspec.read_bytes()
        response = self.install({VIOLET_NONE: MINIMAL_WEBP})
        self.assertEqual(response.returncode, 2)
        self.assertIn("Incomplete", response.stdout)
        self.assertFalse((self.repo / VIOLET_NONE).exists())
        self.assertEqual(self.pubspec.read_bytes(), original)

    def test_invalid_art_prevents_partial_install_even_with_valid_satchel(self):
        original = self.pubspec.read_bytes()
        response = self.install({
            VIOLET_SATCHEL: MINIMAL_WEBP,
            VIOLET_NONE: MINIMAL_WEBP,
            VIOLET_SCARF: b"not a webp",
        })
        self.assertEqual(response.returncode, 2)
        self.assertIn("Not a valid WebP", response.stdout)
        self.assertFalse((self.repo / VIOLET_SATCHEL).exists())
        self.assertFalse((self.repo / VIOLET_NONE).exists())
        self.assertEqual(self.pubspec.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()
