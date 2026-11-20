"""Developer-only checks for the proposed Brim accent art pipeline.

Run after installing Pillow:
    python3 -m unittest discover -s tools -p 'test_refine_brim_accents.py'
"""
import unittest

from PIL import Image

from refine_brim_accents import add_accents


class RefinedAccentTests(unittest.TestCase):
    def setUp(self):
        self.guide = Image.new("RGBA", (4, 2), (0, 0, 0, 0))
        self.base = Image.new("RGBA", (4, 2), (0, 0, 0, 0))
        # Cool accent, purple body, warm cream and semi-transparent accent.
        colours = [
            ((60, 170, 235, 255), (25, 97, 183, 255)),
            ((145, 65, 175, 255), (25, 97, 183, 255)),
            ((230, 195, 150, 255), (230, 195, 150, 255)),
            ((60, 170, 235, 130), (25, 97, 183, 130)),
        ]
        for x, (reference, target) in enumerate(colours):
            self.guide.putpixel((x, 0), reference)
            self.base.putpixel((x, 0), target)

    def test_preserves_geometry_and_alpha(self):
        for colour in ("blue", "mint"):
            with self.subTest(colour=colour):
                result = add_accents(self.guide, self.base, colour)
                self.assertEqual(result.size, self.base.size)
                self.assertEqual(
                    result.getchannel("A").tobytes(),
                    self.base.getchannel("A").tobytes(),
                )
                self.assertEqual(result.getbbox(), self.base.getbbox())

    def test_cool_accents_change_but_warm_materials_do_not(self):
        for colour in ("blue", "mint"):
            with self.subTest(colour=colour):
                result = add_accents(self.guide, self.base, colour)
                self.assertNotEqual(result.getpixel((0, 0)), self.base.getpixel((0, 0)))
                self.assertEqual(result.getpixel((2, 0)), self.base.getpixel((2, 0)))

    def test_source_alignment_is_required(self):
        offset = self.guide.copy()
        offset.putpixel((0, 0), (0, 0, 0, 0))
        with self.assertRaises(ValueError):
            add_accents(offset, self.base, "mint")

    def test_bad_palette_is_rejected(self):
        with self.assertRaises(ValueError):
            add_accents(self.guide, self.base, "violet")


if __name__ == "__main__":
    unittest.main()
