# Steam AI disclosure covers only player-facing content; AI-written code needs none, AI art/audio does

- Area: tech
- Date / source: 2026-11-26; Valve rules rewritten Jan 2026 (https://www.pcgamer.com/software/ai/steam-updates-ai-disclosure-form-to-specify-that-its-focused-on-ai-generated-content-that-is-consumed-by-players-not-efficiency-tools-used-behind-the-scenes/); USCO Part 2 (https://copyright.gov/newsnet/2025/1060.html)
- Confidence: medium
- Apply when: choosing how to produce art/audio/text, or filling the Steam content survey.

Pre-generated AI content must be disclosed and follows normal content rules; live-generated
content additionally needs described guardrails, and players can report it via overlay.
Dev-efficiency tools (Claude writing code) are exempt. Purely prompted output is likely not
copyrightable in the US, so key art/capsules/characters should be human-made or heavily
human-edited. Keep `assets/LICENSES.md` per project (source, licence, AI yes/no) and fill the
disclosure from it.
