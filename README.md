# Recast Radar

**Author:** Ixis  
**Dependencies:** [LibAddonMenu-2.0](../LibAddonMenu-2.0), [LibZone](../LibZone)
**Optional:** [LibMediaProvider](../LibMediaProvider) adds its registered fonts to the font selector. [LibFoodDrinkBuff](../LibFoodDrinkBuff) enables food and drink timeout monitoring; those options are disabled when the library is not loaded.

## AI assistance disclaimer

This project was developed with assistance from AI tools. AI-generated suggestions were reviewed and adapted by the author, but users should verify behavior and report issues through the project repository. The author remains responsible for the final implementation.

Recast Radar tracks cooldowns, timed action-slot effects, and optional food and drink effects while monitoring is enabled. By default, when one expires during combat in an enabled zone, it displays `Recast: <icon> <skill name>` if the full timer meets the configured minimum. When combat begins, all active timers become combat countdowns, and their alerts still appear if they expire after combat ends. Timers that began before combat are tracked as well. Food and drink monitoring are enabled by default when LibFoodDrinkBuff is loaded and can be controlled independently. Arcanist characters can optionally monitor Crux: reaching three displays `Max crux ready` and plays the configured ready sound; dropping from three to below three plays the configured below-three sound once per transition. Uncheck **Show in combat only** to display all timer expirations outside combat.

Optional class and world-skill-line alerts are opt-in and initialize silently so logging in with a resource already ready does not produce a surprise alert:

- **Ultimate:** alerts when Ultimate reaches its current maximum, then waits until it is spent before alerting again.
- **Dragonknight:** alerts when Seething Fury reaches three stacks.
- **Nightblade:** alerts when Grim Focus, Merciless Resolve, or Relentless Focus reaches its spectral-bow threshold. The current Relentless Focus threshold is four stacks; the other two are five.
- **Sorcerer:** alerts when the Crystal Fragments instant-cast proc becomes available. It uses the effect event when available and an active-buff scan as a fallback.
- **Necromancer:** provides an approximate corpse estimate based on known generator and consumer combat events, with a configurable one-to-three-corpse alert threshold. Corpses can expire or be created by events the tracker cannot observe, so this is intentionally not presented as an exact count.
- **Werewolf:** alerts when Werewolf form starts and expires. The form transition is detected through the native `IsPlayerInWerewolfForm()` API.
- **Vampire:** alerts when the active Vampire stage changes or ends by scanning the current stage buff. Disable **Show in combat only** if stage changes outside combat should be displayed.

## Commands

- `/recastradar` opens the settings panel.
- `/recastradar on` enables monitoring.
- `/recastradar off` disables monitoring.
- `/recastradar move` toggles a visible, draggable move-mode block.

## Settings

The LibAddonMenu settings panel is organized into submenus similar to other larger ESO addons:

- **General:** enable monitoring, combat-only filtering, and the minimum timer duration.
- **Cooldowns and effects:** independent food and drink timeout monitoring.
- **Class resources and procs:** Ultimate, Dragonknight, Nightblade, Sorcerer, approximate Necromancer corpse, and Arcanist Crux alerts.
- **Werewolf and Vampire:** world skill-line state alerts.
- **Zones:** the zone types where alerts are enabled.
- **Alert appearance and position:** font, size, color, sounds, fade time, locking, and move mode.
- **Slotted skills:** the skills included in cooldown and timed-effect monitoring.

Choose **None** to mute any sound; when LibMediaProvider is installed, its registered sounds are also available. Selecting a sound previews it. Skill recast messages use the `Recast: <icon> <skill name>` format; food and drink messages use `Replenish: <icon> <name>`. Arcanist Crux displays `Max crux ready` when three are reached. All alerts fade individually after the configured display time. With **Show in combat only** enabled, all timers active when combat begins, plus timers started during combat, can still alert after combat ends. Food and drink options are grayed out when LibFoodDrinkBuff is not loaded; Dragonknight, Nightblade, Sorcerer, and Necromancer controls are grayed out when the relevant class is not active, and Crux controls are grayed out for non-Arcanists or when the Crux API is unavailable. The new class and world-skill-line trackers default to off; the existing Crux and food/drink defaults are unchanged. Use the **Toggle move mode** button or `/recastradar move` to keep a clearly visible Recast Radar block on screen; it starts centered horizontally with its top at one-third of the screen height, and expands to fit simultaneous alerts. Drag it to reposition, then toggle move mode off when finished.

During normal alerts, the display has no background; a small gold accent and stronger text shadow add a subtle highlight. The addon only observes cooldowns and displays text; it does not use skills or change action bars. Existing settings stored under the former `CooldownLapseMonitorSavedVariables` name are automatically migrated to `RecastRadarSavedVariables`.

If a tracked skill is cast again while its cooldown or timed effect is active, Recast Radar resets tracking to the new timer.
