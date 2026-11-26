# Default engine is Godot 4 with GDScript; pick something else only with a written reason

- Area: tech
- Date / source: 2026-11-26, projects/_research/engine-evaluation.md
- Confidence: high (user confirmed 2026-11-26)
- Apply when: starting any new game project or tempted to switch engine.

Godot (MIT, no fees) is the only mainstream engine verified to import, test and export
fully headless in our Linux container, and all its scene/resource files are text Claude can
edit. Market proof: Godot Steam releases 375 (2023) -> 819 (2024) -> 1,229 (2025), Slay the
Spire 2 peaked at 430k CCU in March 2026
(https://www.gamesradar.com/games/roguelike/steam-stats-for-slay-the-spire-2s-engine-godot-show-strong-signs-of-exponential-growth/).
Use GDScript, not C#: C# needs the .NET SDK (blocked here) and Godot 4 C# still cannot export
to web (https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).
Unity Personal cannot be licensed in headless CI; Unreal is binary assets + huge installs.
Runner-up for pure-2D code-only games: LÖVE (Balatro).
