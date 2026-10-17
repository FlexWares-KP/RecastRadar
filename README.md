# Recast Radar

**Author:** Ixis  
**Dependencies:** [LibAddonMenu-2.0](../LibAddonMenu-2.0), [LibZone](../LibZone)
**Optional:** [LibMediaProvider](../LibMediaProvider) adds its registered fonts to the font selector. [LibFoodDrinkBuff](../LibFoodDrinkBuff) enables food and drink timeout monitoring; those options are disabled when the library is not loaded.

## AI assistance disclaimer

This project was developed with assistance from AI tools. AI-generated suggestions were reviewed and adapted by the author, but users should verify behavior and report issues through the project repository. The author remains responsible for the final implementation.

Recast Radar tracks cooldowns, timed action-slot effects, and optional food and drink effects while monitoring is enabled. By default, when one expires during combat in an enabled zone, it displays `Recast: <icon> <skill name>` if the full timer meets the configured minimum. When combat begins, all active timers become combat countdowns, and their alerts still appear if they expire after combat ends. Timers that began before combat are tracked as well. Food and drink monitoring are enabled by default when LibFoodDrinkBuff is loaded and can be controlled independently. Uncheck **Show in combat only** to display all timer expirations outside combat.

## Commands

- `/recastradar` opens the settings panel.
- `/recastradar on` enables monitoring.
- `/recastradar off` disables monitoring.
- `/recastradar move` toggles a visible, draggable move-mode block.

## Settings

The LibAddonMenu settings panel lets you configure whether alerts are limited to combat, whether food and drink timeouts are monitored independently, the minimum cooldown or effect duration, how long recast messages stay visible before fading, the alert sound, the zone types where alerts are enabled, whether each currently slotted skill is included, alert font, size and color, and whether the alert can be moved. Choose **None** to mute alert sounds; when LibMediaProvider is installed, its registered sounds are also available. Selecting a sound previews it. Skill recast messages use the `Recast: <icon> <skill name>` format; food and drink messages use `Replenish: <icon> <name>`. All alerts fade individually after the configured display time. With **Show in combat only** enabled, all timers active when combat begins, plus timers started during combat, can still alert after combat ends. Food and drink options are grayed out when LibFoodDrinkBuff is not loaded. Use the **Toggle move mode** button or `/recastradar move` to keep a clearly visible Recast Radar block on screen; it starts centered horizontally with its top at one-third of the screen height, and expands to fit simultaneous alerts. Drag it to reposition, then toggle move mode off when finished.

During normal alerts, the display has no background; a small gold accent and stronger text shadow add a subtle highlight. The addon only observes cooldowns and displays text; it does not use skills or change action bars. Existing settings stored under the former `CooldownLapseMonitorSavedVariables` name are automatically migrated to `RecastRadarSavedVariables`.

If a tracked skill is cast again while its cooldown or timed effect is active, Recast Radar resets tracking to the new timer.
