#!/usr/bin/env python3
"""Compose App Store screenshots: branded caption band + scaled UI capture."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MANIFEST = ROOT / "store_screenshots" / "manifest.json"
RAW_DIR = ROOT / "store_screenshots" / "raw"
FRAMED_DIR = ROOT / "store_screenshots" / "framed"


def hex_rgb(value: str) -> tuple[int, int, int]:
    value = value.lstrip("#")
    return tuple(int(value[i : i + 2], 16) for i in (0, 2, 4))  # type: ignore[return-value]


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for path in candidates:
        try:
            if path.endswith(".ttc"):
                return ImageFont.truetype(path, size=size, index=1 if bold else 0)
            return ImageFont.truetype(path, size=size)
        except OSError:
            continue
    return ImageFont.load_default()


def make_background(width: int, height: int, brand: dict) -> Image.Image:
    bg = hex_rgb(brand["background"])
    sage = hex_rgb(brand["sage"])
    accent = hex_rgb(brand["accent"])
    img = Image.new("RGB", (width, height), bg)
    overlay = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Soft radial washes (approximated with ellipses + blur)
    cx, cy = width // 2, int(height * 0.28)
    for r, color, alpha in (
        (int(width * 0.55), sage, 55),
        (int(width * 0.35), accent, 40),
        (int(width * 0.22), sage, 30),
    ):
        box = [cx - r, cy - r, cx + r, cy + r]
        draw.ellipse(box, fill=(*color, alpha))

    # Bottom glow
    bx, by = width // 2, int(height * 0.92)
    r = int(width * 0.45)
    draw.ellipse([bx - r, by - r // 2, bx + r, by + r], fill=(*sage, 35))

    overlay = overlay.filter(ImageFilter.GaussianBlur(radius=max(40, width // 40)))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    return img


def fit_ui(
    ui: Image.Image,
    max_w: int,
    max_h: int,
    radius: int,
) -> Image.Image:
    ui = ui.convert("RGBA")
    scale = min(max_w / ui.width, max_h / ui.height)
    new_size = (max(1, int(ui.width * scale)), max(1, int(ui.height * scale)))
    ui = ui.resize(new_size, Image.Resampling.LANCZOS)

    if radius > 0:
        mask = Image.new("L", ui.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, ui.width - 1, ui.height - 1],
            radius=radius,
            fill=255,
        )
        rounded = Image.new("RGBA", ui.size, (0, 0, 0, 0))
        rounded.paste(ui, mask=mask)
        ui = rounded

    # Soft drop shadow
    shadow = Image.new("RGBA", (ui.width + 40, ui.height + 40), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        [20, 24, 20 + ui.width - 1, 24 + ui.height - 1],
        radius=radius,
        fill=(0, 0, 0, 110),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=18))
    canvas = Image.new("RGBA", shadow.size, (0, 0, 0, 0))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(ui, (20, 16))
    return canvas


def wrap_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont, max_width: int) -> list[str]:
    words = text.split()
    if not words:
        return []
    lines: list[str] = []
    current = words[0]
    for word in words[1:]:
        trial = f"{current} {word}"
        if draw.textlength(trial, font=font) <= max_width:
            current = trial
        else:
            lines.append(current)
            current = word
    lines.append(current)
    return lines


def compose_one(
    raw_path: Path,
    out_path: Path,
    device: dict,
    brand: dict,
    title: str,
    subtitle: str,
) -> None:
    width, height = device["width"], device["height"]
    caption_h = int(height * device["caption_band"])
    margin = int(min(width, height) * device["ui_margin"])

    canvas = make_background(width, height, brand).convert("RGBA")
    draw = ImageDraw.Draw(canvas)

    title_size = max(42, width // 18)
    sub_size = max(28, width // 32)
    title_font = load_font(title_size, bold=True)
    sub_font = load_font(sub_size, bold=False)

    text_max = width - margin * 2
    title_lines = wrap_text(draw, title, title_font, text_max)
    sub_lines = wrap_text(draw, subtitle, sub_font, text_max)

    y = int(caption_h * 0.22)
    text_color = hex_rgb(brand["text"])
    muted = hex_rgb(brand["muted"])
    accent = hex_rgb(brand["accent"])

    # Accent rule
    rule_w = min(120, width // 8)
    draw.rounded_rectangle(
        [margin, y, margin + rule_w, y + 6],
        radius=3,
        fill=(*accent, 255),
    )
    y += 28

    for line in title_lines:
        draw.text((margin, y), line, font=title_font, fill=(*text_color, 255))
        y += int(title_size * 1.15)
    y += 8
    for line in sub_lines:
        draw.text((margin, y), line, font=sub_font, fill=(*muted, 255))
        y += int(sub_size * 1.2)

    # Logo mark top-right
    logo_path = ROOT / brand["logo"]
    if logo_path.exists():
        logo = Image.open(logo_path).convert("RGBA")
        logo_h = max(64, caption_h // 3)
        logo_w = int(logo.width * (logo_h / logo.height))
        logo = logo.resize((logo_w, logo_h), Image.Resampling.LANCZOS)
        canvas.alpha_composite(logo, (width - margin - logo_w, int(caption_h * 0.18)))

    ui = Image.open(raw_path)
    max_ui_w = width - margin * 2
    max_ui_h = height - caption_h - margin
    radius = max(28, width // 40)
    framed_ui = fit_ui(ui, max_ui_w, max_ui_h, radius=radius)

    ux = (width - framed_ui.width) // 2
    uy = caption_h + (height - caption_h - framed_ui.height) // 2
    canvas.alpha_composite(framed_ui, (ux, uy))

    out = canvas.convert("RGB")
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out.save(out_path, format="PNG", optimize=True)
    print(f"wrote {out_path.relative_to(ROOT)} ({out.width}x{out.height})")


def iter_raw(device: str) -> list[Path]:
    folder = RAW_DIR / device
    if not folder.exists():
        return []
    return sorted(
        p
        for p in folder.glob("*.png")
        if not p.name.endswith("-legacy.png")
    )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--device", choices=("iphone", "ipad", "all"), default="all")
    parser.add_argument("--screen", help="Compose a single screen id, e.g. 01-games")
    args = parser.parse_args()

    manifest = json.loads(args.manifest.read_text())
    brand = manifest["brand"]
    screens = {s["id"]: s for s in manifest["screens"]}
    devices = ["iphone", "ipad"] if args.device == "all" else [args.device]

    for device_name in devices:
        device = manifest["devices"][device_name]
        for raw in iter_raw(device_name):
            screen_id = raw.stem
            if args.screen and screen_id != args.screen:
                continue
            meta = screens.get(screen_id)
            if meta is None:
                # Allow filenames like 01-games.png matching id
                print(f"skip {raw}: no manifest entry for id '{screen_id}'")
                continue
            out = FRAMED_DIR / device_name / f"{screen_id}-{device['width']}x{device['height']}.png"
            compose_one(
                raw_path=raw,
                out_path=out,
                device=device,
                brand=brand,
                title=meta["title"],
                subtitle=meta["subtitle"],
            )


if __name__ == "__main__":
    main()
