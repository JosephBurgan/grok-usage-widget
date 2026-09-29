"""Generate grok_widget.ico — official-style Grok mark over two usage bars.

The mark SVG (`grok_mark.svg`) is the stylized G / singularity logo used for
Grok (same path as published in lobehub/lobe-icons). Prefer rendering it with
PyMuPDF when available; otherwise fall back to the committed `grok_mark.png`.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

BAR_COLOR = (76, 175, 80, 255)  # green (matches widget BAR_LOW)
BG_COLOR  = (0, 0, 0, 0)        # transparent
MARK_FILL = (232, 232, 232, 255)

REPO = Path(__file__).resolve().parent
SVG  = REPO / "grok_mark.svg"
MARK = REPO / "grok_mark.png"
OUT  = REPO / "grok_widget.ico"
SIZES = [256, 128, 64, 48, 32, 16]


def _render_mark_from_svg(size: int) -> Image.Image | None:
    """Rasterize grok_mark.svg to a square RGBA image, or None if unavailable."""
    if not SVG.exists():
        return None
    try:
        import pymupdf
    except ImportError:
        return None

    doc = pymupdf.open(SVG)
    try:
        page = doc.load_page(0)
        # viewBox is 24×24; scale so the longest side ≈ size
        zoom = max(size / max(page.rect.width, 1), size / max(page.rect.height, 1))
        pix = page.get_pixmap(matrix=pymupdf.Matrix(zoom, zoom), alpha=True)
    finally:
        doc.close()

    im = Image.frombytes("RGBA", (pix.width, pix.height), pix.samples)
    return _fit_mark(im, size)


def _load_mark_png(size: int) -> Image.Image:
    if not MARK.exists():
        raise FileNotFoundError(
            f"Missing {MARK.name} and could not render {SVG.name}. "
            "Install pymupdf (`pip install pymupdf`) or restore grok_mark.png."
        )
    return _fit_mark(Image.open(MARK).convert("RGBA"), size)


def _fit_mark(im: Image.Image, size: int) -> Image.Image:
    """Crop to opaque content, then fit into a square transparent canvas."""
    bbox = im.split()[-1].getbbox()
    if bbox:
        im = im.crop(bbox)
    im.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), BG_COLOR)
    canvas.alpha_composite(im, ((size - im.width) // 2, (size - im.height) // 2))
    # Ensure mark is light gray/white for dark taskbar / Start Menu backgrounds.
    return _recolor_opaque(canvas, MARK_FILL)


def _recolor_opaque(im: Image.Image, rgba: tuple[int, int, int, int]) -> Image.Image:
    """Keep alpha; force RGB of opaque pixels to rgba's color."""
    px = im.load()
    r, g, b, _ = rgba
    for y in range(im.height):
        for x in range(im.width):
            _, _, _, a = px[x, y]
            if a:
                px[x, y] = (r, g, b, a)
    return im


def load_mark(size: int) -> Image.Image:
    return _render_mark_from_svg(size) or _load_mark_png(size)


def draw_icon(size: int) -> Image.Image:
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), BG_COLOR)

    # Top ~2/3: Grok mark, centered
    mark_size = int(s * 0.70)
    mark = load_mark(mark_size)
    mark_x = (s - mark.width) // 2
    mark_y = int(s * 0.04)
    img.alpha_composite(mark, (mark_x, mark_y))

    # Bottom: two usage bars (same layout as the Claude widget icon)
    d = ImageDraw.Draw(img)
    bar_h      = max(4 * scale, s // 9)
    gap        = max(2 * scale, s // 16)
    bar_widths = [0.50, 1.00]
    total      = 2 * bar_h + gap
    start_y    = int(s * 0.86 - total / 2)

    for i, frac in enumerate(bar_widths):
        y     = start_y + i * (bar_h + gap)
        right = s * frac
        d.rounded_rectangle([0, y, right, y + bar_h], radius=bar_h // 2,
                            fill=BAR_COLOR)

    return img.resize((size, size), Image.LANCZOS)


def main() -> None:
    # Refresh the committed mark PNG from SVG when a renderer is available.
    rendered = _render_mark_from_svg(960)
    if rendered is not None:
        rendered.save(MARK)
        print(f"Wrote {MARK}")

    images = [draw_icon(s) for s in SIZES]
    images[0].save(
        OUT, format="ICO",
        sizes=[(s, s) for s in SIZES],
        append_images=images[1:],
    )
    images[0].save(OUT.with_suffix(".png"))
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
