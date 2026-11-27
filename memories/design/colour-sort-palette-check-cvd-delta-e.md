# When colour is a scoring axis, test the palette under simulated colour blindness, and spread lightness

- Area: design
- Date / source: 2026-11-27, projects/002-cozy-organizing-sim/art/tools/palette_check.py → art/palette-cvd-check.csv
- Confidence: high for the measurement; medium that ΔE00 ≥ 10 is enough in play (not playtested)
- Apply when: a game asks players to sort, match or group by colour (organizing, puzzles, cards).

The greybox 12-colour palette looked fine but under simulated deuteranopia (Machado 2009) teal vs
grey was ΔE00 0.4 and 8 pairs were < 10; protan red/brown 4.4. Constrained random search (hue ±15°
of the named hue) plus a hand pass gave a palette with every pair ≥ 10 under protan/deutan/tritan
and ≥ 15 normally, mainly by spreading lightness (L* 18–98: dark brown, purple; light pink, green).
12 keys can't all be "obvious at a glance" (≥ 20) for dichromats, so also: let the scorer accept
type-grouping as an equal alternative, and offer a colour-glyph accessibility toggle. Run the
script on any new palette before it ships.
