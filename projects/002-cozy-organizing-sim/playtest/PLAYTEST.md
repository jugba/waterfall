# Knolling Co. — week-1 greybox playtest (v0.1.0)

Question we are answering: **is it fun in 5 minutes?** (BRIEF.md, schedule T-9w go/no-go).
Who: the user + 3–4 testers, one at a time. ~10 minutes each: 5 playing, 5 for the form.

## 1. Get the build (observer, before the tester sits down)

Builds are made by `tools/godot/build.sh projects/002-cozy-organizing-sim` and copied to
`playtest/builds/` (git-ignored, shared out of band, e.g. a drive link):

| Platform | File | Run |
|---|---|---|
| macOS (Apple Silicon + Intel) | `KnollingCo-0.1.0-macos-universal.zip` | unzip → `KnollingCo.app` |
| Windows 10/11 | `KnollingCo-0.1.0-windows-x86_64.zip` | unzip → `KnollingCo.exe` (SmartScreen: More info → Run anyway) |
| Linux / Steam Deck desktop | `KnollingCo-0.1.0-linux-x86_64.zip` | unzip → `./KnollingCo.x86_64` |

**Opening on a Mac.** The app is ad-hoc signed, not notarized (we have no Apple Developer ID), so
macOS blocks the first launch with "cannot be opened / Apple could not verify…". Do this once:
1. Unzip, drag `KnollingCo.app` to Applications (or Desktop). Double-click it; click **Done**.
2. macOS 14 and older: **right-click (Control-click) the app → Open → Open**.
   macOS 15+ (that menu no longer bypasses it): **System Settings → Privacy & Security**, scroll to
   "KnollingCo.app was blocked…", click **Open Anyway**, enter your password, then **Open**.
3. Fallback if it still refuses or says "damaged": in Terminal run
   `xattr -dr com.apple.quarantine /Applications/KnollingCo.app` and open it again.

Do this setup *before* the session so the tester's 5 minutes start at the title screen. Start the
game, go Settings → set volume to a comfortable level, return to the title screen. Hand over.

## 2. Controls (tell the tester nothing; this is for the observer)

| | Mouse + keyboard | Controller |
|---|---|---|
| Tip the container (intro) | click / Space | A |
| Pick up / drop an item | drag with left mouse | stick moves cursor, A grab / drop |
| Rotate 90° | right-click or wheel (Q / E / R) | LB / RB |
| Move to next item / nudge held item one cell | WASD / arrows | D-pad |
| Take the photo (score the desk) | Enter or F | Y |
| Pause | Esc or P | Start |

The on-screen hint line shows these. Test at least one tester on a controller (Deck if available).

## 3. The session (no coaching)

Say only: *"This is an early prototype of a game about tidying. Play it for five minutes. Please
think out loud — say what you're trying to do and what you like or don't. I can't help or answer
questions until the end."* Then press Play for them or let them, start a 5-minute timer, and stay
quiet. If they are fully stuck for 60 s, say "do whatever you'd try next" — nothing more; log it.
Stop at 5:00 (let them finish a photo if one is seconds away). Then hand them the feedback form.

## 4. What the observer writes down (timestamps, the tester's words verbatim)

- **Tip and snap feel.** Reaction when the container tips (smile, "oh", nothing?). Do they keep
  dragging for its own sake? Do they comment on the snap / click / line-up sound?
- **Score fairness.** At the photo: do they read the score-card reasons (eyes, comments) or skip
  them? Do they agree with the score ("that's fair" / "why so low?")? Do they Retry to beat it?
- **Layout strategy.** Do they sort by **type**, by **colour**, by size, or freeform? Do they try a
  different layout on the retry or next job? (The scorer rewards several; we want them to notice.)
- **Confusion points.** First 30 s: do they know what to do? When do they find rotate and photo?
  Any moment they say "what now?" or stop moving.
- **Input.** Mouse vs controller: missed grabs, wrong item picked, d-pad jumps that surprise them.
- **Progress.** How far they got in 5 min (job 1 done? job 2 started?) and their scores.
- **Unprompted desire.** "Can I keep playing?" / "One more" / looks at the clock. This is the
  strongest signal; note it exactly.

Record one line per tester in `playtest/results.md` (date, tester, platform, input, jobs done,
scores, fun rating from form Q1, quotes, top confusion).

## 5. Go / no-go rule (from BRIEF.md)

**GO** if **at least 3 of 4 testers rate it fun** (form Q1 = 4 or 5) after 5 minutes.
Otherwise **NO-GO**: reshape the core loop before the vertical slice (don't polish).
Read together with the hook test (≥1 greybox clip >10k views; kill/reshape if all clips stay
under ~2k). Write the decision and evidence into the next iteration file.
