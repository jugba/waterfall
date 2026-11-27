# Hookmaw — fun-check greybox (v0.1.0)

Three questions: **does the hook feel great on its own**, **does growing feel good**, and **do you
want another run?** Greybox only: simple shapes, synthesised sounds, no music. One arena, nine
waves, then the Lantern Leviathan (about 10 minutes), then endless mode.

## 1. Get the build

Zips in `playtest/builds/` (git-ignored; shared out of band):

| Platform | File | Run |
|---|---|---|
| macOS (Apple Silicon + Intel) | `Hookmaw-0.1.0-macos-universal.zip` (61 MB) | unzip → `Hookmaw.app` |
| Windows 10/11 | `Hookmaw-0.1.0-windows-x86_64.zip` (38 MB) | unzip → `Hookmaw.exe` (SmartScreen: More info → Run anyway) |
| Linux / Steam Deck desktop | `Hookmaw-0.1.0-linux-x86_64.zip` (28 MB) | unzip → `./Hookmaw.x86_64` |

**Opening on a Mac.** The app is ad-hoc signed but not notarized (we have no Apple Developer ID), so
the first launch is blocked with **"Hookmaw can't be opened because Apple cannot check it for
malicious software"** (on macOS 15+: **"Apple could not verify 'Hookmaw' is free of malware that
may harm your Mac or compromise your privacy."**). That is expected. Do this once:
1. Unzip, drag `Hookmaw.app` to Applications. Double-click it, then click **Done** (not Move to Trash).
2. macOS 15 or later: open **System Settings → Privacy & Security**, scroll down to
   "Hookmaw was blocked to protect your Mac", click **Open Anyway**, enter your password,
   then click **Open Anyway** again in the dialog.
   macOS 14 or earlier: **Control-click the app → Open → Open**.
3. If it still refuses or says the app is "damaged", run this in Terminal and open it again:
   `xattr -dr com.apple.quarantine /Applications/Hookmaw.app`

(Source: `memories/tech/macos-gatekeeper-unnotarized-builds-need-open-anyway`.)

Sound on: the catch, yank and chomp sounds are half of the feel.

## 2. Controls

| | Mouse + keyboard | Controller / Steam Deck |
|---|---|---|
| Move | WASD or arrow keys | left stick or d-pad |
| Aim | mouse | right stick (aim assist on; Settings → Gameplay) |
| Throw hook | left click (or J) | RT or RB |
| Yank (while something is on the line) | click again, mash it | RT / RB again |
| Dodge (brief invulnerability) | Space, Shift or right click | A, LB or LT |
| Evolution choice | click a card | d-pad + A |
| Pause, settings, rebinding, screen shake | Esc or P | Start |

## 3. How to play the test (10–15 minutes)

1. **Just eat (first 2 minutes).** Throw at the small pink snacks, mash yank, feel the chomp. Notice
   the hitstop on the catch, the struggle on the line, the pop when you grow, the camera zooming out.
2. **Learn the four troublemakers (waves 2–5):**
   - **Darter** (yellow, fast): dodges hooks and dashes at you. Lead your aim. Gives **SPEED** (fins).
   - **Shellback** (green, front shell): the hook clangs off its shell. Hook it from behind, or when it
     opens its mouth to bite. Gives **ARMOUR** (plates).
   - **Spitter** (purple jelly): keeps its distance and spits; dodge the green blobs. Gives **POWER**
     (horns: harder yanks, a chomp shockwave).
   - **Puffer** (orange): spiky on and off. Hooking it while spiky hurts you; wait till it deflates
     (or get ARMOUR). Gives **PIERCE** (spines: your hook goes through shells and spikes).
   - A **red ring** means "too big to hook yet" — grow first.
3. **Evolve (about every 2 minutes):** pick how your hook works: Twin Lure (3 hooks), Chain Maw
   (catches leap to nearby prey), Whirlpool (your dodge spins the hook around you), Long Line.
4. **The Lantern Leviathan (around minute 8):** it can only be hooked once you reach the size shown
   at the bottom. Keep eating its snacks until "BIG ENOUGH!", then hook it and mash yank: it takes
   four bites. Dying sends you back to the start of the current wave at your old size.

## 4. Five questions (answer right after playing)

1. **The hook:** did throwing, catching (the freeze-frame), yanking and the chomp feel satisfying?
   Would you happily do it for a minute with no goal? What felt off (too slow, floaty, sticky, hard to aim)?
2. **Growing:** did you notice and enjoy getting bigger? Did the traits (plates, fins, horns, spines)
   and the evolutions change how you played, or were they just numbers?
3. **Fighting back:** did the darters, shellbacks, spitters and puffers make aiming and timing matter?
   Was anything unfair or confusing (e.g. why a hook bounced)?
4. **Pacing:** did the ~10 minutes to the Leviathan feel too long, too short or right? Was there a
   point where you were bored or waiting? Was finally eating the Leviathan a payoff?
5. **Gut call:** after the boss (or a death), did you want another run? With real art and music,
   would you pay ~$10 for a few hours of this? What one change would make it more fun?
