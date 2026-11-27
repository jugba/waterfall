# Screenshots, trailer and short-form video plan: Knolling Co. (working title)

- Written: 2026-11-27
- Sources: `playbooks/marketing.md` §3 (store page) and §4 (channels), `playbooks/steam-launch-checklist.md` (assets), [M:marketing/short-form-video-is-primary-free-channel], [M:design/organizing-hits-count-the-mess-and-unlock-speed], greybox frames in `../assets/greybox/`.
- Deadlines:
  - 5+ screenshots in the store-page submission on **Fri Dec 18**. Vertical-slice art is enough; replace them with final art before Coming Soon on Jan 7 if possible.
  - Trailer v1 by **Jan 7**. A trailer is required for release, not for the Coming Soon review.
  - Short-form clips start in the greybox week (**Dec 7–11**).

## 0. Capture rules

- **Size: 1920×1080 (16:9).** Steam wants at least 1920×1080 at 16:9, but the game's base viewport is 1280×800 (16:10).
  - Capture with `--resolution 1920x1080`. The project uses `stretch/mode=canvas_items` with `aspect=expand`, so the desk widens instead of letterboxing.
  - Check that the UI anchors and the desk framing look intentional at 16:9 before shooting.
  - Use the Xvfb + `--write-movie` recipe [M:tech/godot-headless-capture-xvfb-write-movie] for deterministic frames.
- Real gameplay with the UI visible. No concept art, no title cards, no text overlays baked into the screenshots (playbook §3).
- **At least 5 tagged as gameplay.** The first 3–4 carry the most weight because they show next to the trailer and in hover previews, so they must sell the genre on their own.
- No real brands on objects, and keep the content all-ages (`store-page.md` §9).
- Use different clients, desk surfaces and grouping styles across shots so the page shows variety. Hits median 10 screenshots [M:market/small-scope-hits-are-small-builds-single-player-3-to-9-hours]; aim for 8.

## 1. Screenshot shot list (in store order)

| # | Shot | What is on screen | Why it is in this slot |
|---|---|---|---|
| 1 | **Halfway: chaos meets order** | Mid-sort on the hiker's day pack (Sam). The left 40% of the desk is still the tipped-out mess (`02-tip.png` energy). The right 60% is a crisp colour-grouped grid. The cursor is carrying one item toward its slot, with the snap guide glowing. Job header visible: "Sam's day pack · 22 items" | The genre in one glance; the capsule (Sketch 1) and trailer open on the same idea |
| 2 | **The score** | Finished flat-lay with the score panel: "IMMACULATE 96%", reasons with points ("Square to the desk +20, Lined up in rows +28, Even spacing +24, Grouped by type +25"), pay, confetti (`06-score-reveal.png` with final art) | Sells "freeform, but you know why", the main differentiator, and the satisfying payoff |
| 3 | **The tip** | A big container (toolbox or magician's trunk) upended at the instant of impact: 60+ objects in motion, slight motion trails, dust puff | Counts the mess ("60 items") and gives energy. Shows that each mess is different |
| 4 | **The pack** | Packing view: the backpack interior with most items fitted, one item rotating into the last gap, the "lid closes" prompt. If it ships, a "PERFECT PACK" badge | The second verb, which separates us from shelf-fillers and Unpacking |
| 5 | **Rainbow** | A different client (kid's pencil case or sewing box) on a different desk surface (wood), laid out as a colour gradient or spiral | Shows creative freedom and variety; very shareable |
| 6 | **Fix it** | Close-up of a micro-action: wiping a smudge off sunglasses, untangling earbuds, before/after | Tactile depth beyond drag-and-drop |
| 7 | **Clients** | End-of-job card: client Polaroid, handwritten note ("Thank you! I found my lucky pencil!"), pay, the next client's bag waiting | Story and job-sim framing |
| 8 | **Tools and catalogue** | Tool shop (auto-align ruler, sorting trays) next to the catalogue page with "Unknown" silhouettes and identified items | Progression; tells collectathon and incremental players there is a meta |
| 9 (opt.) | **Deck** | The same game at 1280×800 with controller glyphs (or a photo of a Deck running it, if allowed) | Deck players filter for it |

If only 5 are ready on Dec 18, ship #1–5.

## 2. Trailer (30–45 s), beat sheet

Rules:
- Gameplay from frame 1; no studio logo first.
- Must work **muted**, because store autoplay is silent.
- Sound design (clicks, snaps, the lid) is the hook when unmuted.
- One trailer at launch; a second only if it adds something (playbook §3).
- Export 1920×1080, 30 fps.

| Time | Beat | Picture | Sound |
|---|---|---|---|
| **0:00–0:03** | **HOOK: tip → sorted** | Hard cut in: backpack upended, 60 items scatter (0:00–0:01). Then a 2-second sped-up timelapse snaps everything into a perfect grid, ending on a camera flash and an "IMMACULATE" stamp | Clatter, then a rapid run of rising snap-clicks, then the shutter |
| 0:03–0:06 | Title flash (short) | Logo stamps onto the mat as a label-maker strip; holds 1 s | Label-maker *zzzt* |
| 0:06–0:12 | The real feel | Real-time sorting: drag, snap, magnetic alignment, a row straightening; cursor movement calm and confident | Individual material sounds (metal clink, plastic tick, paper slide) |
| 0:12–0:17 | No single answer | Three quick finished layouts of the *same* bag: by type, by colour (rainbow), by size (spiral). Score panel reasons pop for each | Three different "ding"s |
| 0:17–0:22 | Pack it back | Rotate, fit, slide; the last item drops in; the lid closes; "PERFECT PACK" | The best sound in the game: the lid thunk |
| 0:22–0:28 | Every bag tells a story | Montage of 4 tips at 1 s each: pencil case, toolbox, sewing box, magician's trunk (a rubber chicken bounces out). Polaroid + note beat | Music comes up |
| 0:28–0:33 | Get faster | Auto-align ruler sweeps a whole row straight; colour brush; bigger desk unlock | Whoosh + chain snaps |
| 0:33–0:38 | Payoff | Pull back from a huge, perfectly knolled trunk layout (the biggest job) | Music peak |
| 0:38–0:43 | End card | Logo, "Wishlist on Steam", platform icons (Windows, Steam Deck), "Follow [Studio] on Steam" | Final click |

Cut-down versions:
- **15 s**: beats 0:00–0:06, then 0:17–0:22, then the end card. Use it for the Coming Soon announcement and Reddit.
- **6 s**: the hook alone, plus the logo.

## 3. Store-page GIFs (for `{GIF-n}` markers in `store-page.md` §2)

Each GIF is 616 px wide, 3–5 s, looping, under the current size limit (check in Steamworks).

| Marker | Content |
|---|---|
| GIF-1 | The trailer's 0:00–0:03 hook |
| GIF-2 | The score panel counting up with reasons |
| GIF-3 | The pack and the lid closing |
| GIF-4 | The auto-align ruler snapping a whole row |

## 4. Short-form video (TikTok / YouTube Shorts / Reels), starting from the greybox

Rules (from [M:marketing/short-form-video-is-primary-free-channel]):
- Post 3–5 clips a week from Dec 7, cross-posted to all three platforms with UTM-tagged Steam links.
- Vertical 1080×1920, 7–20 s. The hook lands in the first second, and the clip must read muted.
- **Hook test from the BRIEF:**
  - Pass: at least one greybox clip passes 10k views by Dec 18.
  - Kill or reshape: if every clip stays under ~2k views.
- Record views, likes, shares, comments and wishlists per clip in the iteration file.

Vertical framing: the desk is landscape. Shoot the grid tighter, using a portrait-shaped desk area for clips, or a "portrait job" debug scene, so the items fill the frame.

**Idea 1: "Satisfying: tip → knolled" (greybox from week 1)**
- The core loop as an oddly-satisfying timelapse, with real gameplay sound turned up.
- Caption: "POV: you're a professional organizer" or "Day 1 of making a game about knolling".
- Greybox version: coloured rectangles snapping into a grid. It still works, because the satisfaction is in the motion and the sound.
- Later: a "greybox vs final art" side-by-side follow-up.
- Tags: #knolling #oddlysatisfying #organizing #gamedev #indiegame.

**Idea 2: "Whose bag is this?" (needs item sprites, from Dec 14)**
- Tip out a bag, knoll it fast, then freeze on the finished flat-lay with the caption "Guess who owns this bag (answer in the comments)".
- Pin the answer, the client Polaroid, in a reply video.
- Built for comments, which drive reach. Every client job becomes a clip, so the 30 jobs are 30 posts.

**Idea 3: "Does this count as neat? The scorer judges" (greybox onward)**
- Make deliberately bad or weird layouts (a smiley face, a single long line, everything stacked in a corner) and let the score panel's reasons react. Then show the perfect one.
- Caption: "I made a game that grades how neat you are".
- Shows the freeform-score differentiator. Invites duets and "do mine" comments, and the dev-diary tone builds a following for the studio account.

Backups:
- An ASMR version with no music, only material sounds.
- A "pack it back, will the lid close?" suspense clip.
- Before/after on a real-life desk next to the in-game desk.
