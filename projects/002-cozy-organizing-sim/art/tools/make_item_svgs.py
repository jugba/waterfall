#!/usr/bin/env python3
"""Writes the hand-coded style-target item sprites (SVG, 128 px per grid cell = 4x master)
to assets/art/items/. Colours come from palette_check.py palette "proposed" via ramp(),
so the sprites always follow art/style-guide.md. Not AI-generated.

Usage: python3 make_item_svgs.py [out_dir]
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import palette_check as pc

CELL = 128          # px per grid cell in the master (4x of the in-game 32 px)
OL = 6              # outline width (1.5 px at 1x)
IL = 4              # interior line width (1 px at 1x)
R = {k: dict(zip(("hi", "base", "sh", "ol"), ("#" + c for c in pc.ramp(h))))
     for k, h in pc.PALETTES["proposed"].items()}
# Neutral materials: low chroma so they never compete with the item's colour key.
STEEL = dict(hi="#eef1f4", base="#c9d0d8", sh="#a2abb6", ol="#5f6873")
WOOD = dict(hi="#f7e3c0", base="#ecca95", sh="#d3ac72", ol="#946d3d")
GRAPHITE = "#3b3e45"
PAPER = R["white"]


def cyl(gid, r, horizontal=True):
    """Gradient for a cylinder seen from straight above: light along the axis, darker at both
    sides. Symmetric, so it stays correct at any quarter turn (no baked light direction)."""
    x2, y2 = ("0", "1") if horizontal else ("1", "0")
    return (f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
            f'<stop offset="0" stop-color="{r["sh"]}"/><stop offset=".32" stop-color="{r["base"]}"/>'
            f'<stop offset=".5" stop-color="{r["hi"]}"/><stop offset=".68" stop-color="{r["base"]}"/>'
            f'<stop offset="1" stop-color="{r["sh"]}"/></linearGradient>')


def dome(gid, r):
    return (f'<radialGradient id="{gid}" cx=".5" cy=".5" r=".55">'
            f'<stop offset="0" stop-color="{r["hi"]}"/><stop offset=".55" stop-color="{r["base"]}"/>'
            f'<stop offset="1" stop-color="{r["sh"]}"/></radialGradient>')


def rr(x, y, w, h, rx, fill, stroke, sw=OL, extra=""):
    return (f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" '
            f'stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" {extra}/>')


def bevel(x, y, w, h, rx, r):
    """Flat top face with a soft inner rim in the shade colour: reads as a rounded edge
    from above, again with no light direction."""
    return (rr(x, y, w, h, rx, r["base"], r["ol"]) +
            rr(x + 7, y + 7, w - 14, h - 14, max(2, rx - 7), "none", r["sh"], 8, 'opacity=".55"') +
            rr(x, y, w, h, rx, "none", r["ol"]))


def svg(w_cells, h_cells, defs, body, item_id):
    W, H = w_cells * CELL, h_cells * CELL
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">\n'
            f'<!-- Knolling Co. item "{item_id}", {w_cells}x{h_cells} cells, 128 px/cell master. '
            f'Hand-coded by make_item_svgs.py (not AI). No baked drop shadow: the engine draws it. -->\n'
            f'<defs>{defs}</defs>\n{body}\n</svg>\n')


ITEMS = {}


def item(item_id, w, h):
    def deco(fn):
        ITEMS[item_id] = (w, h, fn)
        return fn
    return deco


@item("pencil_yellow", 4, 1)
def pencil():
    y, p = R["yellow"], R["pink"]
    defs = cyl("ferrule", STEEL) + cyl("rubber", p)
    body = [
        rr(14, 34, 46, 60, 14, "url(#rubber)", p["ol"]),
        rr(54, 32, 44, 64, 4, "url(#ferrule)", STEEL["ol"]),
        f'<path d="M66 34V94M78 34V94" stroke="{STEEL["sh"]}" stroke-width="{IL}"/>',
        # wood cone, scalloped where the paint ends, then graphite
        f'<path d="M396 32 Q406 48 398 64 Q406 80 396 96 L470 71 L470 57 Z" fill="{WOOD["base"]}" '
        f'stroke="{WOOD["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        f'<path d="M470 57 L496 64 L470 71 Z" fill="{GRAPHITE}" stroke="{GRAPHITE}" stroke-width="{IL}" stroke-linejoin="round"/>',
        # hexagonal body: three facets, middle one lit (symmetric)
        f'<rect x="98" y="32" width="300" height="64" fill="{y["base"]}"/>',
        f'<rect x="98" y="53" width="300" height="22" fill="{y["hi"]}"/>',
        f'<path d="M98 32H398M98 96H398" stroke="{y["ol"]}" stroke-width="{OL}"/>',
        f'<path d="M98 53H398M98 75H398" stroke="{y["sh"]}" stroke-width="{IL}"/>',
        f'<path d="M98 32V96" stroke="{STEEL["ol"]}" stroke-width="{OL}"/>',
    ]
    return defs, body


@item("pen_blue", 4, 1)
def pen():
    b = R["blue"]
    defs = cyl("barrel", b) + cyl("cap", {**b, "base": b["sh"], "hi": b["base"]}) + cyl("clip", STEEL)
    body = [
        rr(18, 40, 30, 48, 12, b["sh"], b["ol"]),                       # end plug
        rr(36, 38, 300, 52, 26, "url(#barrel)", b["ol"]),               # barrel
        f'<path d="M150 42V86M164 42V86" stroke="{b["sh"]}" stroke-width="{IL}" opacity=".7"/>',
        rr(300, 32, 186, 64, 30, "url(#cap)", b["ol"]),                 # cap (covers the tip)
        rr(318, 56, 132, 16, 8, "url(#clip)", STEEL["ol"], IL),         # clip lies on top
        f'<circle cx="452" cy="64" r="9" fill="{STEEL["base"]}" stroke="{STEEL["ol"]}" stroke-width="{IL}"/>',
    ]
    return defs, body


@item("highlighter_pink", 3, 1)
def highlighter():
    p = R["pink"]
    defs = cyl("hbody", p) + cyl("hcap", {**p, "base": p["sh"], "hi": p["base"]})
    body = [
        rr(14, 26, 290, 76, 24, "url(#hbody)", p["ol"]),
        rr(70, 46, 150, 36, 8, PAPER["base"], PAPER["ol"], IL),           # label
        rr(84, 56, 74, 16, 6, p["base"], p["ol"], IL),                     # ink swatch
        f'<path d="M170 64H206" stroke="{PAPER["ol"]}" stroke-width="{IL}" stroke-linecap="round"/>',
        rr(270, 20, 100, 88, 26, "url(#hcap)", p["ol"]),
        f'<path d="M296 24V104M312 24V104" stroke="{p["ol"]}" stroke-width="{IL}" opacity=".45"/>',
    ]
    return defs, body


@item("eraser", 2, 1)
def eraser():
    p = R["pink"]
    body = [
        bevel(14, 22, 228, 84, 22, p),
        rr(148, 18, 76, 92, 6, PAPER["base"], PAPER["ol"]),                # paper sleeve
        f'<path d="M164 46H206M164 64H200M164 82H190" stroke="{PAPER["ol"]}" stroke-width="{IL}" stroke-linecap="round"/>',
    ]
    return "", body


@item("scissors", 4, 2)
def scissors():
    r = R["red"]
    defs = cyl("blade_top", STEEL, True)
    body = [
        # blades (closed): one leaf, lower half in shade
        f'<path d="M176 102 Q340 104 496 128 Q340 152 176 154 Z" fill="{STEEL["base"]}" '
        f'stroke="{STEEL["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        f'<path d="M176 128 Q340 130 496 128 Q340 152 176 154 Z" fill="{STEEL["sh"]}"/>',
        f'<path d="M180 128 H492" stroke="{STEEL["ol"]}" stroke-width="{IL}"/>',
        f'<path d="M176 102 Q340 104 496 128 Q340 152 176 154" fill="none" stroke="{STEEL["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        # shanks from loops to the pivot
        f'<path d="M150 92 L222 120 M150 164 L222 136" stroke="{r["ol"]}" stroke-width="{30 + OL}" stroke-linecap="round"/>',
        f'<path d="M150 92 L222 120 M150 164 L222 136" stroke="{r["base"]}" stroke-width="30" stroke-linecap="round"/>',
        # finger loops: red rings
        f'<ellipse cx="96" cy="74" rx="66" ry="50" fill="{r["ol"]}"/>',
        f'<ellipse cx="96" cy="74" rx="60" ry="44" fill="{r["base"]}"/>',
        f'<ellipse cx="96" cy="74" rx="46" ry="30" fill="none" stroke="{r["hi"]}" stroke-width="6" opacity=".7"/>',
        f'<ellipse cx="96" cy="74" rx="36" ry="22" fill="{r["ol"]}"/>',
        f'<ellipse cx="100" cy="182" rx="74" ry="56" fill="{r["ol"]}"/>',
        f'<ellipse cx="100" cy="182" rx="68" ry="50" fill="{r["base"]}"/>',
        f'<ellipse cx="100" cy="182" rx="53" ry="35" fill="none" stroke="{r["hi"]}" stroke-width="6" opacity=".7"/>',
        f'<ellipse cx="100" cy="182" rx="42" ry="26" fill="{r["ol"]}"/>',
        f'<circle cx="222" cy="128" r="13" fill="{STEEL["hi"]}" stroke="{STEEL["ol"]}" stroke-width="{IL}"/>',
    ]
    return defs, body


@item("stapler", 3, 2)
def stapler():
    k = R["black"]
    defs = cyl("sbody", k)
    body = [
        rr(40, 70, 334, 116, 34, STEEL["base"], STEEL["ol"]),            # base plate, shows at the front
        f'<circle cx="352" cy="128" r="10" fill="{STEEL["sh"]}" stroke="{STEEL["ol"]}" stroke-width="{IL}"/>',
        f'<path d="M64 48 H262 Q330 56 330 128 Q330 200 262 208 H64 Q18 208 18 128 Q18 48 64 48 Z" '
        f'fill="url(#sbody)" stroke="{k["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        rr(70, 112, 170, 32, 16, k["hi"], k["ol"], IL, 'opacity=".9"'),   # top ridge
        f'<path d="M236 92 H286 Q318 96 318 128 Q318 160 286 164 H236 Z" fill="{STEEL["base"]}" '
        f'stroke="{STEEL["ol"]}" stroke-width="{IL}" stroke-linejoin="round"/>',          # metal head
        f'<path d="M256 104 V152 M272 104 V152" stroke="{STEEL["sh"]}" stroke-width="{IL}"/>',
        f'<circle cx="54" cy="128" r="9" fill="{k["sh"]}" stroke="{k["ol"]}" stroke-width="{IL}"/>',
    ]
    return defs, body


@item("sticky_notes", 2, 2)
def sticky():
    y = R["yellow"]
    body = [
        rr(22, 22, 212, 212, 8, y["sh"], y["ol"]),                         # the pad (stack edges)
        f'<path d="M34 34 H222 V178 L178 222 H34 Z" fill="{y["base"]}" stroke="{y["sh"]}" stroke-width="{IL}" stroke-linejoin="round"/>',
        f'<path d="M222 178 L178 222 L184 184 Z" fill="{y["hi"]}" stroke="{y["ol"]}" stroke-width="{IL}" stroke-linejoin="round"/>',
        f'<path d="M60 80 H180 M60 112 H160 M60 144 H128" stroke="{y["ol"]}" stroke-width="{IL + 2}" stroke-linecap="round" opacity=".45"/>',
        rr(22, 22, 212, 212, 8, "none", y["ol"]),
    ]
    return "", body


@item("notebook", 4, 3)
def notebook():
    b, k = R["blue"], R["black"]
    body = [
        rr(440, 28, 56, 328, 8, PAPER["base"], PAPER["ol"]),               # page block edge
        f'<path d="M476 40V344M486 40V344" stroke="{PAPER["sh"]}" stroke-width="{IL}"/>',
        bevel(16, 16, 464, 352, 18, b),                                    # cover
        f'<rect x="16" y="16" width="56" height="352" rx="18" fill="{b["sh"]}"/>',   # cloth spine
        f'<path d="M72 18V366" stroke="{b["ol"]}" stroke-width="{IL}"/>',
        rr(16, 16, 464, 352, 18, "none", b["ol"]),
        rr(150, 70, 190, 78, 10, PAPER["base"], PAPER["ol"], IL),           # label
        f'<path d="M172 98H318M172 122H280" stroke="{PAPER["ol"]}" stroke-width="{IL}" stroke-linecap="round"/>',
        rr(398, 10, 20, 364, 6, k["base"], k["ol"], IL),                    # elastic band
    ]
    return "", body


@item("phone", 4, 2)
def phone():
    k = R["black"]
    body = [
        rr(14, 14, 484, 228, 46, k["base"], k["ol"]),
        rr(22, 22, 468, 212, 40, "none", k["hi"], IL, 'opacity=".8"'),     # rim catch-light, all round
        rr(46, 34, 420, 188, 26, "#14171d", "#0c0e12", IL),                # screen
        f'<path d="M150 34 L230 34 L130 222 L50 222 Z" fill="#ffffff" opacity=".07"/>',
        f'<circle cx="32" cy="128" r="7" fill="#0c0e12" stroke="{k["hi"]}" stroke-width="2"/>',
        rr(478, 108, 10, 40, 5, k["sh"], k["ol"], 2),
    ]
    return "", body


@item("keys", 2, 2)
def keys():
    g = R["grey"]
    body = [
        f'<circle cx="74" cy="74" r="46" fill="none" stroke="{STEEL["ol"]}" stroke-width="{14 + OL}"/>',
        f'<circle cx="74" cy="74" r="46" fill="none" stroke="{STEEL["hi"]}" stroke-width="14"/>',
        # key 1, diagonal
        '<g transform="rotate(45 128 128)">'
        f'<path d="M150 116 H236 V132 H226 V146 H214 V132 H204 V146 H192 V140 H150 Z" fill="{g["base"]}" '
        f'stroke="{g["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>'
        f'<circle cx="122" cy="128" r="36" fill="{g["base"]}" stroke="{g["ol"]}" stroke-width="{OL}"/>'
        f'<circle cx="122" cy="128" r="26" fill="none" stroke="{g["hi"]}" stroke-width="6" opacity=".8"/>'
        f'<circle cx="106" cy="128" r="9" fill="{g["ol"]}"/>'
        '</g>',
        # key 2, horizontal, overlaps the ring
        f'<path d="M140 52 H238 V68 H228 V80 H218 V68 H208 V80 H198 V72 H140 Z" fill="{g["sh"]}" '
        f'stroke="{g["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        rr(98, 36, 54, 52, 16, g["sh"], g["ol"]),
        f'<circle cx="112" cy="62" r="8" fill="{g["ol"]}"/>',
    ]
    return "", body


@item("apple", 2, 2)
def apple():
    gr, br = R["green"], R["brown"]
    defs = dome("appleg", gr)
    body = [
        f'<path d="M128 40 C 176 22 236 50 232 124 C 228 196 176 232 128 222 C 80 232 28 196 24 124 '
        f'C 20 50 80 22 128 40 Z" fill="url(#appleg)" stroke="{gr["ol"]}" stroke-width="{OL}" stroke-linejoin="round"/>',
        f'<ellipse cx="128" cy="118" rx="22" ry="18" fill="{gr["sh"]}" opacity=".8"/>',
        f'<path d="M128 118 Q138 100 156 92 Q190 70 206 84 Q190 112 156 106 Z" fill="{gr["sh"]}" '
        f'stroke="{gr["ol"]}" stroke-width="{IL}" stroke-linejoin="round"/>',
        f'<path d="M128 118 Q124 104 118 96" stroke="{br["base"]}" stroke-width="9" stroke-linecap="round"/>',
    ]
    return defs, body


@item("compass", 2, 2)
def compass():
    r = R["red"]
    body = [
        f'<circle cx="128" cy="128" r="104" fill="{r["base"]}" stroke="{r["ol"]}" stroke-width="{OL}"/>',
        f'<circle cx="128" cy="128" r="94" fill="none" stroke="{r["hi"]}" stroke-width="6" opacity=".6"/>',
        f'<circle cx="128" cy="128" r="76" fill="{PAPER["base"]}" stroke="{r["ol"]}" stroke-width="{IL}"/>',
        *[f'<path d="M128 56 V{70 if i % 2 == 0 else 64}" stroke="{PAPER["ol"]}" stroke-width="{IL}" '
          f'stroke-linecap="round" transform="rotate({i * 45} 128 128)"/>' for i in range(8)],
        f'<path d="M128 66 L142 128 L114 128 Z" fill="{r["base"]}" stroke="{r["ol"]}" stroke-width="{IL}" stroke-linejoin="round"/>',
        f'<path d="M128 190 L142 128 L114 128 Z" fill="{STEEL["base"]}" stroke="{STEEL["ol"]}" stroke-width="{IL}" stroke-linejoin="round"/>',
        f'<circle cx="128" cy="128" r="8" fill="{STEEL["hi"]}" stroke="{STEEL["ol"]}" stroke-width="{IL}"/>',
        rr(112, 14, 32, 20, 8, r["sh"], r["ol"], IL),                       # lanyard lug
    ]
    return "", body


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "art", "items")
    os.makedirs(out, exist_ok=True)
    for item_id, (w, h, fn) in ITEMS.items():
        defs, body = fn()
        with open(os.path.join(out, f"{item_id}.svg"), "w") as f:
            f.write(svg(w, h, defs, "\n".join(body), item_id))
        print("wrote", item_id, f"{w}x{h}")


if __name__ == "__main__":
    main()
