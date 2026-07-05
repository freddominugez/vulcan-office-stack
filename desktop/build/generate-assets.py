#!/usr/bin/env python3
# Deterministic asset generator for Vulcan Office Windows installer.
#
# Reads source rasters from vulcanappsadmin.git/vulcanoffice/ASSETS/ and produces:
#   desktop/branding/icons/vulcanoffice.ico   (multi-size Windows icon)
#   desktop/branding/logos/logo_light.svg     (sidebar, light theme)
#   desktop/branding/logos/logo_dark.svg      (sidebar, dark theme)
#   desktop/branding/logos/about-logo.svg     (About dialog)
#   desktop/branding/logos/about-logo-white.svg (About dialog on white bg)
#   desktop/branding/logos/loading.svg        (splash / loading screen)
#
# Deterministic: same source files always produce byte-identical outputs.
#
# Usage (from repo root):
#   python3 -m venv /tmp/vov && /tmp/vov/bin/pip install pillow
#   /tmp/vov/bin/python desktop/build/generate-assets.py \
#       --assets-dir /Users/carlosdominguez/Documents/vulcanappsadmin.git/vulcanoffice/ASSETS

import argparse
import base64
import io
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("pillow not found. Install: pip install pillow", file=sys.stderr)
    sys.exit(1)

REPO = Path(__file__).resolve().parents[2]
ICON_DIR = REPO / "desktop" / "branding" / "icons"
LOGO_DIR = REPO / "desktop" / "branding" / "logos"
ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]


def build_ico(favicon_png: Path, out_ico: Path) -> None:
    src = Image.open(favicon_png).convert("RGBA")
    if max(src.size) < 256:
        raise SystemExit(f"source too small: {src.size}, need >= 256")
    src256 = src.resize((256, 256), Image.Resampling.LANCZOS)
    sizes = [(s, s) for s in ICO_SIZES]
    src256.save(out_ico, format="ICO", sizes=sizes)
    print(f"ico: {out_ico}  ({', '.join(str(s) for s in ICO_SIZES)})")


def png_to_data_uri(png_path: Path, max_side: int = 512) -> tuple[str, int, int]:
    im = Image.open(png_path).convert("RGBA")
    w, h = im.size
    if max(w, h) > max_side:
        scale = max_side / max(w, h)
        im = im.resize((int(w * scale), int(h * scale)), Image.Resampling.LANCZOS)
        w, h = im.size
    buf = io.BytesIO()
    im.save(buf, format="PNG", optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode("ascii")
    return f"data:image/png;base64,{b64}", w, h


def build_svg(name: str, src_png: Path, out_svg: Path, bg: str | None = None) -> None:
    uri, w, h = png_to_data_uri(src_png)
    parts = [
        f'<?xml version="1.0" encoding="UTF-8"?>',
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" '
        f'width="{w}" height="{h}">',
        f'  <title>Vulcan Office - {name}</title>',
    ]
    if bg:
        parts.append(f'  <rect width="{w}" height="{h}" fill="{bg}"/>')
    parts.append(f'  <image href="{uri}" width="{w}" height="{h}"/>')
    parts.append("</svg>")
    out_svg.write_text("\n".join(parts) + "\n", encoding="utf-8")
    print(f"svg: {out_svg}  ({w}x{h}{' bg='+bg if bg else ''})")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--assets-dir", required=True, type=Path)
    args = ap.parse_args()

    favicon = args.assets_dir / "favicon.png"
    logo_source = args.assets_dir / "ativo1.png"
    for f in (favicon, logo_source):
        if not f.is_file():
            print(f"missing source: {f}", file=sys.stderr)
            return 1

    ICON_DIR.mkdir(parents=True, exist_ok=True)
    LOGO_DIR.mkdir(parents=True, exist_ok=True)

    build_ico(favicon, ICON_DIR / "vulcanoffice.ico")
    build_svg("logo_light", logo_source, LOGO_DIR / "logo_light.svg")
    build_svg("logo_dark", logo_source, LOGO_DIR / "logo_dark.svg")
    build_svg("about-logo", logo_source, LOGO_DIR / "about-logo.svg")
    build_svg("about-logo-white", logo_source, LOGO_DIR / "about-logo-white.svg", bg="#ffffff")
    build_svg("loading", logo_source, LOGO_DIR / "loading.svg")

    return 0


if __name__ == "__main__":
    sys.exit(main())
