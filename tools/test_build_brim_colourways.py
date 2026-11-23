"""Small, dependency-light tests for Brim reference-palette transfer.

Run from repository root: python3 tools/test_build_brim_colourways.py
"""
from __future__ import annotations

import unittest

from PIL import Image

import build_brim_colourways as brim


class BrimColourwayBuilderTests(unittest.TestCase):
    def setUp(self):
        self.old_size = brim.SIZE
        brim.SIZE = (2, 2)
        self.addCleanup(lambda: setattr(brim, "SIZE", self.old_size))

    @staticmethod
    def picture(colors):
        image = Image.new("RGBA", (2, 2))
        image.putdata(colors)
        return image

    def test_exact_reference_colours_and_warm_accessory_are_preserved(self):
        violet = self.picture([
            (100, 40, 180, 255),
            (220, 140, 65, 255),
            (100, 40, 180, 255),
            (0, 0, 0, 0),
        ])
        blue = self.picture([
            (45, 110, 215, 255),
            (220, 140, 65, 255),
            (45, 110, 215, 255),
            (0, 0, 0, 0),
        ])
        palette = brim.Palette([(violet, blue)])
        self.assertEqual(palette.translate((100, 40, 180)), (45, 110, 215))
        self.assertEqual(palette.translate((220, 140, 65)), (220, 140, 65))

    def test_unchanged_pixels_anchor_to_approved_reference(self):
        violet = self.picture([(100, 40, 180, 255)] * 4)
        blue = self.picture([(45, 110, 215, 255)] * 4)
        variant = self.picture([
            (100, 40, 180, 255),
            (105, 50, 184, 255),
            (100, 40, 180, 255),
            (100, 40, 180, 255),
        ])
        palette = brim.Palette([(violet, blue)])
        result, locked, changed = brim.create_variant(
            variant, violet, blue, palette
        )
        self.assertEqual(locked, 3)
        self.assertEqual(changed, 1)
        self.assertEqual(result.getpixel((0, 0)), blue.getpixel((0, 0)))
        self.assertEqual(result.getpixel((0, 1)), blue.getpixel((0, 1)))
        brim.same_alpha(result, variant, "test output alpha")

    def test_alpha_mismatch_stops_unsafe_transfer(self):
        violet = self.picture([(100, 40, 180, 255)] * 4)
        bad = self.picture([(100, 40, 180, 255)] * 3 + [(0, 0, 0, 0)])
        with self.assertRaisesRegex(ValueError, "alpha differs"):
            brim.same_alpha(violet, bad, "deliberately mismatched")


if __name__ == "__main__":
    unittest.main()
