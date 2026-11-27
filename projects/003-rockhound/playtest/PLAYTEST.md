# Rockhound — fun-gate greybox (v0.1.0)

The one question: **are the first 5 minutes fun?** Is there tension while you dig and crack, and does
the reveal make you want "one more rock"? Greybox only: shapes, glow and synthesised sounds, no art.

## 1. Get the build

Zips in `playtest/builds/` (git-ignored; shared out of band):

| Platform | File | Run |
|---|---|---|
| macOS (Apple Silicon + Intel) | `Rockhound-0.1.0-macos-universal.zip` | unzip → `Rockhound.app` |
| Windows 10/11 | `Rockhound-0.1.0-windows-x86_64.zip` | unzip → `Rockhound.exe` (SmartScreen: More info → Run anyway) |
| Linux / Steam Deck desktop | `Rockhound-0.1.0-linux-x86_64.zip` | unzip → `./Rockhound.x86_64` |

**Opening on a Mac.** The app is ad-hoc signed but not notarized (we have no Apple Developer ID), so
the first launch is blocked with **"Rockhound can't be opened because Apple cannot check it for
malicious software"** (or "Apple could not verify…"). That is expected. Do this once:
1. Unzip, drag `Rockhound.app` to Applications. Double-click it, then click **Done**.
2. macOS 15 or later: **System Settings → Privacy & Security**, scroll down to
   "Rockhound.app was blocked…", click **Open Anyway**, enter your password, then **Open**.
   macOS 14 or earlier: **Control-click the app → Open → Open**.
3. If it still refuses or says "damaged", run this in Terminal and open it again:
   `xattr -dr com.apple.quarantine /Applications/Rockhound.app`

(Source: `memories/tech/macos-gatekeeper-unnotarized-builds-need-open-anyway`.)

## 2. Controls

| | Mouse | Keyboard | Controller |
|---|---|---|---|
| Dig (rock face, left) | hold left button on the rock | hold Space | hold A |
| Crack (geode on the anvil) | hold on the geode | hold Space | hold A |
| Sell the crystal | click it | Space | A |
| Polish (after buying Polish Wheel) | hold on the crystal, release in the green zone | hold Space | hold A |
| Switch rock ↔ anvil ↔ shop | point at it | ← → | d-pad / left stick ← → |
| Buy an upgrade | click it | → into the shop, ↑ ↓, Enter | → into the shop, ↑ ↓, A |
| Collection book | "Book" button | Tab or B | Y |
| Pause / settings | — | Esc or P | Start |

The title screen has **Continue** and **New game**. Progress saves on its own every 10 s and on quit.

## 3. How to play the test

Play for at least 5 minutes without reading anything else, then stop at a natural point. If you want to
keep going, keep going, and note when and why you stopped. Things to look for: the first upgrade
should come within about 30 s, a rare (blue) or better crystal within about 2 minutes, and there should
always be a "Next:" goal at the top.

## 4. Five questions (answer right after playing)

1. **Did you want to crack "one more"?** When did you stop, and why (bored, done, confused, time)?
2. **The reveal:** which reveal do you remember best, and did the build-up (cracks, light, rising ticks,
   slow motion) make you lean in, or did you want to skip it?
3. **Digging:** did chipping the rock feel good on its own, or was it a chore between cracks?
4. **Goals:** did you always know what you were saving for? Was any upgrade exciting? Which one was dull?
5. **Gut call:** would you play this for an hour if it had real art and sound? What one change would
   make it more fun?
