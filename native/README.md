# Native REPENTOGON Patch

`repentogon-item-pool-weight-setter.patch` adds this Lua method to REPENTOGON:

```lua
Game():GetItemPool():SetCollectibleWeight(poolType, entryIndex, weight)
```

`entryIndex` is the one-based index returned by `GetCollectiblesFromPool(poolType)`. The method updates only that exact live entry's current `weight`. It preserves its collectible ID, `initialWeight`, `decreaseBy`, `removeOn`, unlock state, and all other pool entries.

## API Contract

- Only weights strictly greater than zero are accepted.
- The target pool and entry index are validated.
- Call this only before any item-pool selection in a new run.
- The Lua mod must calculate `entry.initialWeight * multiplier` once; it must never multiply an already-modified weight.

## Build and Install

This is a source patch, not a Workshop dependency. `bin/zhlREPENTOGON.dll` is the prebuilt patched runtime used for local verification. It was built against REPENTOGON `1.1.2g` and has SHA-256 `52B76E0AF261A573A07D0062A2352F104EDA17BF2B1517FBFEB069EB508CB96E`.

Use the bundled DLL only with REPENTOGON `1.1.2g`. For another version, apply this patch to a complete matching source checkout and compile with REPENTOGON's documented Windows build process.

From the REPENTOGON source root on Windows:

```powershell
git apply --ignore-space-change native/repentogon-item-pool-weight-setter.patch
```

Use an absolute path if this repository is outside the checkout. The option tolerates upstream Windows line-ending normalization without weakening the patch's code or validation.

Install the resulting `zhlREPENTOGON.dll` in the REPENTOGON runtime location, keeping a backup of the original. The root [README.md](../README.md) documents the helper script and full local installation path.

Do not redistribute the bundled custom DLL through Steam Workshop. The maintainable public distribution path is an upstream REPENTOGON release containing this API.