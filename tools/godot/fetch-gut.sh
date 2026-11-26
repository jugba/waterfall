#!/usr/bin/env bash
# Install the GUT test framework (https://github.com/bitwes/Gut, MIT) into a Godot project.
#
#   tools/godot/fetch-gut.sh <game-dir> <gut-version, e.g. 9.7.1>
#
# GUT is fetched, not committed: <game-dir>/addons/gut/ is gitignored and the version is
# pinned in the project's build.env. Uses `git clone` of the release tag because github.com
# git is reachable from the Claude container (api.github.com is not). Idempotent.
set -euo pipefail

GAME_DIR="${1:?usage: fetch-gut.sh <game-dir> <gut-version>}"
VERSION="${2:?usage: fetch-gut.sh <game-dir> <gut-version>}"
DEST="$GAME_DIR/addons/gut"
MARKER="$DEST/.fetched-version"

if [[ -f "$MARKER" && "$(cat "$MARKER")" == "$VERSION" ]]; then
  exit 0
fi

echo "[fetch-gut] installing GUT $VERSION into $DEST" >&2
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -c advice.detachedHead=false clone -q --depth 1 --branch "v$VERSION" \
  https://github.com/bitwes/Gut.git "$tmp/gut"
rm -rf "$DEST"
mkdir -p "$GAME_DIR/addons"
cp -r "$tmp/gut/addons/gut" "$DEST"
echo "$VERSION" > "$MARKER"
