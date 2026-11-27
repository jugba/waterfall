# Write an incremental's pacing promises as unit tests against the balance data

- Area: design
- Date / source: 2026-11-27, projects/003-rockhound (greybox); tests in `game/tests/unit/test_economy.gd` and `test_rarity.gd`
- Confidence: medium (the tests work and caught tuning; whether the promised pace *feels* right is up to the fun gate)
- Apply when: building any incremental / loot / reveal game where balance lives in a data file.

The first-5-minutes promises ("first upgrade within ~30 s", "a rare reveal within 2–3 min", "never more
than N rolls without a rare") are design requirements, so test them instead of eyeballing:
- Keep game rules in a pure `RefCounted` (no nodes) with a seedable `RandomNumberGenerator`, reading
  weights, costs and pity limits from JSON.
- Simulate a conservative player (seconds per hit/strike/reveal) over 20+ seeds and assert the time to
  the first upgrade; assert the pity gap over thousands of rolls and that a fresh save always gets rare+
  within the pity window; check roll frequencies against weights at ~4σ.
- Then anyone can retune `balance.json` and the build fails if a promise breaks.
