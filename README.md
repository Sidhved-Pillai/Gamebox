# Gamebox Steam Play

Gamebox is a source fork of [NotProton](https://github.com/NotProtonNot/NotProton) at commit `42c1a9174d2a742cfdfe7808d76d133417d441dc`. It uses NotProton's Steam Play bridge for the native macOS Steam client and a supported, separately licensed CrossOver installation. The app window and bundle are branded Gamebox; the internal Steam bridge and support folder retain upstream `notproton` names so their paths and update checks continue to agree.

**This is a development build, not a validated replacement.** It has not been tested with Steam, CrossOver, or GTA V Enhanced on this Mac because those applications are not present here. It cannot promise to fix every DirectX or Rockstar Launcher error. Gamebox and NotProton share internal Steam modifications and should not be installed side by side. Use the upstream uninstall/repair flow before switching implementations.

## What the upstream bridge provides

- Enables Windows game downloads in the existing macOS Steam client through Steam Play.
- Builds a per-game CrossOver prefix and lets Steam launch games through the selected compatibility tool.
- Supports CrossOver 26.3 and several pinned Preview versions, subject to exact binary validation.
- Includes prefix management, backups, Wine tools, and plugins.
- Adds a GTA V Enhanced launch check for known DirectX 12 and Rockstar authentication signatures in the per-game logs. It gives targeted next steps and does not alter saves or game files.

Steam Cloud is handled by Steam when a game supports it. Rockstar authentication and cloud saves depend on Rockstar Games Launcher functioning for that game. Neither is independently implemented by Gamebox. GTA V Enhanced may require a newer CrossOver Preview for DirectX 12 compatibility; the installed 26.3 runner alone is not a guaranteed fix.

## Build

The full build requires Xcode 27, Homebrew, `mingw-w64`, `bison`, `flex`, `fontforge`, `gpatch`, and the pinned Dobby source. See `.github/workflows/app.yml` for the build sequence. `make app` creates `out/Gamebox.app` after the payload has been staged. A successful CI run uploads `Gamebox.zip` as a workflow artifact.

The Mac used to prepare this fork has Command Line Tools only, so a complete local build could not be run. The first CI build is the verification gate before any release.

## License and attribution

The core fork remains under GPLv3. Keep `LICENSE`, `NOTICE`, component license files, and source attribution when redistributing. Some Valve-derived components have different licenses described in `NOTICE`. CrossOver binaries are not included.
