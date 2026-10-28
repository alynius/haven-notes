#!/usr/bin/env python3
"""
Stage 2 enhancement: pass scaffold (+ optional style template) to Nano Banana Pro,
get a polished App Store screenshot back.
"""

import argparse
import os
import sys
from pathlib import Path
from google import genai
from google.genai import types
from PIL import Image

MODEL = "models/gemini-3-pro-image-preview"


def load_image(path):
    return Image.open(path).convert("RGBA")


def enhance(scaffold_path, prompt, output_path, style_template=None, approved_design=None):
    client = genai.Client()
    parts = [prompt, load_image(scaffold_path)]
    if style_template:
        parts.append(load_image(style_template))
    if approved_design:
        parts.append(load_image(approved_design))

    resp = client.models.generate_content(
        model=MODEL,
        contents=parts,
        config=types.GenerateContentConfig(
            response_modalities=["IMAGE"],
            image_config=types.ImageConfig(aspect_ratio="16:9", image_size="4K"),
        ),
    )

    for candidate in resp.candidates:
        for part in candidate.content.parts:
            if part.inline_data and part.inline_data.data:
                Path(output_path).parent.mkdir(parents=True, exist_ok=True)
                with open(output_path, "wb") as f:
                    f.write(part.inline_data.data)
                print(f"✓ {output_path}")
                return
    print(f"✗ {output_path} — no image returned", file=sys.stderr)
    print(resp, file=sys.stderr)
    sys.exit(1)


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--scaffold", required=True)
    p.add_argument("--prompt", required=True)
    p.add_argument("--output", required=True)
    p.add_argument("--style-template")
    p.add_argument("--approved-design")
    args = p.parse_args()
    enhance(args.scaffold, args.prompt, args.output, args.style_template, args.approved_design)


if __name__ == "__main__":
    main()
