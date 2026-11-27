# Sprites the player rotates must have no baked light direction; the engine draws the shadow

- Area: design
- Date / source: 2026-11-27, projects/002-cozy-organizing-sim/art/style-guide.md §3; game/scripts/desk_item.gd (screen-fixed drop shadow)
- Confidence: medium (reasoned from the engine setup and the SVG targets; not yet playtested)
- Apply when: drawing or prompting art for top-down items, tiles or pieces that rotate in 90° steps.

A top-left highlight baked into a sprite is wrong as soon as the item turns 180°, while the drop
shadow stays screen-fixed (down-right). Shade by form only, symmetric about the object's axis:
cylinders lit along the centre and darker at both sides, boxes as a flat top with a soft inner rim,
round things with a central radial highlight. Bake no cast shadow; draw one soft shadow in code from
the sprite's own silhouette (resting offset ~(3,4) px, lifted (12,18) px). Put "no cast shadow, no
light direction" in the fixed AI prompt and in the cleanup checklist, because image models add both.
