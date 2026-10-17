# Recast Radar

**Author:** Ixis  
**Dependencies:** [LibAddonMenu-2.0](../LibAddonMenu-2.0), [LibZone](../LibZone)  
**Optional:** [LibMediaProvider](../LibMediaProvider) adds its registered fonts to the font selector.

Recast Radar watches abilities on both weapon bars while you are in combat. When an ability's non-global cooldown finishes, it displays `Recast <skill name>` for a few seconds if the ability's full cooldown meets the configured minimum.

## Commands

- `/recast` opens the settings panel.
- `/recast on` enables monitoring.
- `/recast off` disables monitoring.

## Settings

The LibAddonMenu settings panel lets you configure the minimum cooldown duration, the zone types where alerts are enabled, whether each currently slotted skill is included, alert font, size and color, and whether the alert can be moved. To reposition the alert, unlock it, show the preview, and drag the text. Lock it again when finished.

The alert itself has no background. The addon only observes cooldowns and displays text; it does not use skills or change action bars. Existing settings are retained under the legacy saved-variable name.
