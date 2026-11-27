#!/usr/bin/env bash
# Install a pinned Godot editor binary and the Linux, Windows and macOS export templates.
#
#   tools/godot/install-godot.sh 4.7.1        # prints the path of the godot binary on stdout
#
# Sources are GitHub releases (downloads.godotengine.org is blocked in the Claude container).
# Binary goes to $GODOT_HOME/<version>/ (default ~/.cache/godot); templates go to Godot's
# standard folder ~/.local/share/godot/export_templates/<version>.stable/. Idempotent: does
# nothing if both are already present. The full templates archive is ~1.3 GB, so only the
# files we export with are extracted and the archive is deleted afterwards.
set -euo pipefail

VERSION="${1:?usage: install-godot.sh <godot-version, e.g. 4.7.1>}"
GODOT_HOME="${GODOT_HOME:-$HOME/.cache/godot}"
BIN_DIR="$GODOT_HOME/$VERSION"
BIN="$BIN_DIR/Godot_v${VERSION}-stable_linux.x86_64"
TPL_DIR="${GODOT_TEMPLATES_DIR:-$HOME/.local/share/godot/export_templates/${VERSION}.stable}"
BASE="https://github.com/godotengine/godot/releases/download/${VERSION}-stable"

log() { echo "[install-godot] $*" >&2; }

if [[ ! -x "$BIN" ]]; then
  log "downloading Godot $VERSION editor"
  mkdir -p "$BIN_DIR"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/godot.zip" "$BASE/Godot_v${VERSION}-stable_linux.x86_64.zip"
  unzip -q -o "$tmp/godot.zip" -d "$BIN_DIR"
  rm -rf "$tmp"
  chmod +x "$BIN"
fi

need=(linux_release.x86_64 linux_debug.x86_64 windows_release_x86_64.exe windows_debug_x86_64.exe macos.zip version.txt)
missing=0
for f in "${need[@]}"; do [[ -f "$TPL_DIR/$f" ]] || missing=1; done
if [[ $missing -eq 1 ]]; then
  log "downloading export templates $VERSION (~1.3 GB, extracting Linux + Windows + macOS only)"
  mkdir -p "$TPL_DIR"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/templates.tpz" "$BASE/Godot_v${VERSION}-stable_export_templates.tpz"
  args=()
  for f in "${need[@]}"; do args+=("templates/$f"); done
  unzip -q -o -j "$tmp/templates.tpz" "${args[@]}" -d "$TPL_DIR"
  rm -rf "$tmp"
fi

echo "$BIN"
