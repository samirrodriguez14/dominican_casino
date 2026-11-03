#!/usr/bin/env python3
"""Generate App Store Header and Search Results creatives (3840x2560)."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "store_screenshots" / "creative"
LOGO = ROOT / "assets" / "images" / "logo_cards_transparent.png"
ICON = ROOT / "assets" / "images" / "logo_icon_barajando.png"

BG = (0x1A, 0x22, 0x20)
SURFACE = (0x25, 0x2E, 0x2B)
ACCENT = (0xC4, 0xB0, 0x7A)
SAGE = (0x6F, 0x9E, 0x86)
TEXT = (0xF4, 0xF2, 0xEC)
MUTED = (0xB0, 0xBA, 0xB4)

W, H = 3840, 2560


def load_font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        try:
            if path.endswith(".ttc"):
                return ImageFont.truetype(path, size=size, index=1 if bold else 0)
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def felt_background() -> Image.Image:
    img = Image.new("RGB", (W, H), BG)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Felt table ellipse
    draw.ellipse(
        [int(W * 0.08), int(H * 0.18), int(W * 0.92), int(H * 0.95)],
        fill=(*SAGE, 70),
    )
    draw.ellipse(
        [int(W * 0.18), int(H * 0.28), int(W * 0.82), int(H * 0.88)],
        fill=(0x3A, 0x63, 0x4F, 90),
    )
    # Gold wash top
    draw.ellipse(
        [int(W * 0.25), -int(H * 0.2), int(W * 0.75), int(H * 0.45)],
        fill=(*ACCENT, 45),
    )
    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=80))
    return Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGBA")


def paste_logo(canvas: Image.Image, size: int, xy: tuple[int, int]) -> None:
    src = LOGO if LOGO.exists() else ICON
    logo = Image.open(src).convert("RGBA")
    logo = logo.resize((size, int(logo.height * size / logo.width)), Image.Resampling.LANCZOS)
    canvas.alpha_composite(logo, xy)


def write_search() -> Path:
    """High-contrast search thumbnail — brand + short line."""
    canvas = felt_background()
    draw = ImageDraw.Draw(canvas)

    # Left brand cluster
    paste_logo(canvas, 720, (280, 780))

    title_font = load_font(220, bold=True)
    sub_font = load_font(84, bold=False)
    draw.text((1100, 900), "Barajando", font=title_font, fill=(*TEXT, 255))
    draw.text((1100, 1180), "Dominican card games", font=sub_font, fill=(*MUTED, 255))

    # Accent bar
    draw.rounded_rectangle([1100, 1320, 1380, 1336], radius=8, fill=(*ACCENT, 255))

    # Small game chips
    chip_font = load_font(48, bold=True)
    chips = ["Sweep", "Tres y Dos", "Rummy"]
    x = 1100
    for chip in chips:
        tw = int(draw.textlength(chip, font=chip_font))
        pad = 36
        draw.rounded_rectangle(
            [x, 1420, x + tw + pad * 2, 1420 + 88],
            radius=44,
            fill=(*SURFACE, 220),
            outline=(*ACCENT, 180),
            width=3,
        )
        draw.text((x + pad, 1438), chip, font=chip_font, fill=(*TEXT, 255))
        x += tw + pad * 2 + 28

    out = OUT_DIR / "search-3840x2560.png"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"wrote {out.relative_to(ROOT)}")
    return out


def write_header() -> Path:
    """Cinematic header — atmosphere first, wordmark secondary."""
    canvas = felt_background()
    draw = ImageDraw.Draw(canvas)

    # Scattered card suggestions via logo scaled large, low opacity backdrop
    if LOGO.exists():
        big = Image.open(LOGO).convert("RGBA")
        big = big.resize((1400, int(big.height * 1400 / big.width)), Image.Resampling.LANCZOS)
        # Tint/dim
        faded = Image.new("RGBA", big.size, (0, 0, 0, 0))
        faded.alpha_composite(big)
        # reduce alpha
        alpha = faded.split()[-1].point(lambda a: int(a * 0.35))
        faded.putalpha(alpha)
        canvas.alpha_composite(faded, (W - 1600, 420))
        canvas.alpha_composite(faded.rotate(12, expand=True, fillcolor=(0, 0, 0, 0)), (W - 1900, 900))

    paste_logo(canvas, 520, (320, 720))

    title_font = load_font(200, bold=True)
    sub_font = load_font(72, bold=False)
    draw.text((920, 820), "Barajando", font=title_font, fill=(*TEXT, 255))
    draw.text(
        (920, 1080),
        "Felt tables. Real Dominican games.",
        font=sub_font,
        fill=(*MUTED, 255),
    )
    draw.rounded_rectangle([920, 1220, 1200, 1236], radius=8, fill=(*ACCENT, 255))

    out = OUT_DIR / "header-3840x2560.png"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out, format="PNG", optimize=True)
    print(f"wrote {out.relative_to(ROOT)}")
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=("search", "header", "all"), default="all")
    args = parser.parse_args()
    if args.only in ("search", "all"):
        write_search()
    if args.only in ("header", "all"):
        write_header()


if __name__ == "__main__":
    main()
