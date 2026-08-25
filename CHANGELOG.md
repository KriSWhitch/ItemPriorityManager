# Changelog

## 0.2.0 - 2026-08-25

- Added 9 priority presets that save and load the full set of item priorities (`P` to open, digits to select, `S`/`X`/`D` to save, load, or clear a slot).
- Reset-all (`R`) now asks for `Y`/`N` confirmation before clearing priorities.

## 0.1.0 - 2026-08-17

- Added an in-game menu for unlocked vanilla active and passive collectibles.
- Added saved collectible priorities: `0.50x` decreased, `1.00x` default, and `1.50x` increased.
- Limited changed priorities to 20% of unlocked collectibles.
- Added item search, keyboard navigation, pagination, and reset-all controls.
- Applies each priority to the live item pool as `initialWeight * priorityMultiplier` at the start of a new run.
- Uses the game's normal item selection, pool depletion, and RNG after weights are applied.
- Skips continued runs and applies changes made during a run on the next new run.
- Requires REPENTOGON with the `SetCollectibleWeight` API.