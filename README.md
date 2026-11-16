# NotchFill

Open source tool that lets games on a notched MacBook use the whole display, including
the strip beside the notch, which macOS normally leaves black in full screen.
Inspired by ProMax Display; no code is shared with it.

> Status: early. Everything works **without SIP changes**. Measurements and how it works:
> [docs/RESEARCH.md](docs/RESEARCH.md).

## Features

| Feature | How | Needs |
|---------|-----|-------|
| **Native full screen into the notch strip** | A small library (`libNotchFillHook.dylib`) is loaded into the game. It removes AppKit's cut below the notch and keeps the full screen window above the black menu bar. Start the game from the menu (**Launch Game with Notch Fill…**) or, for Steam, use **Copy Steam Launch Option** and paste it in the game's Properties › Launch Options. | Game without hardened runtime (most games). Code runs inside the game: do not use it with online anti-cheat games. |
| **Game resolution (Unity)** | Menu › **Game Resolution**: Full / 75% / 50% of the whole display (e.g. 3456×2234). Unity games then start with `-screen-width/-screen-height`, so the picture has the aspect of the whole screen instead of 16:10 with bars. Used by **Launch Game…** and included in the Steam option (copy it again after a change). | Unity game |
| **SDL games use the notch area** | Sets `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0` with `launchctl setenv`, so SDL2/SDL3 games use a borderless window over the whole display (1728×1117 instead of 1728×1084 on a 16" MacBook Pro). Restart Steam and the game after you change it. Apps that you start from Terminal do not get it; use `SDL_VIDEO_MAC_FULLSCREEN_SPACES=0 ./game` there. | – |
| **Rear-view mirror** | Move the pointer behind the notch: a panel below the notch shows what is there, pointer included. Clicks go to the app behind. Toggle: ⌃⌥⌘M. | Screen Recording |
| **Hide menu bar and Dock** | Turns on auto-hide for both, and puts back your own settings when you turn it off or quit (also after a crash, on the next launch). | – |

Limits: games with the hardened runtime block the library, also when only the inner app of a
wrapper is hardened (NotchFill tells you). For such a game you can patch its
files (backup first, undo any time):

```bash
python3 scripts/patch-game.py patch   "/Applications/Some Game.app"
python3 scripts/patch-game.py restore "/Applications/Some Game.app"
```

The patch adds a weak load command for the library (copied to
`~/Library/Application Support/NotchFill/`) and re-signs the app ad-hoc with its own
entitlements. The game then starts normally (Steam, Finder) with notch fill and NotchFill's
**Game Resolution**. A game update or Steam "verify files" removes the patch. While a
game is in full screen, the menu bar does not slide down at the top edge; use the
rear-view mirror to see what is behind the notch.

## Requirements

- MacBook with a notch, macOS 14 or later (tested on macOS 27.2).
- Command Line Tools (`xcode-select --install`). Xcode is not needed.

## Build and run

```bash
./scripts/create-dev-cert.sh   # once: local signing identity, keeps permissions between builds
./scripts/build-app.sh
open build/NotchFill.app
```

`create-dev-cert.sh` adds a self-signed "NotchFill Dev" identity to your login keychain.
Without it the app is signed ad-hoc, and macOS asks for permissions again after each build.

## Diagnostics

```bash
open -n build/NotchFill.app --args -mirror-snapshot /tmp/mirror.png -report /tmp/report.txt -quit-after 1
```

Starts the mirror, moves the pointer behind the notch, saves what the mirror shows.

## Licence

MIT, see [LICENSE](LICENSE).
