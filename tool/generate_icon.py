"""Generate Renew Vault brand PNG assets from the official vector design."""

from __future__ import annotations

import math
import shutil
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    raise SystemExit("Install Pillow: pip install pillow")

ROOT = Path(__file__).resolve().parent.parent
LOGO_DIR = ROOT / "assets" / "images" / "logo"
ICON_SIZE = 1024
CENTER = ICON_SIZE // 2

APP_NAME = "Renew Vault™"
TAGLINE = "Your life, organized."

LOGO_PNG = LOGO_DIR / "renew_vault_logo.png"
ICON_PNG = LOGO_DIR / "renew_vault_icon.png"
SPLASH_LIGHT = LOGO_DIR / "renew_vault_splash_light.png"
SPLASH_DARK = LOGO_DIR / "renew_vault_splash_dark.png"
SPLASH_BRANDING_LIGHT = LOGO_DIR / "renew_vault_splash_branding_light.png"
SPLASH_BRANDING_DARK = LOGO_DIR / "renew_vault_splash_branding_dark.png"


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def draw_logo_mark(draw: ImageDraw.ImageDraw, size: int, offset_x: float = 0, offset_y: float = 0) -> None:
    """Draw the circular Renew Vault mark at *size* pixels, top-left at offset."""
    scale = size / 512
    center = size / 2

    def s(v: float) -> float:
        return v * scale

    def pt(x: float, y: float) -> tuple[float, float]:
        return (offset_x + center - size / 2 + s(x), offset_y + center - size / 2 + s(y))

    for r in range(int(s(232)), 0, -1):
        t = r / s(232)
        red = int(lerp(0x1D, 0x25, t))
        green = int(lerp(0x4E, 0x63, t))
        blue = int(lerp(0xD8, 0xEB, t))
        cx = offset_x + center
        cy = offset_y + center
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(red, green, blue))

    bbox = (
        offset_x + center - s(200),
        offset_y + center - s(200),
        offset_x + center + s(200),
        offset_y + center + s(200),
    )
    draw.arc(bbox, start=200, end=470, fill=(0xF5, 0x9E, 0x0B), width=max(1, int(s(18))))

    arrow = [pt(120, 340), pt(96, 360), pt(130, 372)]
    draw.polygon(arrow, fill=(0xF5, 0x9E, 0x0B))

    shield = [pt(256, 108), pt(352, 148), pt(352, 252), pt(256, 396), pt(160, 252), pt(160, 148)]
    draw.polygon(shield, fill=(0xFF, 0xFF, 0xFF), outline=(0x25, 0x63, 0xEB), width=max(1, int(s(6))))

    cal_x, cal_y = pt(196, 188)[0], pt(196, 188)[1]
    cal_w, cal_h = s(120), s(32)
    draw.rounded_rectangle(
        (cal_x, cal_y, cal_x + cal_w, cal_y + cal_h),
        radius=max(1, int(s(6))),
        fill=(0x25, 0x63, 0xEB),
    )
    body_y = cal_y + s(24)
    draw.rounded_rectangle(
        (cal_x, body_y, cal_x + cal_w, body_y + s(96)),
        radius=max(1, int(s(6))),
        fill=(0xFF, 0xFF, 0xFF),
        outline=(0x25, 0x63, 0xEB),
        width=max(1, int(s(4))),
    )

    for dx in (218, 256, 294):
        rx, ry = pt(dx, 178)
        draw.rounded_rectangle(
            (rx, ry, rx + s(8), ry + s(20)),
            radius=max(1, int(s(3))),
            fill=(0x1D, 0x4E, 0xD8),
        )

    for dx, dy in [(218, 244), (256, 244), (294, 244), (218, 278), (294, 278)]:
        cx, cy = pt(dx, dy)
        draw.ellipse((cx - s(7), cy - s(7), cx + s(7), cy + s(7)), fill=(0x25, 0x63, 0xEB, 90))
    cx, cy = pt(256, 278)
    draw.ellipse((cx - s(7), cy - s(7), cx + s(7), cy + s(7)), fill=(0x22, 0xC5, 0x5E))

    bx, by = pt(340, 340)
    r = s(44)
    draw.ellipse((bx - r, by - r, bx + r, by + r), fill=(0x22, 0xC5, 0x5E))
    draw.line(
        [(bx - s(22), by), (bx - s(6), by + s(16)), (bx + s(24), by - s(18))],
        fill=(0xFF, 0xFF, 0xFF),
        width=max(1, int(s(10))),
    )


def generate_logo_png() -> None:
    img = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_logo_mark(draw, ICON_SIZE)
    LOGO_DIR.mkdir(parents=True, exist_ok=True)
    img.save(LOGO_PNG, "PNG")
    shutil.copy2(LOGO_PNG, ICON_PNG)
    print(f"Wrote {LOGO_PNG}")
    print(f"Wrote {ICON_PNG}")


def _load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = []
    if bold:
        candidates.extend(
            [
                Path("C:/Windows/Fonts/segoeuib.ttf"),
                Path("C:/Windows/Fonts/arialbd.ttf"),
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"),
                Path("/System/Library/Fonts/Supplemental/Arial Bold.ttf"),
            ]
        )
    else:
        candidates.extend(
            [
                Path("C:/Windows/Fonts/segoeui.ttf"),
                Path("C:/Windows/Fonts/arial.ttf"),
                Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
                Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
            ]
        )
    for path in candidates:
        if path.exists():
            return ImageFont.truetype(str(path), size)
    return ImageFont.load_default()


def _text_width(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> float:
    if hasattr(draw, "textlength"):
        return draw.textlength(text, font=font)
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def generate_splash_composite(output: Path, *, title_color: tuple[int, int, int, int], tagline_color: tuple[int, int, int, int]) -> None:
    logo_size = 280
    padding = 32
    title_font = _load_font(52, bold=True)
    tagline_font = _load_font(28, bold=False)

    probe = Image.new("RGBA", (1, 1))
    probe_draw = ImageDraw.Draw(probe)
    title_h = probe_draw.textbbox((0, 0), APP_NAME, font=title_font)[3]
    tagline_h = probe_draw.textbbox((0, 0), TAGLINE, font=tagline_font)[3]

    width = max(
        logo_size,
        int(_text_width(probe_draw, APP_NAME, title_font)) + padding * 2,
        int(_text_width(probe_draw, TAGLINE, tagline_font)) + padding * 2,
    )
    height = logo_size + padding + title_h + 16 + tagline_h + padding

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    logo_img = Image.new("RGBA", (logo_size, logo_size), (0, 0, 0, 0))
    logo_draw = ImageDraw.Draw(logo_img)
    draw_logo_mark(logo_draw, logo_size)
    img.paste(logo_img, ((width - logo_size) // 2, 0), logo_img)

    y = logo_size + padding
    title_w = _text_width(draw, APP_NAME, title_font)
    draw.text(((width - title_w) / 2, y), APP_NAME, font=title_font, fill=title_color)
    y += title_h + 16
    tagline_w = _text_width(draw, TAGLINE, tagline_font)
    draw.text(((width - tagline_w) / 2, y), TAGLINE, font=tagline_font, fill=tagline_color)

    img.save(output, "PNG")
    print(f"Wrote {output}")


def generate_splash_branding(output: Path, *, title_color: tuple[int, int, int, int], tagline_color: tuple[int, int, int, int]) -> None:
    padding = 32
    title_font = _load_font(44, bold=True)
    tagline_font = _load_font(24, bold=False)

    probe = Image.new("RGBA", (1, 1))
    probe_draw = ImageDraw.Draw(probe)
    title_h = probe_draw.textbbox((0, 0), APP_NAME, font=title_font)[3]
    tagline_h = probe_draw.textbbox((0, 0), TAGLINE, font=tagline_font)[3]

    width = max(
        int(_text_width(probe_draw, APP_NAME, title_font)) + padding * 2,
        int(_text_width(probe_draw, TAGLINE, tagline_font)) + padding * 2,
    )
    height = title_h + 12 + tagline_h + padding

    img = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    title_w = _text_width(draw, APP_NAME, title_font)
    draw.text(((width - title_w) / 2, 0), APP_NAME, font=title_font, fill=title_color)
    y = title_h + 12
    tagline_w = _text_width(draw, TAGLINE, tagline_font)
    draw.text(((width - tagline_w) / 2, y), TAGLINE, font=tagline_font, fill=tagline_color)

    img.save(output, "PNG")
    print(f"Wrote {output}")


def generate_splash_assets() -> None:
    generate_splash_composite(
        SPLASH_LIGHT,
        title_color=(255, 255, 255, 255),
        tagline_color=(255, 255, 255, 210),
    )
    generate_splash_composite(
        SPLASH_DARK,
        title_color=(255, 255, 255, 255),
        tagline_color=(230, 240, 255, 220),
    )
    generate_splash_branding(
        SPLASH_BRANDING_LIGHT,
        title_color=(255, 255, 255, 255),
        tagline_color=(255, 255, 255, 210),
    )
    generate_splash_branding(
        SPLASH_BRANDING_DARK,
        title_color=(255, 255, 255, 255),
        tagline_color=(230, 240, 255, 220),
    )


def main() -> None:
    generate_logo_png()
    generate_splash_assets()


if __name__ == "__main__":
    main()
