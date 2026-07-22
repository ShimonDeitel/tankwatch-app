#!/usr/bin/env python3
"""
Generates a real 1024x1024 Tankwatch AppIcon.png using Pillow.
Charcoal background, rust/amber vertical tank-gauge glyph filling ~70% of the tile.
No emoji, no external assets.
"""
import math
from PIL import Image, ImageDraw

SIZE = 1024
OUT_PATH = "../Tankwatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

# Palette (matches Theme.swift)
CHARCOAL = (25, 27, 29)
CHARCOAL_ELEVATED = (37, 39, 42)
CREAM = (242, 232, 212)
RUST = (200, 93, 45)
RUST_BRIGHT = (230, 115, 56)
AMBER = (221, 162, 62)
BRASS = (179, 152, 81)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def vertical_gradient(draw, box, top_color, bottom_color):
    x0, y0, x1, y1 = box
    height = y1 - y0
    for y in range(int(y0), int(y1)):
        t = (y - y0) / max(height, 1)
        color = lerp(top_color, bottom_color, t)
        draw.line([(x0, y), (x1, y)], fill=color)


def rounded_rect_mask(size, box, radius):
    mask = Image.new("L", size, 0)
    mdraw = ImageDraw.Draw(mask)
    mdraw.rounded_rectangle(box, radius=radius, fill=255)
    return mask


def main():
    img = Image.new("RGB", (SIZE, SIZE), CHARCOAL)
    draw = ImageDraw.Draw(img)

    # Subtle background vignette (radial-ish via concentric squares) for depth.
    vertical_gradient(draw, (0, 0, SIZE, SIZE), CHARCOAL, (18, 20, 22))

    # Tank glyph fills ~70% of tile: 717px tall, canted narrower width.
    glyph_width = int(SIZE * 0.42)
    glyph_height = int(SIZE * 0.70)
    glyph_x0 = (SIZE - glyph_width) // 2
    glyph_y0 = (SIZE - glyph_height) // 2 + 20
    glyph_x1 = glyph_x0 + glyph_width
    glyph_y1 = glyph_y0 + glyph_height
    corner_radius = int(glyph_width * 0.30)

    # Tank shell.
    shell_layer = Image.new("RGB", (SIZE, SIZE), CHARCOAL)
    shell_draw = ImageDraw.Draw(shell_layer)
    shell_draw.rounded_rectangle(
        (glyph_x0, glyph_y0, glyph_x1, glyph_y1),
        radius=corner_radius,
        fill=CHARCOAL_ELEVATED,
        outline=CREAM,
        width=10,
    )
    shell_mask = rounded_rect_mask((SIZE, SIZE), (glyph_x0, glyph_y0, glyph_x1, glyph_y1), corner_radius)
    img.paste(shell_layer, (0, 0), shell_mask)

    # Fill level: ~38% full (reads as "getting low" -> rust/amber), inset from shell.
    inset = 16
    fill_x0 = glyph_x0 + inset
    fill_x1 = glyph_x1 - inset
    fill_y1 = glyph_y1 - inset
    fill_percent = 0.38
    fill_y0 = fill_y1 - (glyph_height - 2 * inset) * fill_percent
    fill_radius = max(corner_radius - inset, 4)

    fill_layer = Image.new("RGB", (SIZE, SIZE), CHARCOAL)
    fill_draw = ImageDraw.Draw(fill_layer)
    fill_draw.rounded_rectangle((fill_x0, fill_y0, fill_x1, fill_y1), radius=fill_radius, fill=RUST_BRIGHT)
    fill_mask = rounded_rect_mask((SIZE, SIZE), (fill_x0, fill_y0, fill_x1, fill_y1), fill_radius)

    # Gradient inside the fill for depth.
    grad_layer = Image.new("RGB", (SIZE, SIZE), CHARCOAL)
    grad_draw = ImageDraw.Draw(grad_layer)
    vertical_gradient(grad_draw, (fill_x0, fill_y0, fill_x1, fill_y1), AMBER, RUST)
    img.paste(grad_layer, (0, 0), fill_mask)

    # Tick marks (two horizontal notches suggesting gauge thresholds).
    tick_draw = ImageDraw.Draw(img)
    for frac in (0.2, 0.6):
        ty = glyph_y1 - inset - (glyph_height - 2 * inset) * frac
        tick_draw.line(
            [(fill_x0 + 6, ty), (fill_x1 - 6, ty)],
            fill=CHARCOAL,
            width=6,
        )

    # Small cap/valve nub on top to read clearly as a tank.
    nub_w = int(glyph_width * 0.28)
    nub_h = int(glyph_width * 0.22)
    nub_x0 = SIZE // 2 - nub_w // 2
    nub_y0 = glyph_y0 - nub_h + 14
    nub_x1 = nub_x0 + nub_w
    nub_y1 = glyph_y0 + 14
    draw.rounded_rectangle((nub_x0, nub_y0, nub_x1, nub_y1), radius=int(nub_w * 0.3), fill=BRASS, outline=CREAM, width=6)

    img.save(OUT_PATH, "PNG")
    print(f"Saved {OUT_PATH} ({SIZE}x{SIZE})")


if __name__ == "__main__":
    main()
