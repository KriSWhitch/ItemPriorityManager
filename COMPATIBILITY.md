# Compatibility

## Required Runtime

- The Binding of Isaac: Repentance+.
- REPENTOGON `1.1.2g` with [the included native patch](native/repentogon-item-pool-weight-setter.patch) applied and built.
- A new run after the mod is enabled. The patched API must provide both `GetCollectiblesFromPool` and `SetCollectibleWeight`.

The standard Workshop Lua API cannot change an existing live item-pool entry's weight exactly. A normal REPENTOGON install without the patch is therefore unsupported.

## Behavior and Limits

- The mod writes `initialWeight * priorityMultiplier` once, before selection begins in a new run.
- Continued runs are skipped so existing runtime pool state is not reset or multiplied again.
- Preference changes take effect on the next new run.
- Interaction with Chaos, Sacred Orb, Glitched Crown, Tainted Lost, rerolls, and special item generation has not been fully verified.