# Check game names against Steam's search JSON for exact title substrings; common organizing words (Tidy, Sort, Neat, Unpack, Everything…) are already taken

- Area: marketing
- Date / source: 2026-11-27, projects/002-cozy-organizing-sim/store/name-check.md
- Confidence: high for the method; medium for the crowding (2026-11 snapshot)
- Apply when: picking or checking a working title, before commissioning a logo.

`https://store.steampowered.com/search/results/?term=<q>&count=15&infinite=1&ndl=1` is reachable from the container and returns JSON. Its `results_html` holds `data-ds-appid` and the title for each result.

How to read it:
- Search is fuzzy, so `total_count` > 0 does not mean a conflict. Check whether any returned **title contains the word**.
- Then pull `api/appdetails?appids=<id>` for close matches.

State of organizing-game names as of 2026-11:
- Taken or crowded: "Tidy Up the X" (143 releases), "Sort Them X", "Sorted", "Neat!", the "Organized Neatly" series, "Everything In Its Place", "Everything MUST Fit!", "Organizer Pro" and "Unpacking" names.
- Still unused: niche hobby terms such as "knolling" and "flat lay".

Steam and the web are only a first screen. The user must still run a USPTO/EUIPO/WIPO (and CNIPA if shipping Chinese) search in classes 9, 28 and 41. Lock the name before logo work starts, about 2 weeks before the store-page submission.
