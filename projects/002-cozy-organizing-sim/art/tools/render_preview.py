#!/usr/bin/env python3
"""Renders assets/art/items/*.svg to PNG with headless Chromium (no rsvg/inkscape here).
Writes <id>@2x.png (64 px/cell, the in-game texture) and <id>@4x.png (128 px/cell master)
next to the SVGs, plus _preview-1x.png / _preview-2x.png: every item on the cutting mat at
in-game scale, with the engine's drop shadow imitated, for the readability check.
Usage: python3 render_preview.py [chrome_binary]
"""
import glob, os, re, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
ITEMS = os.path.normpath(os.path.join(HERE, "..", "..", "assets", "art", "items"))
CHROME = sys.argv[1] if len(sys.argv) > 1 else "/opt/pw-browsers/chromium-1243/chrome-linux64/chrome"
MAT, ROOM = "#2f5d50", "#1d1f26"


def shot(html, w, h, out):
    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False) as f:
        f.write(html)
    subprocess.run([CHROME, "--headless", "--no-sandbox", "--disable-gpu", "--hide-scrollbars",
                    "--default-background-color=00000000", f"--window-size={w},{h}",
                    f"--screenshot={out}", "file://" + f.name],
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.unlink(f.name)


def size(svg):
    s = open(svg).read()
    return int(re.search(r'width="(\d+)"', s).group(1)), int(re.search(r'height="(\d+)"', s).group(1))


def main():
    svgs = sorted(p for p in glob.glob(os.path.join(ITEMS, "*.svg")))
    for p in svgs:
        w, h = size(p)
        for scale, tag in ((0.5, "@2x"), (1.0, "@4x")):
            W, H = int(w * scale), int(h * scale)
            html = (f'<html><body style="margin:0;background:transparent">'
                    f'<img src="file://{p}" width="{W}" height="{H}" style="display:block"></body></html>')
            shot(html, W, H, p[:-4] + tag + ".png")
    for px, tag in ((32, "1x"), (64, "2x")):
        cells = []
        for p in svgs:
            w, h = size(p)
            W, H = w * px // 128, h * px // 128
            sx, sy = 3 * px / 32, 4 * px / 32   # desk_item.gd resting shadow offset
            cells.append(f'<img src="file://{p}" width="{W}" height="{H}" style="margin:{px // 2}px;'
                         f'filter:drop-shadow({sx}px {sy}px {px / 16}px rgba(0,0,0,.35))">')
        W = 32 * px
        html = (f'<html><body style="margin:0;background:{ROOM}"><div style="margin:{px // 2}px;'
                f'background:{MAT};width:{W - px}px;display:flex;flex-wrap:wrap;align-items:center;'
                f'background-image:linear-gradient(rgba(255,255,255,.06) 1px,transparent 1px),'
                f'linear-gradient(90deg,rgba(255,255,255,.06) 1px,transparent 1px);'
                f'background-size:{px}px {px}px">{"".join(cells)}</div></body></html>')
        shot(html, W, 9 * px, os.path.join(ITEMS, f"_preview-{tag}.png"))
    print("rendered", len(svgs), "items")


if __name__ == "__main__":
    main()
