#!/usr/bin/env bash
# Builds NotchFill.app into ./build. Needs only the Command Line Tools.
# Set CODESIGN_IDENTITY to a stable certificate name so macOS keeps the
# Accessibility / Screen Recording grants between builds (ad-hoc by default).
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${CONFIG:-release}"
# SWIFT_EXTRA_FLAGS: extra `swift build` arguments (scripts/release.sh uses it); split on spaces.
# shellcheck disable=SC2086
swift build -c "$CONFIG" ${SWIFT_EXTRA_FLAGS:-}

APP="build/NotchFill.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/NotchFill" "$APP/Contents/MacOS/NotchFill"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Game hook (arm64 + x86_64, so Rosetta games work too) and its launcher.
HOOK_FLAGS=(-arch arm64 -arch x86_64 -mmacosx-version-min=11.0 -O2 -Wall)
clang "${HOOK_FLAGS[@]}" -dynamiclib -fobjc-arc -framework AppKit \
  -o "$APP/Contents/Resources/libNotchFillHook.dylib" Hook/NotchFillHook.m
clang "${HOOK_FLAGS[@]}" -framework CoreFoundation \
  -o "$APP/Contents/MacOS/notchfill-run" Hook/notchfill-run.c

# Default: the local "NotchFill Dev" identity if it exists (scripts/create-dev-cert.sh), else ad-hoc.
if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  if security find-certificate -c "NotchFill Dev" >/dev/null 2>&1; then
    CODESIGN_IDENTITY="NotchFill Dev"
  else
    CODESIGN_IDENTITY="-"
  fi
fi

# Nested code first. The hook and the launcher run inside / start games, so no hardened
# runtime on them (it would strip DYLD_INSERT_LIBRARIES from the launcher's child).
codesign --force --sign "$CODESIGN_IDENTITY" --identifier dev.notchfill.hook \
  "$APP/Contents/Resources/libNotchFillHook.dylib"
codesign --force --sign "$CODESIGN_IDENTITY" --identifier dev.notchfill.run \
  "$APP/Contents/MacOS/notchfill-run"
codesign --force --options runtime \
  --sign "$CODESIGN_IDENTITY" \
  --identifier dev.notchfill.NotchFill "$APP"
echo "Signed with: $CODESIGN_IDENTITY"

echo "Built $APP"
