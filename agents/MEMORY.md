# Memory

## What failed

- Accessibility window fill: AppKit clamps `AXPosition`/`AXSize` to `visibleFrame` (y ≥ 32 pt
  on the 16" screen), even for borderless windows and with the menu bar on auto-hide.
  `AXFrame` is not settable. Feature removed.
- AppKit defaults (`NSFullScreenTileFillsScreen`, `NSApplicationSafeAperture*`) do not
  change the native full screen frame.

- `APPLE_DISPLAY_SAFE_AREA_COMPATIBILITY_MODE=1`: window gets 1117 pt, but the display output
  is scaled below the notch (user saw a black strip). ScreenCaptureKit screenshots hide this
  scaling — never trust a capture for this; ask the user to look.
- `SLSTransactionSetSafeApertureOverride` / `…SpaceReveal` from a non-Dock process: no effect.

## What worked

- In-game hook: swizzle `-[NSWindow _frameForFullScreenMode(InRect:)]` + window level
  `kCGMainMenuWindowLevel + 1` in full screen → strip filled (user confirmed by eye).
  The black strip in full screen is WindowServer's `Menubar` window, not a clip.

- Borderless window sized by the owning app to `screen.frame` → full 1117 pt.
- `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0`: SDL2 and SDL3 desktop full screen → 1728×1117 at y=0
  (checked with dlopen test against installed SDL dylibs, also via `launchctl setenv` + `open`).
- ScreenCaptureKit on the notch rect with `showsCursor` → mirror.
- Self-signed identity → TCC designated requirement `identifier + certificate leaf`,
  grants survive rebuilds (ad-hoc gives `cdhash`, lost on every build).
- `tccutil reset <Service> dev.notchfill.NotchFill` clears stale grants.

- lldb works on our own test processes (no SIP needed) to disassemble AppKit/SkyLight
  from the shared cache; `otool -tV` on the Dock binary shows stub names at call sites.
- Diagnostics that capture the screen: launch NotchFill with `open -g`, or the activation
  switches away from the full screen Space.

## Gotchas

- patch-game restore once matched backups by bundle id and overwrote a game's outer
  wrapper `load` (same bundle id as the inner game). Now: backups keyed by executable path,
  restore uses path.txt only. Back up every file you might touch, including wrappers.

- Never rewrite a signed Mach-O in place (same inode): next launch is SIGKILLed. Write a new
  file and rename it over the old one.
- Scanning for hardened games must include nested apps (wrapper launchers like `load`).
- Do not take display snapshots while the user may be using the Mac: they capture private
  windows. Ask the user to look instead.

- `set -o pipefail` + `tr </dev/urandom | head` exits 141 (SIGPIPE).
- Diagnostics args use a single dash (`-mirror-snapshot`), they come from NSArgumentDomain.
