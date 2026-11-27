# In a grow-by-eating game, spawn prey relative to the player's size and make meal efficiency decay with size, then tune the curve with a bot pacing report

- Area: design
- Date / source: 2026-11-27, projects/005-hook-and-grow/iterations/001.md (Hookmaw greybox;
  `game/scripts/core/growth.gd`, `game/data/balance.json`, `game/tests/tools/pace_report.gd`, `tests/integration/test_pacing.gd`)
- Confidence: medium (curve and tests verified with a scripted bot over 4 seeds; whether it *feels* right awaits the fun gate)
- Apply when: any game where eating / absorbing / collecting makes the player bigger (agar-likes,
  survivors-likes, Katamari-likes, "eat to grow" mobile mechanics).

- Spawning prey at a fraction of the *current* player size (e.g. 0.35–0.75×, gatekeepers 0.7–1.15×)
  means the game never gets stuck (there's always something edible) and "bigger enemies need bigger
  you" falls out for free. Keep the boss at an absolute size so it stays a goal.
- But with constant efficiency, relative prey + cubic mass (size ∝ mass^(1/3)) is exponential: the bot
  hit the size-36 boss gate in 1–4 minutes instead of ~10. Fix that worked: meal mass × eff ×
  (start_size / size)^0.9. Early meals give quick visible growth spurts, late growth slows down.
- Upgrades that multiply throughput (multi-hook, chain) speed up the late game a lot; tune with them in.
- Trait levels on raw counts (sqrt(n)) maxed out by wave 5 of 9 because the player eats ~800 things;
  `1 + floor(sqrt(n/3))` spread visible body changes over the whole run. Check the counts the bot eats.
- Process: a 40-line SceneTree script that runs the bot over N seeds and prints evolution times,
  waves, sizes per milestone and boss gate times (~1.5 s per 10-minute run) made each retune a 10-second
  loop; ~10 passes got every promise in range. Then the same numbers became `test_pacing.gd`.
- Keep the gate meaningful: assert the boss *arrives* before you can hook it (hookable − arrival > 20 s),
  or players simply out-grow the gate and the boss is a speed bump.
