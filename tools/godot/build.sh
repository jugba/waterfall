#!/usr/bin/env bash
# Headless import -> tests -> export for a game project made from projects/_template.
#
#   tools/godot/build.sh <project-dir> [--no-tests] [--no-export] [--platform linux|windows|macos|all]
#
# <project-dir> contains build.env and game/project.godot (e.g. projects/002-my-game).
# Outputs:  <project-dir>/build/linux/<GAME_NAME>.x86_64
#           <project-dir>/build/windows/<GAME_NAME>.exe
#           <project-dir>/build/macos/<GAME_NAME>.zip   (universal <GAME_NAME>.app, ad-hoc signed)
#           <project-dir>/build/test-results.xml   (JUnit, for CI)
# Godot binary: $GODOT if set, else installed/pinned via tools/godot/install-godot.sh.
# Exit code is non-zero if import, any test, or any export fails.
set -euo pipefail

usage() { sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
[[ $# -ge 1 ]] || usage
PROJECT_DIR="$(cd "$1" && pwd)"; shift
RUN_TESTS=1; RUN_EXPORT=1; PLATFORM=all
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-tests) RUN_TESTS=0 ;;
    --no-export) RUN_EXPORT=0 ;;
    --platform) PLATFORM="${2:?}"; shift
      case "$PLATFORM" in linux|windows|macos|all) ;; *) echo "unknown platform: $PLATFORM" >&2; usage ;; esac ;;
    -h|--help) usage ;;
    *) echo "unknown option: $1" >&2; usage ;;
  esac
  shift
done

TOOLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GAME_DIR="$PROJECT_DIR/game"
BUILD_DIR="$PROJECT_DIR/build"
[[ -f "$PROJECT_DIR/build.env" ]] || { echo "missing $PROJECT_DIR/build.env" >&2; exit 2; }
[[ -f "$GAME_DIR/project.godot" ]] || { echo "missing $GAME_DIR/project.godot" >&2; exit 2; }
# shellcheck source=/dev/null
source "$PROJECT_DIR/build.env"   # GODOT_VERSION, GUT_VERSION, GAME_NAME
: "${GODOT_VERSION:?set in build.env}" "${GUT_VERSION:?set in build.env}" "${GAME_NAME:?set in build.env}"

step() { echo; echo "==> $*"; }

GODOT="${GODOT:-$("$TOOLS_DIR/install-godot.sh" "$GODOT_VERSION")}"
actual="$("$GODOT" --headless --version 2>/dev/null | tail -n1)"
if [[ "$actual" != "$GODOT_VERSION".* ]]; then
  echo "Godot version mismatch: build.env pins $GODOT_VERSION, $GODOT reports $actual" >&2
  exit 1
fi
echo "Godot $actual  ($GODOT)"
gd() { "$GODOT" --headless --path "$GAME_DIR" "$@"; }

# Fail the build on script errors that Godot only logs (it still exits 0 for those).
check_log() {
  if grep -E "SCRIPT ERROR|Parse Error|Failed to load script|ERROR: Failed to (load|instantiate)" "$1" >/dev/null; then
    echo "!! errors found in $1:" >&2
    grep -E -A2 "SCRIPT ERROR|Parse Error|Failed to load script|ERROR: Failed to" "$1" >&2 || true
    return 1
  fi
}

mkdir -p "$BUILD_DIR"
LOG_DIR="$BUILD_DIR/logs"; mkdir -p "$LOG_DIR"

if [[ $RUN_TESTS -eq 1 ]]; then
  step "fetch GUT $GUT_VERSION"
  "$TOOLS_DIR/fetch-gut.sh" "$GAME_DIR" "$GUT_VERSION"
fi

step "import"
gd --import 2>&1 | tee "$LOG_DIR/import.log"
check_log "$LOG_DIR/import.log"

if [[ $RUN_TESTS -eq 1 ]]; then
  step "tests (GUT)"
  set +e
  gd -s res://addons/gut/gut_cmdln.gd -gexit -gjunit_xml_file="$BUILD_DIR/test-results.xml" \
    2>&1 | tee "$LOG_DIR/tests.log"
  status=${PIPESTATUS[0]}
  set -e
  if [[ $status -ne 0 ]]; then echo "!! tests failed (exit $status)" >&2; exit "$status"; fi
fi

export_one() {  # <preset name> <output path>
  local preset="$1" out="$2"
  step "export $preset -> ${out#"$PROJECT_DIR"/}"
  rm -rf "$(dirname "$out")"; mkdir -p "$(dirname "$out")"
  gd --export-release "$preset" "$out" 2>&1 | tee "$LOG_DIR/export-$preset.log"
  [[ -s "$out" ]] || { echo "!! export $preset produced no file" >&2; exit 1; }
  check_log "$LOG_DIR/export-$preset.log"
  ls -l "$(dirname "$out")"
}

if [[ $RUN_EXPORT -eq 1 ]]; then
  [[ $PLATFORM == all || $PLATFORM == linux ]] && export_one "Linux" "$BUILD_DIR/linux/$GAME_NAME.x86_64"
  [[ $PLATFORM == all || $PLATFORM == windows ]] && export_one "Windows" "$BUILD_DIR/windows/$GAME_NAME.exe"
  if [[ $PLATFORM == all || $PLATFORM == macos ]]; then
    # Exported from Linux: universal .app in a .zip, ad-hoc signed by Godot's built-in signer,
    # not notarized (no Apple Developer ID). See memories/tech/godot-macos-export-unsigned-from-linux.
    export_one "macOS" "$BUILD_DIR/macos/$GAME_NAME.zip"
    # Godot names the bundle after config/name ("My Game (demo).app"); rename the top folder to
    # <GAME_NAME>.app. The bundle folder name is not covered by the code signature.
    python3 -I - "$BUILD_DIR/macos/$GAME_NAME.zip" "$GAME_NAME.app" <<'PY'
import os, sys, zipfile
src, new = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(src) as z:
    old = z.namelist()[0].split("/")[0]
    if old == new:
        sys.exit(0)
    tmp = src + ".tmp"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED) as out:
        for info in z.infolist():
            data = z.read(info)
            info.filename = new + info.filename[len(old):]
            out.writestr(info, data)
os.replace(tmp, src)
print(f"renamed {old} -> {new}")
PY
    unzip -l "$BUILD_DIR/macos/$GAME_NAME.zip" | grep -q "\.app/Contents/MacOS/" \
      || { echo "!! macOS zip has no .app/Contents/MacOS/ executable" >&2; exit 1; }
  fi
fi

step "done"
