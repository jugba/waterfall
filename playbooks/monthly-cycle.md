# Monthly release cycle (v1 — desk-researched, not yet run)

- Revised: 2026-11-26. v0 had the build going to Steam review in week 3, which is too late:
  Valve's build review currently takes up to 12 business days, and the Coming Soon page has to
  be public for at least 2 weeks (see `playbooks/steam-launch-checklist.md`).
- Learned from: desk research only. Validate on the first game project and revise it in that postmortem.

## The key idea: a staggered pipeline, not one game per month in isolation

Each game takes about 10 weeks from start to launch. A new game **starts** every 4 weeks,
so one **ships** every 4 weeks, and at any moment about three games are in flight:

```
week:      1   2   3   4   5   6   7   8   9  10  11  12
Game N     [concept/proto][ production  ][polish][LAUNCH]
           fee paid ··· page live ········· build review ···
Game N+1                   [concept/proto][ production  ][polish][LAUNCH]
Game N+2                                   [concept/proto] ...
```

## Per-game timeline (T = launch day)

| When | Development | Steam / marketing |
|---|---|---|
| T-10w | Pick a concept from market research; paper design; set the scope and cut list in BRIEF.md | Pay the $100 Steam Direct fee (30-day wait before release) |
| T-9w | Prototype the core loop; the go/no-go test is "is it fun in 5 minutes?" | Capsule art brief; working title and tags |
| T-8w | Vertical slice: core loop polished and juicy | Fill in the content survey (including AI disclosure); store page draft; submit store page for review (allow 7+ business days) |
| T-6w → T-5w | Content production | **Coming Soon page live** (~5 weeks before launch, minimum 2); trailer v1; creator list |
| T-4w | **Feature-complete build submitted for Steam review** (must have recent Steam-launched playtime) | Social clips, creator outreach |
| T-3w → T-1w | Polish, playtests, bugs, Deck testing | Press kit, launch-discount setup (≤40%, 7–14 days), schedule announcements |
| T | Launch | Wishlist email goes out automatically; post everywhere |
| T+1w → T+4w | Patch from player feedback | Respond to reviews; no other discounts for 30 days |

Assumption to verify: after a build passes review, later builds can be uploaded without
another review, so polishing can continue after T-4w. Check this in Steamworks before relying on it.

## Calendar rules
- To join a seasonal sale, release 30 or more days before it starts (see the sale table in the launch checklist).
- Next Fest: one per game, needs an unreleased game with a demo. Decide which game takes each fest
  (Feb 2027: registration closes Jan 10, 2027).
