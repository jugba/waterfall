# Beatrunner — fun-check greybox (v0.1.0)

Two questions: **does the movement feel great on its own**, and **does running to the music make you
want to play again?** Greybox only: simple shapes, synthesised sounds and a procedurally generated
original track (125 BPM, ~71 s). No art yet.

## 1. Get the build

Zips in `playtest/builds/` (git-ignored; shared out of band):

| Platform | File | Run |
|---|---|---|
| macOS (Apple Silicon + Intel) | `Beatrunner-0.1.0-macos-universal.zip` | unzip → `Beatrunner.app` |
| Windows 10/11 | `Beatrunner-0.1.0-windows-x86_64.zip` | unzip → `Beatrunner.exe` (SmartScreen: More info → Run anyway) |
| Linux / Steam Deck desktop | `Beatrunner-0.1.0-linux-x86_64.zip` | unzip → `./Beatrunner.x86_64` |

**Opening on a Mac.** The app is ad-hoc signed but not notarized (we have no Apple Developer ID), so
the first launch is blocked with **"Beatrunner can't be opened because Apple cannot check it for
malicious software"** (on macOS 15+: **"Apple could not verify 'Beatrunner' is free of malware…"**).
That is expected. Do this once:
1. Unzip, drag `Beatrunner.app` to Applications. Double-click it, then click **Done** (not Move to Trash).
2. macOS 15 or later: open **System Settings → Privacy & Security**, scroll down to
   "Beatrunner was blocked to protect your Mac", click **Open Anyway**, enter your password,
   then click **Open Anyway** again in the dialog.
   macOS 14 or earlier: **Control-click the app → Open → Open**.
3. If it still refuses or says the app is "damaged", run this in Terminal and open it again:
   `xattr -dr com.apple.quarantine /Applications/Beatrunner.app`

(Source: `memories/tech/macos-gatekeeper-unnotarized-builds-need-open-anyway`.)

Use headphones or speakers: the music level is about the sound.

## 2. Controls

| | Keyboard | Controller / Steam Deck |
|---|---|---|
| Move | A / D or ← → | left stick or d-pad |
| Jump (tap = hop, hold = high) | Space, K or Z | A |
| Glide | hold Jump while falling | hold A |
| Fast-fall | hold S or ↓ in the air | stick / d-pad down |
| Punch | J or X | X |
| Dash (once in the air too) | Shift, L or C | B or RT |
| Wall slide / wall jump | hold toward a wall / Jump | same |
| Wall run | sprint (+jump) into a wall and keep holding toward it | same |
| Sandbox: next section | T | Back / View |
| Pause, settings, rebinding | Esc or P | Start |

All bindings can be changed in Settings → Controls (keyboard and controller separately).

## 3. How to play the test (about 10 minutes)

1. **Movement Sandbox first (5 min).** Run the course left to right: signs teach each move in turn
   (jump, coyote gap, wall-jump chimney, wall-run cliff, dash gap, punch crates, glide canyon,
   bounce pad + fast-fall). Then just mess around. Notice when you replay something only because
   it feels good, and when anything feels floaty, slippery, sticky or unfair.
2. **Music Level (5 min).** Pip runs by himself. Jump on the kicks, punch the drums on the claps,
   bounce pads launch you on the downbeat, hold Jump to glide over the big canyon in the quiet
   part. Dying sends you back to the last flag with a 3-2-1 count-in. Play it at least twice.

## 4. Five questions (answer right after playing)

1. **Movement feel:** did running and jumping feel tight and responsive? Which move felt best, and
   which one felt off (floaty, too slow, too fast, sticky walls, dash too short/long)?
2. **Sandbox without goals:** did you ever replay a section or just run around because it was fun?
   Where did you stop, and why?
3. **On the beat:** in the Music Level, could you *feel* your jumps and punches landing on the music?
   Did "PERFECT!" moments feel earned, and did deaths feel fair or like the timing was off?
4. **One more run:** after finishing (or failing) the Music Level, did you want to go again for a
   cleaner run? What would make you want to more (harder track, scores, more variety)?
5. **Gut call:** with real art and a real soundtrack, would you play 2–3 hours of this? What one
   change would make it more fun?
