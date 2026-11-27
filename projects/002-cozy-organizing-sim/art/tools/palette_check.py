#!/usr/bin/env python3
"""Colour-vision-deficiency (CVD) check for the Knolling Co. item palette.

For every pair of palette colours, computes CIEDE2000 colour difference (dE00) under
normal vision and under simulated protanopia, deuteranopia and tritanopia (Machado,
Oliveira & Fernandes 2009, severity 1.0, applied in linear RGB), plus the lightness gap
(dL*) which survives even full colour blindness. Also checks each colour against the
cutting mat.

Source of matrices: https://www.inf.ufrgs.br/~oliveira/pubs_files/CVD_Simulation/CVD_Simulation.html
Usage:  python3 palette_check.py [current|proposed] [--csv out.csv]
"""
import csv, itertools, math, sys

PALETTES = {
    # game/scripts/catalog.gd COLOURS as of 2026-11-27 (greybox)
    "current": {
        "red": "e05a4f", "orange": "f0954a", "yellow": "f2cf4a", "green": "72bb66",
        "teal": "4fb3a9", "blue": "5b8fd9", "purple": "9b72cf", "pink": "e98bb5",
        "brown": "a87b55", "black": "3c3f47", "grey": "9aa1ab", "white": "ece8df",
    },
    # art/style-guide.md palette v1: tuned (random search + hand pass) so every pair is
    # dE00 >= 10 under all three simulated dichromacies and >= 15 for normal vision
    "proposed": {
        "red": "d85a48", "orange": "ee8f2e", "yellow": "f6da4c", "green": "86d08f",
        "teal": "11937b", "blue": "3a86ec", "purple": "6b4ac2", "pink": "f8b2df",
        "brown": "7a4019", "black": "2a2c33", "grey": "8a99a9", "white": "fbf8ef",
    },
}
MAT = "2f5d50"  # desk.gd MAT_COLOUR

MACHADO = {
    "protan": [[0.152286, 1.052583, -0.204868], [0.114503, 0.786281, 0.099216], [-0.003882, -0.048116, 1.051998]],
    "deutan": [[0.367322, 0.860646, -0.227968], [0.280085, 0.672501, 0.047413], [-0.011820, 0.042940, 0.968881]],
    "tritan": [[1.255528, -0.076749, -0.178779], [-0.078411, 0.930809, 0.147602], [0.004733, 0.691367, 0.303900]],
}


def hex_rgb(h):
    return [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def to_lin(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def to_srgb(c):
    c = min(1.0, max(0.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def simulate(rgb, kind):
    if kind == "normal":
        return rgb
    lin = [to_lin(c) for c in rgb]
    m = MACHADO[kind]
    return [to_srgb(sum(m[r][k] * lin[k] for k in range(3))) for r in range(3)]


def lab(rgb):
    r, g, b = [to_lin(c) for c in rgb]
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
    f = lambda t: t ** (1 / 3) if t > 216 / 24389 else (24389 / 27 * t + 16) / 116
    fx, fy, fz = f(x), f(y), f(z)
    return 116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)


def de2000(l1, l2):
    L1, a1, b1 = l1
    L2, a2, b2 = l2
    C1, C2 = math.hypot(a1, b1), math.hypot(a2, b2)
    Cm = (C1 + C2) / 2
    G = 0.5 * (1 - math.sqrt(Cm ** 7 / (Cm ** 7 + 25 ** 7)))
    a1p, a2p = a1 * (1 + G), a2 * (1 + G)
    C1p, C2p = math.hypot(a1p, b1), math.hypot(a2p, b2)
    h1p = math.degrees(math.atan2(b1, a1p)) % 360
    h2p = math.degrees(math.atan2(b2, a2p)) % 360
    dLp, dCp = L2 - L1, C2p - C1p
    dh = h2p - h1p
    if C1p * C2p == 0:
        dh = 0
    elif dh > 180:
        dh -= 360
    elif dh < -180:
        dh += 360
    dHp = 2 * math.sqrt(C1p * C2p) * math.sin(math.radians(dh / 2))
    Lm, Cmp = (L1 + L2) / 2, (C1p + C2p) / 2
    if C1p * C2p == 0:
        hm = h1p + h2p
    elif abs(h1p - h2p) <= 180:
        hm = (h1p + h2p) / 2
    else:
        hm = (h1p + h2p + 360) / 2 if h1p + h2p < 360 else (h1p + h2p - 360) / 2
    T = (1 - 0.17 * math.cos(math.radians(hm - 30)) + 0.24 * math.cos(math.radians(2 * hm))
         + 0.32 * math.cos(math.radians(3 * hm + 6)) - 0.20 * math.cos(math.radians(4 * hm - 63)))
    dth = 30 * math.exp(-(((hm - 275) / 25) ** 2))
    Rc = 2 * math.sqrt(Cmp ** 7 / (Cmp ** 7 + 25 ** 7))
    Sl = 1 + 0.015 * (Lm - 50) ** 2 / math.sqrt(20 + (Lm - 50) ** 2)
    Sc, Sh = 1 + 0.045 * Cmp, 1 + 0.015 * Cmp * T
    Rt = -math.sin(math.radians(2 * dth)) * Rc
    return math.sqrt((dLp / Sl) ** 2 + (dCp / Sc) ** 2 + (dHp / Sh) ** 2 + Rt * (dCp / Sc) * (dHp / Sh))


def lab_hex(L, a, b):
    fy = (L + 16) / 116
    fx, fz = fy + a / 500, fy - b / 200
    finv = lambda t: t ** 3 if t ** 3 > 216 / 24389 else (116 * t - 16) / (24389 / 27)
    x, y, z = finv(fx) * 0.95047, finv(fy), finv(fz) * 1.08883
    lin = (3.2406 * x - 1.5372 * y - 0.4986 * z, -0.9689 * x + 1.8758 * y + 0.0415 * z,
           0.0557 * x - 0.2040 * y + 1.0570 * z)
    return "".join("%02x" % round(to_srgb(c) * 255) for c in lin)


def ramp(h):
    """highlight / base / shade / outline for one palette colour (style-guide.md section 3)."""
    L, a, b = lab(hex_rgb(h))
    hi = lab_hex(min(98, L + 10), a * 0.85, b * 0.85)
    sh = lab_hex(max(8, L - 10), a * 1.05, b * 1.05)
    ol = lab_hex(max(8, L - 30), a * 0.8, b * 0.8) if L > 30 else lab_hex(L + 22, a, b)
    return hi, h, sh, ol


VISIONS = ["normal", "protan", "deutan", "tritan"]


def rows(pal):
    out = []
    for (n1, h1), (n2, h2) in itertools.combinations(pal.items(), 2):
        r = {"a": n1, "b": n2}
        for v in VISIONS:
            r[v] = round(de2000(lab(simulate(hex_rgb(h1), v)), lab(simulate(hex_rgb(h2), v))), 1)
        r["dL"] = round(abs(lab(hex_rgb(h1))[0] - lab(hex_rgb(h2))[0]), 1)
        r["worst"] = min(r[v] for v in VISIONS)
        out.append(r)
    return sorted(out, key=lambda r: r["worst"])


def main():
    name = sys.argv[1] if len(sys.argv) > 1 else "proposed"
    pal = PALETTES[name]
    rs = rows(pal)
    print(f"palette={name}  pairs={len(rs)}  (dE00 >= 20 clear at a glance, 10-20 side by side only, <10 confusable)")
    for v in VISIONS:
        worst = min(rs, key=lambda r: r[v])
        n = sum(1 for r in rs if r[v] < 10)
        print(f"  {v:7s} min dE00 {worst[v]:5.1f} ({worst['a']}/{worst['b']})  pairs<10: {n}")
    print("  10 worst pairs (any vision):")
    for r in rs[:10]:
        print("   ", r)
    print("  vs mat #%s (dE00 normal / L*):" % MAT)
    ml = lab(hex_rgb(MAT))
    for n, h in pal.items():
        l = lab(hex_rgb(h))
        print(f"    {n:7s} #{h} L*={l[0]:5.1f} dE={de2000(l, ml):5.1f}")
    if "--ramps" in sys.argv:
        print("  ramps: name highlight base shade outline")
        for n, h in pal.items():
            print("    %-7s #%s #%s #%s #%s" % ((n,) + ramp(h)))
    if "--csv" in sys.argv:
        path = sys.argv[sys.argv.index("--csv") + 1]
        with open(path, "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=["a", "b", *VISIONS, "dL", "worst"])
            w.writeheader()
            w.writerows(rs)


if __name__ == "__main__":
    main()
