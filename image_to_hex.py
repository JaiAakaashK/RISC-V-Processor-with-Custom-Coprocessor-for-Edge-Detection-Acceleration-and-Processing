"""
image_to_hex.py
===============
Converts any image file (JPG, PNG, BMP, PGM, etc.) to a hex text file
suitable for Verilog $readmemh into a 12-bit pixel memory.

Usage:
    python image_to_hex.py <input_image> [output_hex]

Examples:
    python image_to_hex.py airplane_00391.jpg
        -> writes airplane_00391_image_hex.txt  (640x480 grayscale, 12-bit hex)

    python image_to_hex.py airplane_00391.jpg my_image.txt

Output format  (one hex value per line, no prefix, 3 digits, 307200 lines):
    000
    0a3
    fff
    ...

This is the ONLY format that Verilog $readmemh accepts reliably.
Any header lines, decimal values, or 0x prefixes will cause $readmemh
to silently load zeros for the rest of the array.

The script also diagnoses an existing hex file if you pass it instead of an image.
"""

import sys
import os

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow not installed. Run:  pip install Pillow")
    sys.exit(1)

# ------------------------------------------------------------------ constants
IMG_W = 640
IMG_H = 480
EXPECTED_PIXELS = IMG_W * IMG_H   # 307200

# ------------------------------------------------------------------ helpers

def diagnose_hex_file(path):
    """Read an existing hex file and report what $readmemh would see."""
    print(f"\n--- Diagnosing {path} ---")
    with open(path, 'r', errors='replace') as f:
        lines = [l.rstrip() for l in f.readlines()]

    print(f"Total lines : {len(lines)}")
    print(f"First 5 lines:")
    for l in lines[:5]:
        print(f"  {repr(l)}")

    # Try to parse as hex
    values = []
    bad_lines = []
    for i, line in enumerate(lines):
        tok = line.strip()
        if not tok or tok.startswith('//'):
            continue
        try:
            v = int(tok, 16)
            values.append(v)
        except ValueError:
            bad_lines.append((i+1, tok))

    print(f"\nParseable hex values : {len(values)}")
    print(f"Unparseable lines    : {len(bad_lines)}")
    if bad_lines:
        print("First bad lines (cause $readmemh to stop or skip):")
        for lineno, tok in bad_lines[:5]:
            print(f"  line {lineno}: {repr(tok)}")

    if values:
        non_zero = sum(1 for v in values if v > 0)
        print(f"Non-zero values      : {non_zero} / {len(values)}")
        print(f"Max value            : {max(values)}  (hex: {max(values):03x})")
        print(f"Min value            : {min(values)}")

    if len(values) != EXPECTED_PIXELS:
        print(f"\nWARNING: got {len(values)} values, expected {EXPECTED_PIXELS} (640x480)")
    else:
        print(f"\nPixel count OK: {len(values)} == {EXPECTED_PIXELS}")

    return len(bad_lines) == 0 and len(values) == EXPECTED_PIXELS


def convert_image(input_path, output_path):
    """Convert an image file to $readmemh-compatible hex."""
    img = Image.open(input_path)
    print(f"Opened: {input_path}  size={img.size}  mode={img.mode}")

    # Convert to grayscale
    if img.mode != 'L':
        img = img.convert('L')
        print("Converted to grayscale (mode L)")

    # Resize to 640x480 if needed
    if img.size != (IMG_W, IMG_H):
        print(f"Resizing from {img.size} to {IMG_W}x{IMG_H}")
        img = img.resize((IMG_W, IMG_H), Image.LANCZOS)

    pixels = list(img.getdata()) if not hasattr(img, 'get_flattened_data') else list(img.get_flattened_data())   # 8-bit values 0-255

    # Store 8-bit values directly in 12-bit memory (no scaling).
    # The Sobel threshold in sobel_compute is 255, which is calibrated for
    # 8-bit input range (0-255). Scaling up to 12-bit (p<<4) makes every
    # gradient exceed 255 → entire output saturates to white.
    pixels_12bit = [p for p in pixels]

    print(f"Pixel range: {min(pixels)}-{max(pixels)}  (stored as-is in 12-bit memory)")

    with open(output_path, 'w') as f:
        for v in pixels_12bit:
            f.write(f"{v:03x}\n")

    print(f"Written: {output_path}  ({len(pixels_12bit)} pixels, 3-digit hex, 12-bit)")
    print("Ready for:  $readmemh(\"" + output_path + '", memory_array);')


# ------------------------------------------------------------------ main

def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(0)

    input_path = sys.argv[1]
    if not os.path.exists(input_path):
        print(f"ERROR: file not found: {input_path}")
        sys.exit(1)

    # If input looks like an existing hex file, diagnose it instead
    ext = os.path.splitext(input_path)[1].lower()
    if ext in ('.txt', '.hex', '.mem'):
        ok = diagnose_hex_file(input_path)
        if not ok:
            print("\nRun this script on the original image to regenerate a clean hex file.")
        sys.exit(0)

    # Otherwise convert image to hex
    if len(sys.argv) >= 3:
        output_path = sys.argv[2]
    else:
        base = os.path.splitext(os.path.basename(input_path))[0]
        output_path = base + "_image_hex.txt"

    convert_image(input_path, output_path)


if __name__ == "__main__":
    # ----------------------------------------------------------------
    # Hardcoded path – just run:  python image_to_hex.py
    # (forward slashes required – backslashes cause escape issues)
    # ----------------------------------------------------------------
    INPUT_IMAGE  = "E:/CEIS/pedestrian.jpg"
    OUTPUT_HEX   = "E:/CEIS/pedestrian_image_hex.txt"

    if len(sys.argv) >= 2:
        # Still allow command-line override if needed
        main()
    else:
        if not os.path.exists(INPUT_IMAGE):
            print(f"ERROR: image not found at {INPUT_IMAGE}")
            print("Check the path or pass the image as a command-line argument.")
            sys.exit(1)
        convert_image(INPUT_IMAGE, OUTPUT_HEX)
