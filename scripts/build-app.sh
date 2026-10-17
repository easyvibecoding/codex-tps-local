#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h:h}"
APP_DIR="$ROOT_DIR/dist/Codex TPS Local.app"
ENTITLEMENTS="$ROOT_DIR/Resources/LocalOnly.entitlements"
cd "$ROOT_DIR"

python3 scripts/verify-local-only.py
swift build -c release --product CodexTPSLocal
swift build -c release --product codex-tps-local-snapshot
BIN_DIR="$(swift build -c release --show-bin-path)"
mkdir -p "$ROOT_DIR/dist"
STAGE="$(mktemp -d "$ROOT_DIR/dist/.build.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
STAGED_APP="$STAGE/Codex TPS Local.app"
mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"
ditto "$BIN_DIR/CodexTPSLocal" "$STAGED_APP/Contents/MacOS/CodexTPSLocal"
ditto "$BIN_DIR/codex-tps-local-snapshot" "$STAGED_APP/Contents/MacOS/codex-tps-local-snapshot"
ditto Resources/Info.plist "$STAGED_APP/Contents/Info.plist"
ditto Resources/AppIcon.icns "$STAGED_APP/Contents/Resources/AppIcon.icns"
ditto LICENSE "$STAGED_APP/Contents/Resources/LICENSE"
ditto LICENSES "$STAGED_APP/Contents/Resources/LICENSES"
plutil -lint "$STAGED_APP/Contents/Info.plist"
codesign --force --sign - --options runtime --entitlements "$ENTITLEMENTS" \
  --identifier io.github.easyvibecoding.codex-tps-local.snapshot \
  "$STAGED_APP/Contents/MacOS/codex-tps-local-snapshot"
codesign --force --sign - --options runtime --entitlements "$ENTITLEMENTS" "$STAGED_APP"
codesign --verify --deep --strict "$STAGED_APP"
python3 scripts/verify-local-only.py "$STAGED_APP"
rm -rf "$APP_DIR"
mv "$STAGED_APP" "$APP_DIR"
echo "Built local, ad-hoc signed sandboxed app: $APP_DIR"
