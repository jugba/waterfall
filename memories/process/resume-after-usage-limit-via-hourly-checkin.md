# Resume after a usage limit with an hourly check-in and STATUS.md

- Area: process
- Date / source: 2026-11-27, user request (prompts/2026-11-26_001_factory-setup.md, prompt 19)
- Confidence: high
- Apply when: setting up long-running work, or after any session restart.

When the 5-hour limit is hit, everything stops, including the main session, so a wake-up can't be
scheduled at that moment. Instead, a recurring hourly scheduled task fires a resume message into
the session. Check-ins during the limit fail harmlessly, and the first one after the reset resumes
the work. STATUS.md holds the state and the checklist; the environment setup script reinstalls
Godot (tools/godot/install-godot.sh, ~17 s) on a fresh container.
