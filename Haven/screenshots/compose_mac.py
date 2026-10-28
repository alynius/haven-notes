#!/usr/bin/env python3
"""
Haven Mac App Store screenshot composer — 2880x1800 cream canvas.
Scaffold = headline + windowed app screenshot with drop shadow.
Stage 1 of the scaffold-then-enhance pattern.
"""

import argparse
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

CANVAS_W = 2880
CANVAS_H = 1800
BG = "#F4ECE0"
TEXT = "#3A2418"

FONT_PATH = "/System/Library/Fonts/Avenir.ttc"
FONT_INDEX = 2  # Avenir Black

TOP_PAD = 110
VERB_SIZE_MAX = 320
VERB_SIZE_MIN = 200
DESC_SIZE_MAX = 130
DESC_SIZE_MIN = 90
VERB_DESC_GAP = 60
HEADLINE_WINDOW_GAP = 90
MAX_TEXT_W = int(CANVAS_W * 0.78)

WINDOW_MAX_W = 2200
WINDOW_BOTTOM_PAD = 90
SHADOW_BLUR = 70
SHADOW_OFFSET_Y = 30
SHADOW_ALPHA = 70


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
            return font, size
    return load_font(size_min), size_min


def draw_centered_text(draw, text, y, font, fill):
    """Draw text centered horizontally at vertical position y.
    Returns the y-coordinate of the bottom of the rendered ink, so callers
    can place the next line below without overlap.
    """
    bbox = draw.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    x = (CANVAS_W - w) // 2 - bbox[0]
    draw.text((x, y), text, font=font, fill=fill)
    return y + bbox[3]


def add_shadow(canvas, window_img, x, y):
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_layer = Image.new("RGBA", window_img.size, (0, 0, 0, SHADOW_ALPHA))
    if window_img.mode == "RGBA":
        alpha = window_img.split()[-1]
        shadow_layer.putalpha(alpha)
    shadow.paste(shadow_layer, (x, y + SHADOW_OFFSET_Y), shadow_layer)
    shadow = shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR))
    canvas.alpha_composite(shadow)


def compose(verb, desc, screenshot_path, output_path):
    canvas = Image.new("RGBA", (CANVAS_W, CANVAS_H), hex_to_rgb(BG) + (255,))
    draw = ImageDraw.Draw(canvas)
    text_color = hex_to_rgb(TEXT) + (255,)

    verb_u = verb.upper()
    desc_u = desc.upper()

    verb_font, _ = fit_text_size(draw, verb_u, MAX_TEXT_W, VERB_SIZE_MAX, VERB_SIZE_MIN)
    desc_font, _ = fit_text_size(draw, desc_u, MAX_TEXT_W, DESC_SIZE_MAX, DESC_SIZE_MIN)

    verb_bottom = draw_centered_text(draw, verb_u, TOP_PAD, verb_font, text_color)
    desc_y = verb_bottom + VERB_DESC_GAP
    headline_bottom = draw_centered_text(draw, desc_u, desc_y, desc_font, text_color)

    window = Image.open(screenshot_path).convert("RGBA")
    window_top = headline_bottom + HEADLINE_WINDOW_GAP
    available_h = CANVAS_H - window_top - WINDOW_BOTTOM_PAD

    scale = min(WINDOW_MAX_W / window.width, available_h / window.height)
    new_w = int(window.width * scale)
    new_h = int(window.height * scale)
    window = window.resize((new_w, new_h), Image.LANCZOS)

    wx = (CANVAS_W - new_w) // 2
    wy = window_top + (available_h - new_h) // 2

    add_shadow(canvas, window, wx, wy)
    canvas.alpha_composite(window, (wx, wy))

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
