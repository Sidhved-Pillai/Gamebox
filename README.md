# Gamebox

Gamebox is a macOS bottle manager for an installed Wine runner. It creates isolated Windows prefixes (bottles), runs Windows installers and programs, opens Wine configuration and registry tools, and installs Steam from Valve's official installer. The GTA V Enhanced button opens its install page inside Steam (app ID `3240220`).

## Build and run

```sh
./scripts/build.sh
open dist/Gamebox.app
```

Requires macOS 14 or newer and Xcode Command Line Tools. This build targets Apple Silicon. Choose an executable Wine runner in Gamebox before creating a bottle. Gamebox stores bottles in `~/Library/Application Support/Gamebox/Bottles`.

## What this depends on

Gamebox does not bundle Wine, CrossOver, Steam, or GTA V. The selected runner must support Apple Silicon macOS and the Windows game you want to run. A standard Wine runner can be selected directly. CrossOver's bundled `wine` may require its own setup and licensing; compatibility of Gamebox-created prefixes with a CrossOver runner is unverified. For reliable CrossOver-specific bottle settings, use CrossOver's own bottle manager.

GTA V Enhanced is a demanding DirectX 12 game. The Steam install action is available, but successful gameplay has **not** been verified on this Mac; no runner or Steam installation was present during development. Anti-cheat and Rockstar account requirements may limit online play.

## Updates

Gamebox checks the latest release at `Sidhved-Pillai/Gamebox` on launch. When a newer version exists, **Update now** opens the release ZIP. It does not install the update automatically. The local build is ad hoc signed; a release intended for other Macs should be signed and notarized with an Apple Developer ID.

## Design and ownership

This is an independent app. It does not contain CodeWeavers' proprietary CrossOver UI or binaries and should not be presented as a renamed copy of CrossOver. The functional reference is the [CrossOver Mac guide](https://www.codeweavers.com/support/docs/crossover-mac/index); [Steam's GTA V Enhanced page](https://store.steampowered.com/app/3240220/) documents the game ID.
