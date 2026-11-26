# Memories

Durable learnings that should change how we work on future projects. Not a diary —
the diary is `projects/*/iterations/`.

## Layout: one memory per file, named by topic

```
memories/
├── INDEX.md                         # every memory, one line each — read first
├── market/      what sells on Steam: genres, prices, tags, timing, competition
├── design/      game design and polish: feel, onboarding, scope
├── tech/        engine, tooling, builds, performance, Steamworks
├── marketing/   store page, capsules, trailers, wishlists, festivals, creators
└── process/     how we work: scheduling, scoping, prompting Claude, reviews
```

File name = the topic in kebab-case, specific enough to find by filename alone:
`market/roguelike-deckbuilders-saturated.md`, `marketing/coming-soon-page-two-weeks-minimum.md`,
`tech/steam-appreviews-api-redirects.md`. Refer to a memory by its path
(`market/roguelike-deckbuilders-saturated`), never by a number.

To find things: read `INDEX.md`, or `ls memories/<area>/`, or glob `memories/**/*<keyword>*`.

## File format

```markdown
# <The learning, as one sentence>

- Area: market | design | tech | marketing | process
- Date / source: YYYY-MM-DD, <project/iteration or link to evidence>
- Confidence: low | medium | high
- Apply when: <the situation where this should change a decision>

<Short explanation, numbers, links.>
```

When newer evidence contradicts a memory, update it and add a `- Revised:` line saying
why. Don't silently delete. Keep `INDEX.md` in sync in the same commit.
