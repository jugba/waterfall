# Score "grouping" from each item's row/column neighbours at its smallest gap, best of type-vs-colour

- Area: design
- Date / source: 2026-11-26, projects/002-cozy-organizing-sim/game/scripts/neatness.gd + tests/unit/test_neatness.gd
- Confidence: medium (tuned on synthetic layouts; not yet playtested)
- Apply when: writing a freeform tidiness / arrangement scorer (organizing, packing, decorating games).

First version used k-nearest neighbours by centre distance: tidy row layouts scored only
0.35/1 on grouping (items in the row above are "nearer" than row mates 5 cells along).
What works: neighbours = nearest aligned item left/right/up/down within 4 cells, keeping only
those at the item's smallest gap (a wider gap is how people separate groups), then score
"by type" and "by colour" separately and take the better (so a type-singleton is not punished
for its colour), rescaled so chance = 0. Result: two different tidy layouts (rows by type,
vertical columns by colour) 89-97, random scatter <=24, snapped-but-random in between.
Test a scorer against several different tidy layouts, not one, before trusting it.
