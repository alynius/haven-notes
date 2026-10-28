#!/usr/bin/env python3
"""
Haven iOS App Store screenshot composer — 1290x2796 cream canvas.

Takes the existing dark marketing screenshots (1284x2778) as input, crops
out their built-in headline strip, then places them on a cream canvas with
a fresh espresso headline above. Brand-aligned with the shipped macOS set.
"""

import argparse
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CANVAS_W = 1290
CANVAS_H = 2796
BG = "#F4ECE0"
TEXT = "#3A2418"

FONT_PATH = "/System/Library/Fonts/Avenir.ttc"
FONT_INDEX = 2  # Avenir Black

TOP_PAD = 140
VERB_SIZE_MAX = 240
VERB_SIZE_MIN = 160
DESC_SIZE_MAX = 110
DESC_SIZE_MIN = 80
VERB_DESC_GAP = 30
HEADLINE_PHONE_GAP = 70
MAX_TEXT_W = int(CANVAS_W * 0.85)

# Source crop: existing screenshots have a built-in headline + bottom margin.
# Strip them so we keep only the phone shape.
SRC_CROP_TOP = 295
SRC_CROP_BOTTOM = 80

PHONE_MAX_W = 1140
PHONE_BOTTOM_PAD = 100
SHADOW_BLUR = 80
SHADOW_OFFSET_Y = 30
SHADOW_ALPHA = 90


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def load_font(size):
    return ImageFont.truetype(FONT_PATH, size, index=FONT_INDEX)


def fit_text_size(draw, text, max_w, size_max, size_min):
    for size in range(size_max, size_min - 1, -4):
        font = load_font(size)
        bbox = draw.textbbox((0, 0), text, font=font)
        if (bbox[2] - bbox[0]) <= max_w:
            return font
    return load_font(size_min)


def draw_centered(draw, text, y, font, fill):
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    x = (CANVAS_W - w) // 2 - bbox[0]
    draw.text((x, y), text, font=font, fill=fill)
    return y + bbox[3]


def add_shadow(canvas, phone, x, y):
    shadow_canvas = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", phone.size, (0, 0, 0, SHADOW_ALPHA))
    if phone.mode == "RGBA":
        shadow_layer.putalpha(phone.split()[-1])
    shadow_canvas.paste(shadow_layer, (x, y + SHADOW_OFFSET_Y), shadow_layer)
    shadow_canvas = shadow_canvas.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    canvas.alpha_composite(shadow_canvas)


def compose(verb, desc, screenshot_path, output_path):
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), hex_to_rgb(BG) + (255,))
    draw = ImageDraw.Draw(canvas)
    text_color = hex_to_rgb(TEXT) + (255,)

    verb_u = verb.upper()
    desc_u = desc.upper()

    verb_font = fit_text_size(draw, verb_u, MAX_TEXT_W, VERB_SIZE_MAX, VERB_SIZE_MIN)
    desc_font = fit_text_size(draw, desc_u, MAX_TEXT_W, DESC_SIZE_MAX, DESC_SIZE_MIN)

    verb_bottom = draw_centered(draw, verb_u, TOP_PAD, verb_font, text_color)
    desc_y = verb_bottom + VERB_DESC_GAP
    headline_bottom = draw_centered(draw, desc_u, desc_y, desc_font, text_color)

    src = Image.open(screenshot_path).convert("RGBA")
    cropped = src.crop((0, SRC_CROP_TOP, src.width, src.height - SRC_CROP_BOTTOM))

    phone_top = headline_bottom + HEADLINE_PHONE_GAP
    available_h = CANVAS_H - phone_top - PHONE_BOTTOM_PAD

    scale = min(PHONE_MAX_W / cropped.width, available_h / cropped.height)
    new_w = int(cropped.width * scale)
    new_h = int(cropped.height * scale)
    phone = cropped.resize((new_w, new_h), Image.LANCZOS)

    px = (CANVAS_W - new_w) // 2
    py = phone_top + (available_h - new_h) // 2

    add_shadow(canvas, phone, px, py)
    canvas.alpha_composite(phone, (px, py))

    canvas.convert("RGB").save(output_path, "PNG", optimize=True)
    print(f"✓ {output_path}  [{CANVAS_W}x{CANVAS_H}]")


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--verb", required=True)
    p.add_argument("--desc", required=True)
    p.add_argument("--screenshot", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    compose(args.verb, args.desc, args.screenshot, args.output)


if __name__ == "__main__":
    main()
