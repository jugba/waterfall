# Godot exports a universal, ad-hoc-signed macOS .app from Linux; it needs ETC2/ASTC on and players must allow it once

- Area: tech
- Date / source: 2026-11-27, projects/002-cozy-organizing-sim playtest builds (Godot 4.7.1, `tools/godot/build.sh`)
- Confidence: high (export + binary inspection); medium for the Gatekeeper steps (not yet tried on a real Mac)
- Apply when: shipping playtest/demo builds to Mac users, or adding macOS to a Steam release without an Apple Developer ID.

- Template: `templates/macos.zip` (123 MB) from the full `.tpz`; it holds one universal binary
  (`godot_macos_release.universal`, ~170 MB). `install-godot.sh` now extracts it.
- Preset: `platform="macOS"`, `binary_format/architecture="universal"`, export path `*.zip`
  (Godot writes the `.app` inside a zip from Linux; `.dmg` needs macOS). Needs a valid
  `application/bundle_identifier`.
- **Blocker hit:** universal/arm64 export refuses to run unless the project sets
  `rendering/textures/vram_compression/import_etc2_astc=true` (and the preset `texture_format/etc2_astc=true`).
  Now set in `_template/game/project.godot`.
- Signing: `codesign/codesign=1` (Godot's built-in signer) ad-hoc signs both slices on Linux — no
  rcodesign or Xcode needed. Verified both arm64 and x86_64 slices carry `LC_CODE_SIGNATURE` and
  `_CodeSignature/CodeResources` exists. Ad-hoc matters: Apple Silicon will not run unsigned arm64 code.
  `notarization/notarization=0` — notarizing needs a $99/yr Developer ID + rcodesign/notarytool.
- The bundle is named after `config/name` ("Knolling Co. (prototype).app"); there is no preset option
  to change it. `build.sh` renames the zip's top folder to `<GAME_NAME>.app` (folder name is not sealed).
- Size: 60 MB zip for a greybox (vs 28 MB Linux / 38 MB Windows zipped) — universal doubles the binary.
- Players: Gatekeeper blocks first launch. macOS ≤14: right-click → Open. macOS 15+: System Settings →
  Privacy & Security → Open Anyway. Fallback: `xattr -dr com.apple.quarantine KnollingCo.app`.
  Fine for playtesters; for a paid Steam Mac depot, budget the Developer ID + notarization first.
