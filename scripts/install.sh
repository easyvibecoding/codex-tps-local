#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
INSTALL_DIR="${CODEX_TPS_LOCAL_INSTALL_DIR:-/Applications}"
[[ $# -eq 0 || ( $# -eq 1 && "$1" == "--no-launch" ) ]] || {
  echo "Usage: $0 [--no-launch]" >&2
  exit 2
}
"$ROOT_DIR/scripts/build-app.sh"
mkdir -p "$INSTALL_DIR"
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd -P)"
DEST_APP="$INSTALL_DIR/Codex TPS Local.app"
[[ ! -L "$DEST_APP" ]] || { echo "Refusing a symlink destination" >&2; exit 1; }
[[ ! -e "$DEST_APP" || -d "$DEST_APP" ]] || { echo "Destination is not an app directory" >&2; exit 1; }
STAGE="$(mktemp -d "$INSTALL_DIR/.codex-tps-local.XXXXXX")"
REPLACED=0
SUCCESS=0
cleanup() {
  if [[ "$SUCCESS" == 0 ]]; then
    if [[ -d "$STAGE/previous.app" ]]; then
      rm -rf "$DEST_APP"
      mv "$STAGE/previous.app" "$DEST_APP"
    elif [[ "$REPLACED" == 1 ]]; then
      rm -rf "$DEST_APP"
    fi
  fi
  rm -rf "$STAGE"
}
trap cleanup EXIT
trap 'exit 130' INT TERM
ditto "$ROOT_DIR/dist/Codex TPS Local.app" "$STAGE/new.app"
python3 "$ROOT_DIR/scripts/verify-local-only.py" "$STAGE/new.app"

# Only stop an older copy at this exact destination, never upstream apps.
for pid in ${(f)"$(pgrep -x CodexTPSLocal 2>/dev/null || true)"}; do
  [[ -n "$pid" ]] || continue
  command="$(ps -ww -p "$pid" -o command=)"
  if [[ "$command" == "$DEST_APP/Contents/MacOS/CodexTPSLocal" || "$command" == "$DEST_APP/Contents/MacOS/CodexTPSLocal "* ]]; then
    kill -TERM "$pid"
    for attempt in {1..50}; do
      kill -0 "$pid" 2>/dev/null || break
      sleep 0.1
    done
    if kill -0 "$pid" 2>/dev/null; then
      echo "App did not exit; installation left unchanged" >&2
      exit 1
    fi
  fi
done
[[ ! -d "$DEST_APP" ]] || mv "$DEST_APP" "$STAGE/previous.app"
REPLACED=1
mv "$STAGE/new.app" "$DEST_APP"
python3 "$ROOT_DIR/scripts/verify-local-only.py" "$DEST_APP"
if [[ "${1:-}" != "--no-launch" ]]; then
  open "$DEST_APP"
fi
SUCCESS=1
echo "Installed: $DEST_APP"
echo "Local ad-hoc signature; not a Developer ID signed or notarized release."
