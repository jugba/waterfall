# For a rhythm run, lock the runner's x to audio time, generate music + beat map from one script, and prove sync with onset and replay tests

- Area: design
- Date / source: 2026-11-27, projects/004-rhythm-platformer/iterations/001.md (`tools/gen_music.py`, `game/scripts/core/music_course.gd`, `music_run.gd`, `song_clock.gd`)
- Confidence: medium (works and is tested; whether it is *fun* is the fun gate's call)
- Apply when: building any music-synced level (runner, rhythm platformer, rhythm action).

- x = run_speed × audio_time, so an event at beat time t is built at x(t) and "on the beat" means
  "in the right place"; frame hitches can't desync the level. Audio time = playback position +
  time since last mix − output latency, predicted per frame, steered toward the raw value, snapped
  if > 50 ms off, frame-time fallback if the audio clock is frozen (headless/dummy driver).
- One script writes the WAV *and* `beatmap.json` (beat → time → event type) and puts an audible
  accent on each gameplay event (kick = jump, clap = punch). Tests: every event on the grid
  (±10 ms) and the WAV's biggest transient within ±10 ms of each event (worst 0.1 ms).
- Measure the controller's real air times at build time and size pits/canyons from them; place
  collectibles on their beat along the *simulated ideal input replay*, so the perfect run collects them all.
- Smoke test = ideal replay finishes with 0 deaths; ±50 ms shifted replays also finish (fair windows);
  no input dies at the first obstacle; death → respawn seek = checkpoint − 4 beats (count-in).
