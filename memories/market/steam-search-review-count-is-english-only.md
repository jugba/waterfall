# Steam search-row review counts are language-filtered (≈English); use the review histogram or appdetails for all-language totals

- Area: market
- Date / source: 2026-11-26, projects/001-steam-market-research (iteration 002): research/processed/analysis.md, reports/market-report.md; raw/histogram/, raw/appdetails/
- Confidence: high (744 games compared)
- Apply when: pulling review counts for market research or comparables, or applying the Boxleiter multiplier.

The hover tooltip in Steam search results counts reviews in the viewer's language only. For the same games, two all-language sources agree with each other within about 1%:
- the review histogram (`store.steampowered.com/appreviewhistogram/<appid>`);
- appdetails `recommendations.total`.

Those totals are a median **1.39×** the search count. They exceed 2× for 125 of 744 games, and 10× for Chinese-market hits such as Phantom Blade Zero.

What follows:
- Any "≥N reviews" cut made on search counts under-represents Asian-market hits.
- Revenue estimates should use the all-language total.
- The `appreviews` API redirected to the store homepage on 2026-11-26.
- The histogram endpoint still works. Its `start_date` is the date of the first review, and its rollups give monthly up/down counts.
