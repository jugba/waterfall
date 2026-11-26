# Upload to Steam with game-ci/steam-deploy in GitHub Actions, to a beta branch, human sets live

- Area: tech
- Date / source: 2026-11-26, https://github.com/game-ci/steam-deploy (README + action.yml)
- Confidence: medium (not yet run against our own app)
- Apply when: wiring CI for any Steam release.

Auth is either base64 `config.vdf` from a one-time local `steamcmd` login (secret
`STEAM_CONFIG_VDF`; refresh with `+set_steam_guard_code` when it expires) or a TOTP from the
Steam Guard shared secret (if `totp` is set, `configVdf` is ignored). Use a dedicated build
account, keep credentials only in GitHub secrets, upload Linux + Windows depots to a beta branch,
gate deploy on manual approval. Valve tests the native Linux build on Deck first, Proton only
if it fails (https://www.gamingonlinux.com/2022/02/valve-clarifies-how-they-test-native-linux-or-proton-for-steam-deck),
so test both on a Deck.
