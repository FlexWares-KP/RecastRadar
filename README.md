# Recast Radar

**Author:** Ixis  
**Dependencies:** [LibAddonMenu-2.0](../LibAddonMenu-2.0), [LibZone](../LibZone)  
**Optional:** [LibMediaProvider](../LibMediaProvider) adds its registered fonts to the font selector.

Recast Radar watches abilities on both weapon bars while you are in combat. When an ability's non-global cooldown finishes, it displays `Recast <skill name>` for a few seconds if the ability's full cooldown meets the configured minimum.

## Commands

- `/recastradar` opens the settings panel.
- `/recastradar on` enables monitoring.
- `/recastradar off` disables monitoring.
- `/recastradar move` toggles a visible, draggable move-mode block.

## Settings

The LibAddonMenu settings panel lets you configure the minimum cooldown duration, how long recast messages stay visible before fading, the zone types where alerts are enabled, whether each currently slotted skill is included, alert font, size and color, and whether the alert can be moved. Recast messages fade individually after the configured display time. Use the **Toggle move mode** button or `/recastradar move` to keep a clearly visible Recast Radar block on screen; it starts centered horizontally with its top at one-third of the screen height, and expands to fit simultaneous alerts. Drag it to reposition, then toggle move mode off when finished.

During normal alerts, the display has no background. The addon only observes cooldowns and displays text; it does not use skills or change action bars. Existing settings are retained under the legacy saved-variable name.
