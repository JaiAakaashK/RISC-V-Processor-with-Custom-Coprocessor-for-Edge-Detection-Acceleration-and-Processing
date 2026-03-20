"""
pgm_to_jpg.py
=============
Converts sobel_output.pgm to sobel_output.jpg

Usage:
    python pgm_to_jpg.py                          <- uses hardcoded paths below
    python pgm_to_jpg.py input.pgm output.jpg     <- custom paths
"""

import sys
import os

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run:  pip install Pillow")
    sys.exit(1)


def pgm_to_jpg(input_path, output_path):
    if not os.path.exists(input_path):
        print(f"ERROR: file not found: {input_path}")
        sys.exit(1)

    img = Image.open(input_path)
    print(f"Opened : {input_path}  size={img.size}  mode={img.mode}")

    # Convert to RGB (JPG does not support grayscale palette in all viewers)
    img_rgb = img.convert("RGB")

    img_rgb.save(output_path, "JPEG", quality=95)
    print(f"Saved  : {output_path}")
    print("Done!")


if __name__ == "__main__":
    # ----------------------------------------------------------------
    # Hardcoded paths – just run:  python pgm_to_jpg.py
    # ----------------------------------------------------------------
    INPUT_PGM  = "E:/CEIS/sobel_output_2.pgm"
    OUTPUT_JPG = "E:/CEIS/sobel_output_2.jpg"

    if len(sys.argv) == 3:
        INPUT_PGM  = sys.argv[1]
        OUTPUT_JPG = sys.argv[2]
    elif len(sys.argv) == 2:
        INPUT_PGM  = sys.argv[1]
        base       = os.path.splitext(INPUT_PGM)[0]
        OUTPUT_JPG = base + ".jpg"

    pgm_to_jpg(INPUT_PGM, OUTPUT_JPG)
