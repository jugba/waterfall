# Shared tools

Scripts reused across projects (scrapers, data processing, build and upload helpers).
Project-specific one-offs stay in that project's folder until a second project needs them.

- `godot/build.sh <project-dir>`: headless import, GUT tests, then Linux + Windows export for a project made from `projects/_template` (see its README).
  Helpers: `godot/install-godot.sh <version>` (pinned binary + templates from GitHub releases) and `godot/fetch-gut.sh <game-dir> <version>`.
