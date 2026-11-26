# The Claude container cannot reach Steam (SteamCMD, partner site) or the .NET SDK host; upload from GitHub Actions

- Area: tech
- Date / source: 2026-11-26, proxy probes in projects/_research/engine-evaluation.md §3
- Confidence: high (as of this date; network policy can change)
- Apply when: planning builds, Steam uploads, or choosing a toolchain that downloads an SDK.

Blocked by the agent proxy: `steamcdn-a.akamaihd.net`, `media.steampowered.com` (SteamCMD),
`partner.steamgames.com`, `builds.dotnet.microsoft.com`, `downloads.godotengine.org`; WebFetch
also could not reach `steamdb.info`, `gamefromscratch.com`, `godotsteam.com`. Reachable: github.com
release downloads, npm, crates index, nuget API. So: build/test in the container, deploy to Steam
from GitHub Actions with `game-ci/steam-deploy` (https://github.com/game-ci/steam-deploy), or ask
the user to allowlist hosts. Report blocks; don't work around them.
