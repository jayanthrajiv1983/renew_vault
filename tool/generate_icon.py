"""Generate renew_vault_icon.png (1024x1024) for app launcher icons."""

from __future__ import annotations

import math
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    raise SystemExit("Install Pillow: pip install pillow")

OUTPUT = Path(__file__).resolve().parent.parent / "assets" / "images" / "logo" / "renew_vault_icon.png"
SIZE = 1024
CENTER = SIZE // 2


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def draw_logo(draw: ImageDraw.ImageDraw) -> None:
    scale = SIZE / 512

    def s(v: float) -> float:
        return v * scale

    # Background circle gradient approximation
    for r in range(int(s(232)), 0, -1):
        t = r / s(232)
        red = int(lerp(0x1D, 0x25, t))
        green = int(lerp(0x4E, 0x63, t))
        blue = int(lerp(0xD8, 0xEB, t))
        draw.ellipse(
            (CENTER - r, CENTER - r, CENTER + r, CENTER + r),
            fill=(red, green, blue),
        )

    # Refresh ring arc
    bbox = (CENTER - s(200), CENTER - s(200), CENTER + s(200), CENTER + s(200))
    draw.arc(bbox, start=200, end=470, fill=(0xF5, 0x9E, 0x0B), width=int(s(18)))

    # Arrow head
    arrow = [
        (s(120), s(340)),
        (s(96), s(360)),
        (s(130), s(372)),
    ]
    draw.polygon([(CENTER - SIZE / 2 + x, CENTER - SIZE / 2 + y) for x, y in arrow], fill=(0xF5, 0x9E, 0x0B))

    # Shield polygon
    shield = [
        (s(256), s(108)),
        (s(352), s(148)),
        (s(352), s(252)),
        (s(256), s(396)),
        (s(160), s(252)),
        (s(160), s(148)),
    ]
    shield_pts = [(CENTER - SIZE / 2 + x, CENTER - SIZE / 2 + y) for x, y in shield]
    draw.polygon(shield_pts, fill=(0xFF, 0xFF, 0xFF), outline=(0x25, 0x63, 0xEB), width=int(s(6)))

    # Calendar header
    cal_x = CENTER - SIZE / 2 + s(196)
    cal_y = CENTER - SIZE / 2 + s(188)
    draw.rounded_rectangle(
        (cal_x, cal_y, cal_x + s(120), cal_y + s(32)),
        radius=int(s(6)),
        fill=(0x25, 0x63, 0xEB),
    )
    draw.rounded_rectangle(
        (cal_x, cal_y + s(24), cal_x + s(120), cal_y + s(120)),
        radius=int(s(6)),
        fill=(0xFF, 0xFF, 0xFF),
        outline=(0x25, 0x63, 0xEB),
        width=int(s(4)),
    )

    # Binding rings
    for dx in (218, 256, 294):
        rx = CENTER - SIZE / 2 + s(dx)
        ry = CENTER - SIZE / 2 + s(178)
        draw.rounded_rectangle(
            (rx, ry, rx + s(8), ry + s(20)),
            radius=int(s(3)),
            fill=(0x1D, 0x4E, 0xD8),
        )

    # Calendar dots
    dot_positions = [(218, 244), (256, 244), (294, 244), (218, 278), (294, 278)]
    for dx, dy in dot_positions:
        cx = CENTER - SIZE / 2 + s(dx)
        cy = CENTER - SIZE / 2 + s(dy)
        draw.ellipse((cx - s(7), cy - s(7), cx + s(7), cy + s(7)), fill=(0x25, 0x63, 0xEB, 90))
    cx = CENTER - SIZE / 2 + s(256)
    cy = CENTER - SIZE / 2 + s(278)
    draw.ellipse((cx - s(7), cy - s(7), cx + s(7), cy + s(7)), fill=(0x22, 0xC5, 0x5E))

    # Check badge
    bx = CENTER - SIZE / 2 + s(340)
    by = CENTER - SIZE / 2 + s(340)
    r = s(44)
    draw.ellipse((bx - r, by - r, bx + r, by + r), fill=(0x22, 0xC5, 0x5E))
    draw.line(
        [
            (bx - s(22), by),
            (bx - s(6), by + s(16)),
            (bx + s(24), by - s(18)),
        ],
        fill=(0xFF, 0xFF, 0xFF),
        width=int(s(10)),
    )


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_logo(draw)
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUTPUT, "PNG")
    print(f"Wrote {OUTPUT}")


if __name__ == "__main__":
    main()
