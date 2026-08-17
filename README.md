# Item Priority Manager

Item Priority Manager is a Lua mod for The Binding of Isaac: Repentance+ that changes the relative appearance weight of unlocked collectibles without replacing the game's item-selection algorithm.

## Status

This project currently requires a custom REPENTOGON build. The required native API is supplied as the source patch in [native/repentogon-item-pool-weight-setter.patch](native/repentogon-item-pool-weight-setter.patch). A prebuilt DLL verified against REPENTOGON `1.1.2g` is included at `native/bin/zhlREPENTOGON.dll`; it is not part of an official REPENTOGON release.

## What It Does

- Shows unlocked vanilla active and passive collectibles in an in-game menu.
- Saves `0.50x` (decreased) and `1.50x` (increased) item priorities; unlisted items remain at `1.00x`.
- Limits changed items to `floor(unlocked collectibles / 5)`.
- On a new run, applies `initialWeight * priorityMultiplier` once to each live pool entry through the patched REPENTOGON API.
- Leaves item selection, pool depletion, and RNG to the game.

Priorities changed while a run is active apply on the next new run. Continued runs deliberately do not receive a second weight application.

## Manual Installation

This installation is for a developer or tester. Make backups before replacing runtime DLLs. Use one of the following native-runtime options, then deploy the Lua mod.

1. Install The Binding of Isaac: Repentance+ and install REPENTOGON through its official launcher.
2. Choose a native-runtime option:

   **Option A: use the included DLL.** This is the quickest local path. It is built for REPENTOGON `1.1.2g` and has SHA-256 `52B76E0AF261A573A07D0062A2352F104EDA17BF2B1517FBFEB069EB508CB96E`. Do not use it with a different REPENTOGON version.

   **Option B: build the patch yourself.** Obtain a complete REPENTOGON source checkout matching the installed runtime. From its source root, apply this repository's patch:

	```powershell
	git apply --ignore-space-change "path\to\Item-Priority-Manager\native\repentogon-item-pool-weight-setter.patch"
	```

   Build REPENTOGON using its Windows build instructions. Pass the resulting `zhlREPENTOGON.dll` to the launch helper with `-PatchedDllPath`.

3. Copy the patched DLL over REPENTOGON's runtime DLL, preserving a backup. With Option A, the helper uses `native/bin/zhlREPENTOGON.dll` by default and launches through the launcher:

	```powershell
	.\launch-patched-repentogon.ps1
	```

	Pass `-LauncherPath`, `-GamePath`, `-PatchedDllPath`, and `-TargetDllPath` when your installation is elsewhere. The launcher may overwrite the DLL during startup; the helper watches and restores the patched copy for the current launch.
4. Deploy the Lua mod to the game's `mods` directory:

	```powershell
	.\deploy-local.ps1 -GamePath "D:\SteamLibrary\steamapps\common\The Binding of Isaac Rebirth"
	```

5. Launch through REPENTOGON, enable **Item Priority Manager** in the in-game Mods menu, and start a new run. Isaac's log should contain `[Item Priority Manager] Applied priority multipliers`.

## Controls

- `I`: open or close the menu.
- Arrow keys or `WASD`: select an item.
- `Z` / `X`: decrease / increase priority.
- `Page Up` / `Page Down`: change page.
- `/`: search.
- `R`: reset all priorities.
- `Escape`: close the menu.

## Compatibility

See [COMPATIBILITY.md](COMPATIBILITY.md) for supported runtime details and known limitations. Native patch details and the API contract are in [native/README.md](native/README.md). Changes are recorded in [CHANGELOG.md](CHANGELOG.md).