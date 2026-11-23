"""Developer-only QA for the pixel-locked Mint colourway conversion.

Run with Pillow installed:
    python3 -m unittest discover -s tools -p 'test_recolour_brim_palette.py'
"""
import tempfile
import unittest
from pathlib import Path

from PIL import Image

from recolour_brim_palette import recolour, remap_pixel


class BrimMintPaletteTests(unittest.TestCase):
    def test_preserves_warm_materials(self):
        self.assertEqual(remap_pixel(225, 193, 160), (225, 193, 160))
        self.assertEqual(remap_pixel(250, 247, 242), (250, 247, 242))

    def test_changes_clearly_blue_materials(self):
        original = (40, 105, 190)
        changed = remap_pixel(*original)
        self.assertNotEqual(changed, original)
        self.assertGreater(changed[1], changed[0])
        self.assertGreater(changed[1], changed[2])

    def test_canvas_alpha_bounds_and_warm_pixels_are_unchanged(self):
        with tempfile.TemporaryDirectory() as directory:
            source = Path(directory) / "blue.webp"
            destination = Path(directory) / "mint.webp"
            im = Image.new("RGBA", (8, 8), (0, 0, 0, 0))
            im.putpixel((1, 1), (40, 105, 190, 255))  # Blue body
            im.putpixel((2, 1), (225, 193, 160, 255))  # Cream belly
            im.putpixel((3, 1), (30, 105, 200, 140))  # Soft blue edge
            im.save(source, "WEBP", lossless=True)

            recolour(source, destination)

            with Image.open(source) as input_im, Image.open(destination) as output_im:
                a, b = input_im.convert("RGBA"), output_im.convert("RGBA")
                self.assertEqual(a.size, b.size)
                self.assertEqual(a.getbbox(), b.getbbox())
                self.assertEqual(a.getchannel("A").tobytes(), b.getchannel("A").tobytes())
                self.assertEqual(a.getpixel((2, 1)), b.getpixel((2, 1)))
                self.assertNotEqual(a.getpixel((1, 1)), b.getpixel((1, 1)))


if __name__ == "__main__":
    unittest.main()
