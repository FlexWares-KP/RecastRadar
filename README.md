# Recast Radar

**Author:** Ixis  
**Dependencies:** [LibAddonMenu-2.0](../LibAddonMenu-2.0), [LibZone](../LibZone)  
**Optional:** [LibMediaProvider](../LibMediaProvider) adds its registered fonts to the font selector.

Recast Radar tracks cooldowns and timed action-slot effects on both weapon bars while monitoring is enabled. By default, when one expires during combat in an enabled zone, it displays `Recast <skill name>` if the full timer meets the configured minimum. Timers that began before combat are tracked as well. Uncheck **Show in combat only** to display timer expirations outside combat too.

## Commands

- `/recastradar` opens the settings panel.
- `/recastradar on` enables monitoring.
- `/recastradar off` disables monitoring.
- `/recastradar move` toggles a visible, draggable move-mode block.

## Settings

The LibAddonMenu settings panel lets you configure whether alerts are limited to combat, the minimum cooldown or effect duration, how long recast messages stay visible before fading, the alert sound, the zone types where alerts are enabled, whether each currently slotted skill is included, alert font, size and color, and whether the alert can be moved. Choose **None** to mute alert sounds; when LibMediaProvider is installed, its registered sounds are also available. Selecting a sound previews it. Recast messages fade individually after the configured display time. Use the **Toggle move mode** button or `/recastradar move` to keep a clearly visible Recast Radar block on screen; it starts centered horizontally with its top at one-third of the screen height, and expands to fit simultaneous alerts. Drag it to reposition, then toggle move mode off when finished.

During normal alerts, the display has no background; a small gold accent and stronger text shadow add a subtle highlight. The addon only observes cooldowns and displays text; it does not use skills or change action bars. Existing settings stored under the former `CooldownLapseMonitorSavedVariables` name are automatically migrated to `RecastRadarSavedVariables`.
