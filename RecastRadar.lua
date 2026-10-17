-- AI assistance disclaimer: This addon was developed with assistance from AI tools.
-- AI-generated suggestions were reviewed and adapted by the author; verify behavior
-- and report issues through the project repository.

local ADDON_NAME = "RecastRadar"
local PANEL_ID = ADDON_NAME .. "_Settings"
local SAVED_VARIABLES = "RecastRadarSavedVariables"
local LEGACY_SAVED_VARIABLES = "CooldownLapseMonitorSavedVariables"
local UPDATE_NAME = ADDON_NAME .. "_Update"
local ALERT_FADE_DURATION_MS = 750
local POLL_INTERVAL_MS = 100
local COOLDOWN_RESET_TOLERANCE_MS = POLL_INTERVAL_MS * 2
local MIN_OVERLAY_WIDTH = 700
local MAX_OVERLAY_WIDTH = 800
local MIN_OVERLAY_HEIGHT = 200
local OVERLAY_POSITION_VERSION = 2
local OVERLAY_PADDING = 20
local OVERLAY_LINE_HEIGHT_RATIO = 1.25
local SKILL_LIST_ICON_SIZE = 20
local FOOD_DRINK_TYPES = { "food", "drink" }
local FIRST_SKILL_SLOT = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1
local LAST_SKILL_SLOT = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
local HOTBARS = { HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP }
local FONT_DROPDOWN_REFERENCE = "RecastRadar_FontDropdown"
local SOUND_DROPDOWN_REFERENCE = "RecastRadar_SoundDropdown"
local CRUX_READY_SOUND_DROPDOWN_REFERENCE = "RecastRadar_CruxReadySoundDropdown"
local CRUX_BELOW_THREE_SOUND_DROPDOWN_REFERENCE = "RecastRadar_CruxBelowThreeSoundDropdown"
local NO_ALERT_SOUND = "None"
local DEFAULT_ALERT_SOUND = "Recast Radar Swish"
local DEFAULT_CRUX_READY_SOUND = "Crux ready gong"
local DEFAULT_CRUX_BELOW_THREE_SOUND = "Crux below three"
local DRAGONKNIGHT_CLASS_ID = 1
local SORCERER_CLASS_ID = 2
local NIGHTBLADE_CLASS_ID = 3
local NECROMANCER_CLASS_ID = 6
local ARCANIST_CLASS_ID = 117
local MAX_CRUX = 3
local CRUX_BUFF_ID = 184220
local LEGACY_ARCANIST_CLASS_ID = 7
local MAX_SEETHING_FURY_STACKS = 3
local NECROMANCER_CORPSE_LIFETIME_MS = 16000
local CRUX_BUFF_IDS = {
    [CRUX_BUFF_ID] = true,
}
local CRYSTAL_FRAGMENTS_PASSIVE_ID = 46327
local CRYSTAL_FRAGMENTS_BUFF_IDS = {
    [46327] = true,
    [46324] = true,
    [114716] = true,
}
local SEETHING_FURY_BUFF_IDS = {
    [122729] = true,
    [122658] = true,
}
local VAMPIRE_STAGE_IDS = {
    [135397] = 1,
    [135399] = 2,
    [135400] = 3,
    [135402] = 4,
    [135412] = 5,
}
local WEREWOLF_RAMPAGE_BUFF_IDS = {
    [266377] = true,
    [266523] = true,
    [266524] = true,
    [267416] = true,
    [267417] = true,
    [267418] = true,
    [267425] = true,
    [267426] = true,
    [267427] = true,
    [267428] = true,
}
local NIGHTBLADE_PROC_DATA = {
    [122585] = {
        name = "Grim Focus ready",
        skillId = 61902,
        threshold = 5,
        buffIds = { [122585] = true, [61905] = true },
    },
    [122586] = {
        name = "Merciless Resolve ready",
        skillId = 61919,
        threshold = 5,
        buffIds = { [122586] = true, [61920] = true },
    },
    [122587] = {
        name = "Relentless Focus ready",
        skillId = 61927,
        threshold = 4,
        buffIds = { [122587] = true, [61928] = true },
    },
}
local NECROMANCER_CORPSE_GENERATORS = {
    [117926] = true,
    [122385] = true,
    [122390] = true,
    [117967] = true,
    [122364] = true,
    [122359] = true,
    [117972] = true,
    [122374] = true,
    [122371] = true,
}
local NECROMANCER_CORPSE_CONSUMERS = {
    [116445] = true,
    [118009] = true,
    [118764] = true,
    [116450] = true,
    [118123] = true,
    [118071] = true,
    [118639] = true,
}

local BUILTIN_ALERT_SOUNDS = {
    { name = DEFAULT_ALERT_SOUND, sound = SOUNDS.DEATH_RECAP_KILLING_BLOW_SHOWN },
    { name = DEFAULT_CRUX_READY_SOUND, sound = SOUNDS.OBJECTIVE_DISCOVERED },
    { name = DEFAULT_CRUX_BELOW_THREE_SOUND, sound = SOUNDS.ABILITY_NOT_READY },
    { name = "Soft notification", sound = SOUNDS.TUTORIAL_INFO_SHOWN },
    { name = "Book acquired", sound = SOUNDS.BOOK_ACQUIRED },
}

local DEFAULTS = {
    enabled = true,
    showInCombatOnly = true,
    monitorFood = true,
    monitorDrink = true,
    monitorCrux = true,
    monitorUltimate = false,
    monitorSeethingFury = false,
    monitorNightblade = false,
    monitorCrystalFragments = false,
    monitorNecromancerCorpses = false,
    monitorWerewolf = false,
    monitorVampire = false,
    necromancerCorpseThreshold = 1,
    minimumCooldownSeconds = 10,
    zones = {
        openWorld = true,
        dungeons = true,
        trials = true,
        battlegrounds = true,
        cyrodiil = true,
    },
    skills = {},
    fontSize = 26,
    fontColor = { r = 1, g = 1, b = 1, a = 1 },
    alertDisplaySeconds = 3.5,
    alertSound = DEFAULT_ALERT_SOUND,
    cruxReadySound = DEFAULT_CRUX_READY_SOUND,
    cruxBelowThreeSound = DEFAULT_CRUX_BELOW_THREE_SOUND,
    locked = true,
    positionX = 0,
    positionY = 0,
}

local SYSTEM_FONTS = {
    { name = "System - Medium", path = "$(MEDIUM_FONT)" },
    { name = "System - Bold", path = "$(BOLD_FONT)" },
    { name = "System - Chat", path = "$(CHAT_FONT)" },
    { name = "System - Gamepad", path = "$(GAMEPAD_MEDIUM_FONT)" },
}

local ZONE_OPTIONS = {
    { key = "openWorld", name = "Open world" },
    { key = "dungeons", name = "Dungeons" },
    { key = "trials", name = "Trials" },
    { key = "battlegrounds", name = "Battlegrounds" },
    { key = "cyrodiil", name = "Cyrodiil" },
}

local addon = {
    settings = nil,
    inCombat = false,
    cooldowns = {},
    foodDrink = {
        food = nil,
        drink = nil,
    },
    lastAlertAt = {},
    alerts = {},
    skillRows = {},
    alertLabels = {},
    fontChoices = {},
    fontOption = nil,
    alertSoundOption = nil,
    cruxReadySoundOption = nil,
    cruxBelowThreeSoundOption = nil,
    cruxCount = nil,
    ultimateReady = nil,
    seethingFuryStacks = nil,
    nightbladeStacks = {},
    crystalFragmentsReady = nil,
    crystalFragmentsEventSeen = false,
    necromancerCorpses = {},
    necromancerCorpseReady = nil,
    lastNecromancerEventAt = {},
    werewolfForm = nil,
    vampireStage = nil,
    moveMode = false,
    panel = nil,
    skillsControl = nil,
    overlay = nil,
    overlayBackdrop = nil,
    overlayAccent = nil,
    overlaySceneFragment = nil,
    overlayLabel = nil,
    cachedZoneId = nil,
    cachedZoneType = nil,
}

local CreateOverlay

local function GetCurrentZoneType()
    if LibZone:IsInBattleground() then
        return "battlegrounds"
    end
    if LibZone:IsInCyrodiil() then
        return "cyrodiil"
    end

    local zoneIndex = GetUnitZoneIndex("player")
    local zoneId = zoneIndex and GetZoneId(zoneIndex) or 0
    if zoneId == addon.cachedZoneId then
        return addon.cachedZoneType
    end

    local zoneType
    if LibZone:IsInTrial() then
        zoneType = "trials"
    elseif LibZone:IsInAnyDungeon() then
        zoneType = "dungeons"
    else
        zoneType = "openWorld"
    end

    addon.cachedZoneId = zoneId
    addon.cachedZoneType = zoneType
    return zoneType
end

local function IsCurrentZoneEnabled()
    return addon.settings.zones[GetCurrentZoneType()] ~= false
end

local function GetSkillName(slotIndex, hotbarCategory)
    local name = GetSlotName(slotIndex, hotbarCategory)
    if type(name) ~= "string" or name == "" then
        return nil
    end
    return name
end

local function GetIconMarkup(icon, size)
    if type(icon) ~= "string" or icon == "" then
        return ""
    end
    return string.format("|t%d:%d:%s|t ", size, size, icon)
end

local function GetAbilityIconMarkup(abilityId, size)
    return GetIconMarkup(GetAbilityIcon(abilityId), size)
end

local function BuildFontChoices()
    local choices = {}
    local seen = {}
    local mediaProvider = LibMediaProvider

    if mediaProvider and mediaProvider.MediaType and mediaProvider.MediaType.FONT then
        local mediaType = mediaProvider.MediaType.FONT
        for _, name in ipairs(mediaProvider:List(mediaType) or {}) do
            local path = mediaProvider:Fetch(mediaType, name)
            if path and not seen[name] then
                seen[name] = true
                table.insert(choices, { name = name, path = path })
            end
        end
    end

    for _, font in ipairs(SYSTEM_FONTS) do
        if not seen[font.name] then
            seen[font.name] = true
            table.insert(choices, font)
        end
    end

    table.sort(choices, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return choices
end

local function GetFontNames()
    local names = {}
    for index, font in ipairs(addon.fontChoices) do
        names[index] = font.name
    end
    return names
end

local function GetFontPathByName(name)
    for _, font in ipairs(addon.fontChoices) do
        if font.name == name then
            return font.path
        end
    end
end

local function GetFontPath()
    return GetFontPathByName(addon.settings.fontName) or SYSTEM_FONTS[1].path
end

local function GetFontPreviewDescriptor(name)
    local path = GetFontPathByName(name)
    if path then
        return string.format("%s|18|soft-shadow-thin", path)
    end
end

local function ApplyFontDropdownEntryFont(_, labelControl, rowData)
    local item = rowData and rowData.GetDataSource and rowData:GetDataSource()
    local dropdownControl = _G[FONT_DROPDOWN_REFERENCE]
    if not item or not dropdownControl or item.control ~= dropdownControl then
        return
    end

    local font = GetFontPreviewDescriptor(item.name)
    if font then
        labelControl:SetFont(font)
    end
end

local function ApplyFontDropdownSelectedFont(comboBox, item)
    local dropdownControl = _G[FONT_DROPDOWN_REFERENCE]
    if not item or not dropdownControl or comboBox ~= dropdownControl.dropdown then
        return
    end

    local font = GetFontPreviewDescriptor(item.value or item.name)
    if font then
        comboBox:SetSelectedItemFont(font)
    end
end

local function GetOverlayWidth()
    local rootWidth = GuiRoot:GetWidth()
    return math.max(
        1,
        math.min(rootWidth - 40, math.max(MIN_OVERLAY_WIDTH, math.min(MAX_OVERLAY_WIDTH, rootWidth * 0.5)))
    )
end

local function BuildAlertSoundChoices()
    local choices = { NO_ALERT_SOUND }
    local seen = { [NO_ALERT_SOUND] = true }

    for _, sound in ipairs(BUILTIN_ALERT_SOUNDS) do
        if not seen[sound.name] then
            seen[sound.name] = true
            table.insert(choices, sound.name)
        end
    end

    if LibMediaProvider then
        for _, name in ipairs(LibMediaProvider:List("sound") or {}) do
            if not seen[name] then
                seen[name] = true
                table.insert(choices, name)
            end
        end
    end

    table.sort(choices, function(left, right)
        if left == right then return false end
        if left == NO_ALERT_SOUND then return true end
        if right == NO_ALERT_SOUND then return false end
        return string.lower(left) < string.lower(right)
    end)
    return choices
end

local function IsAlertSoundChoice(name)
    for _, choice in ipairs(BuildAlertSoundChoices()) do
        if choice == name then
            return true
        end
    end
    return false
end

local function RefreshSoundChoices(option, reference, choices)
    if not option then
        return
    end

    option.choices = choices
    local control = _G[reference]
    if control and control.UpdateChoices then
        control:UpdateChoices(option.choices)
        control:UpdateValue()
    end
end

local function RefreshAlertSoundChoices()
    local choices = BuildAlertSoundChoices()
    RefreshSoundChoices(addon.alertSoundOption, SOUND_DROPDOWN_REFERENCE, choices)
    RefreshSoundChoices(addon.cruxReadySoundOption, CRUX_READY_SOUND_DROPDOWN_REFERENCE, choices)
    RefreshSoundChoices(addon.cruxBelowThreeSoundOption, CRUX_BELOW_THREE_SOUND_DROPDOWN_REFERENCE, choices)
end

local function PlayAlertSound(soundName)
    soundName = soundName or addon.settings.alertSound
    if soundName == NO_ALERT_SOUND then
        return
    end

    local sound
    if LibMediaProvider then
        sound = LibMediaProvider:Fetch("sound", soundName)
    end
    if not sound then
        for _, builtin in ipairs(BUILTIN_ALERT_SOUNDS) do
            if builtin.name == soundName then
                sound = builtin.sound
                break
            end
        end
    end
    if not sound then
        d(string.format("[Recast Radar] Could not find configured sound '%s'.", tostring(soundName)))
        return
    end
    PlaySound(sound)
end

local function RegisterBuiltinAlertSounds()
    if LibMediaProvider then
        for _, sound in ipairs(BUILTIN_ALERT_SOUNDS) do
            LibMediaProvider:Register("sound", sound.name, sound.sound)
        end
    end
end

local function RefreshFontChoices()
    addon.fontChoices = BuildFontChoices()
    if addon.fontOption then
        addon.fontOption.choices = GetFontNames()
        local control = _G[FONT_DROPDOWN_REFERENCE]
        if control and control.UpdateChoices then
            control:UpdateChoices(addon.fontOption.choices)
            control:UpdateValue()
        end
    end
end

local function IsSkillEnabled(abilityId)
    return addon.settings.skills[tostring(abilityId)] ~= false
end

local function IsFoodDrinkEnabled(timeoutType)
    if timeoutType == "food" then
        return addon.settings.monitorFood
    end
    return addon.settings.monitorDrink
end

local function IsFoodDrinkAvailable()
    return type(LIB_FOOD_DRINK_BUFF) == "table"
        and type(LIB_FOOD_DRINK_BUFF.GetFoodBuffInfos) == "function"
end

local function IsClass(globalClassName, fallbackClassId)
    if type(GetUnitClassId) ~= "function" then
        return false
    end

    local classId = GetUnitClassId("player")
    local expectedClassId = type(_G[globalClassName]) == "number" and _G[globalClassName] or fallbackClassId
    return classId == expectedClassId
end

local function IsArcanist()
    if type(GetUnitClassId) ~= "function" then
        return false
    end

    local classId = GetUnitClassId("player")
    local configuredClassId = type(_G.CLASS_ID_ARCANIST) == "number" and _G.CLASS_ID_ARCANIST or ARCANIST_CLASS_ID
    return classId == configuredClassId
        or classId == ARCANIST_CLASS_ID
        or classId == LEGACY_ARCANIST_CLASS_ID
end

local function IsDragonknight()
    return IsClass("CLASS_ID_DRAGONKNIGHT", DRAGONKNIGHT_CLASS_ID)
end

local function IsSorcerer()
    return IsClass("CLASS_ID_SORCERER", SORCERER_CLASS_ID)
end

local function IsNightblade()
    return IsClass("CLASS_ID_NIGHTBLADE", NIGHTBLADE_CLASS_ID)
end

local function IsNecromancer()
    return IsClass("CLASS_ID_NECROMANCER", NECROMANCER_CLASS_ID)
end

local function IsCruxAvailable()
    return IsArcanist()
        and type(GetNumBuffs) == "function"
        and type(GetUnitBuffInfo) == "function"
end

local function GetPlayerBuffByIds(abilityIds)
    if type(GetNumBuffs) ~= "function" or type(GetUnitBuffInfo) ~= "function" then
        return nil
    end

    for buffIndex = 1, GetNumBuffs("player") do
        local buffName, timeStarted, timeEnding, buffSlot, stackCount, icon, _, effectType, abilityType,
            statusEffectType, abilityId = GetUnitBuffInfo("player", buffIndex)
        if abilityIds[abilityId] then
            return {
                abilityId = abilityId,
                name = buffName,
                timeStarted = timeStarted,
                timeEnding = timeEnding,
                stackCount = tonumber(stackCount) or 0,
                icon = icon,
            }
        end
    end
end

local function CanShowResourceAlert(zoneEnabled)
    return zoneEnabled and (not addon.settings.showInCombatOnly or addon.inCombat)
end

local function AddAlert(alertKey, displayName, now, icon, prefix, soundName)
    local previousAlert = addon.lastAlertAt[alertKey]
    if previousAlert and now - previousAlert < 1000 then
        return
    end

    local alertPrefix = prefix or "Recast: "
    addon.lastAlertAt[alertKey] = now
    table.insert(addon.alerts, {
        text = alertPrefix .. displayName,
        name = displayName,
        icon = icon,
        prefix = alertPrefix,
        shownAt = now,
    })
    PlayAlertSound(soundName)
end

local function GetAlertDisplayText(alert, fontSize)
    if type(alert.icon) ~= "string" or alert.icon == "" or not alert.name then
        return alert.text
    end

    local iconSize = math.max(12, math.min(fontSize, 32))
    return string.format("%s%s%s", alert.prefix or "Recast: ", GetIconMarkup(alert.icon, iconSize), alert.name)
end

local function RefreshOverlay(now)
    local activeAlerts = {}
    for index = #addon.alerts, 1, -1 do
        local alert = addon.alerts[index]
        local fadeStartsAt = alert.shownAt + addon.settings.alertDisplaySeconds * 1000
        local expiresAt = fadeStartsAt + ALERT_FADE_DURATION_MS
        if expiresAt <= now then
            table.remove(addon.alerts, index)
        else
            local alpha = 1
            if now >= fadeStartsAt then
                alpha = 1 - (now - fadeStartsAt) / ALERT_FADE_DURATION_MS
            end
            table.insert(activeAlerts, 1, {
                text = alert.text,
                name = alert.name,
                icon = alert.icon,
                prefix = alert.prefix,
                alpha = alpha,
            })
        end
    end

    if addon.moveMode then
        table.insert(activeAlerts, 1, { text = "Recast Radar", alpha = 1, isTitle = true })
    end

    local rootHeight = GuiRoot:GetHeight()
    local width = GetOverlayWidth()
    local lineCount = math.max(1, #activeAlerts)
    local availableHeight = math.max(1, rootHeight - addon.settings.positionY - 20)
    local longestLine = 0
    for _, alert in ipairs(activeAlerts) do
        local visibleLength = #alert.text + (alert.icon and 2 or 0)
        longestLine = math.max(longestLine, visibleLength)
    end

    local maxFontForWidth = longestLine > 0 and math.floor((width - OVERLAY_PADDING * 2) / (longestLine * 0.6)) or 64
    local maxFontForHeight = math.floor((availableHeight - OVERLAY_PADDING * 2) / (lineCount * OVERLAY_LINE_HEIGHT_RATIO))
    local fontSize = math.max(12, math.min(addon.settings.fontSize, maxFontForWidth, maxFontForHeight))
    local lineHeight = math.ceil(fontSize * OVERLAY_LINE_HEIGHT_RATIO)
    local height = math.min(
        availableHeight,
        math.max(MIN_OVERLAY_HEIGHT, OVERLAY_PADDING * 2 + lineCount * lineHeight)
    )

    addon.overlay:SetDimensions(width, height)
    local displayedAlertCount = #activeAlerts - (addon.moveMode and 1 or 0)
    addon.overlayAccent:ClearAnchors()
    addon.overlayAccent:SetAnchor(
        TOPLEFT,
        addon.overlay,
        TOPLEFT,
        OVERLAY_PADDING / 2,
        OVERLAY_PADDING + (addon.moveMode and lineHeight or 0)
    )
    addon.overlayAccent:SetDimensions(4, math.max(1, displayedAlertCount * lineHeight))
    addon.overlayAccent:SetHidden(addon.moveMode or displayedAlertCount == 0)
    addon.overlayLabel:SetDimensions(width - OVERLAY_PADDING * 2, lineHeight)
    addon.overlayLabel:SetFont(string.format("%s|%d|soft-shadow-thick", GetFontPath(), fontSize))
    addon.overlayLabel:SetHidden(not addon.moveMode)
    local color = addon.settings.fontColor
    for index, alert in ipairs(activeAlerts) do
        local label
        if alert.isTitle then
            label = addon.overlayLabel
            label:ClearAnchors()
            label:SetAnchor(TOP, addon.overlay, TOP, 0, OVERLAY_PADDING)
        else
            label = addon.alertLabels[index]
            if not label then
                label = WINDOW_MANAGER:CreateControl(nil, addon.overlay, CT_LABEL)
                label:SetDrawTier(DT_HIGH)
                label:SetDrawLayer(DL_OVERLAY)
                label:SetDrawLevel(102)
                label:SetMouseEnabled(false)
                label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
                label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
                addon.alertLabels[index] = label
            end
            label:ClearAnchors()
            local titleOffset = addon.moveMode and lineHeight or 0
            local alertIndex = index - (addon.moveMode and 1 or 0)
            label:SetAnchor(TOP, addon.overlay, TOP, 0, OVERLAY_PADDING + titleOffset + (alertIndex - 1) * lineHeight)
        end
        label:SetDimensions(width - OVERLAY_PADDING * 2, lineHeight)
        label:SetFont(string.format("%s|%d|soft-shadow-thick", GetFontPath(), fontSize))
        label:SetText(alert.isTitle and alert.text or GetAlertDisplayText(alert, fontSize))
        label:SetColor(color.r, color.g, color.b, (color.a or 1) * alert.alpha)
        label:SetHidden(false)
    end
    for index = 1, #addon.alertLabels do
        if not activeAlerts[index] or activeAlerts[index].isTitle then
            addon.alertLabels[index]:SetHidden(true)
        end
    end

    local canMove = addon.moveMode and not addon.settings.locked
    if addon.moveMode then
        addon.overlayBackdrop:SetCenterColor(0.035, 0.04, 0.07, 0.9)
        addon.overlayBackdrop:SetEdgeColor(1, 0.78, 0.2, 1)
    else
        addon.overlayBackdrop:SetCenterColor(0, 0, 0, 0)
        addon.overlayBackdrop:SetEdgeColor(0, 0, 0, 0)
    end
    addon.overlay:SetMouseEnabled(canMove)
    addon.overlay:SetMovable(canMove)
    addon.overlay:SetHidden(not addon.moveMode and #activeAlerts == 0)
end

local function ToggleMoveMode()
    addon.moveMode = not addon.moveMode
    if addon.moveMode then
        SCENE_MANAGER:AddFragment(addon.overlaySceneFragment)
        addon.settings.locked = false
    end
    RefreshOverlay(GetGameTimeMilliseconds())
    d(string.format("[Recast Radar] Move mode %s.", addon.moveMode and "enabled" or "disabled"))
end

local function StartMovingOverlay(control)
    if addon.moveMode and not addon.settings.locked then
        control:StartMoving()
    end
end

local function TrackCooldown(slotIndex, hotbarCategory, now, zoneEnabled)
    local abilityId = GetSlotBoundId(slotIndex, hotbarCategory)
    local skillName = GetSkillName(slotIndex, hotbarCategory)
    local key = tostring(hotbarCategory) .. ":" .. tostring(slotIndex)
    local previous = addon.cooldowns[key]

    if not abilityId or abilityId == 0 or not skillName then
        addon.cooldowns[key] = nil
        return
    end

    local remaining, duration, isGlobal = GetSlotCooldownInfo(slotIndex, hotbarCategory)
    local effectDuration = GetActionSlotEffectDuration(slotIndex, hotbarCategory) or 0
    local effectRemaining = GetActionSlotEffectTimeRemaining(slotIndex, hotbarCategory) or 0
    local cooldownActive = remaining > 0 and not isGlobal
    local effectActive = effectDuration > 0 and effectRemaining > 0
    local isCoolingDown = cooldownActive or effectActive
    local observedDuration = math.max(cooldownActive and duration or 0, effectActive and effectDuration or 0)
    local observedRemaining = math.max(cooldownActive and remaining or 0, effectActive and effectRemaining or 0)
    if not previous or previous.abilityId ~= abilityId then
        addon.cooldowns[key] = {
            abilityId = abilityId,
            wasCoolingDown = isCoolingDown,
            remaining = observedRemaining,
            duration = observedDuration,
            cooldownRemaining = cooldownActive and remaining or 0,
            effectRemaining = effectActive and effectRemaining or 0,
            combatCountdown = isCoolingDown and addon.inCombat or false,
        }
        return
    end

    if isCoolingDown then
        local previousCooldownRemaining = previous.cooldownRemaining or 0
        local previousEffectRemaining = previous.effectRemaining or 0
        local cooldownWasReset = previous.wasCoolingDown
            and cooldownActive
            and previousCooldownRemaining > 0
            and remaining > previousCooldownRemaining + COOLDOWN_RESET_TOLERANCE_MS
        local effectWasReset = previous.wasCoolingDown
            and effectActive
            and previousEffectRemaining > 0
            and effectRemaining > previousEffectRemaining + COOLDOWN_RESET_TOLERANCE_MS
        local wasReset = cooldownWasReset or effectWasReset

        if not previous.wasCoolingDown or wasReset then
            previous.combatCountdown = addon.inCombat
        end
        previous.wasCoolingDown = true
        previous.remaining = observedRemaining
        previous.cooldownRemaining = cooldownActive and remaining or 0
        previous.effectRemaining = effectActive and effectRemaining or 0
        if wasReset then
            previous.duration = observedDuration
            addon.lastAlertAt[abilityId] = nil
        else
            previous.duration = math.max(previous.duration, observedDuration)
        end
        return
    end

    if previous.wasCoolingDown and previous.remaining > 0
        and previous.duration >= addon.settings.minimumCooldownSeconds * 1000
        and (not addon.settings.showInCombatOnly or addon.inCombat or previous.combatCountdown)
        and zoneEnabled and IsSkillEnabled(abilityId) then
        AddAlert(abilityId, skillName, now, GetAbilityIcon(abilityId))
    end

    previous.wasCoolingDown = false
    previous.remaining = 0
    previous.duration = 0
    previous.cooldownRemaining = 0
    previous.effectRemaining = 0
    previous.combatCountdown = false
end

local function AddFoodDrinkExpiryAlert(timeoutType, timeout, now, nowSeconds, zoneEnabled)
    if timeout.timeEnding > nowSeconds
        or timeout.durationMilliseconds < addon.settings.minimumCooldownSeconds * 1000
        or (addon.settings.showInCombatOnly and not addon.inCombat and not timeout.combatCountdown)
        or not zoneEnabled then
        return
    end

    local alertKey = timeoutType .. ":" .. tostring(timeout.abilityId)
    AddAlert(alertKey, timeout.name, now, timeout.icon, "Replenish: ")
end

local function TrackFoodDrink(now, zoneEnabled)
    if not IsFoodDrinkAvailable() then
        addon.foodDrink.food = nil
        addon.foodDrink.drink = nil
        return
    end

    local nowSeconds = now / 1000
    local buffType, isDrink, abilityId, buffName, timeStarted, timeEnding, iconTexture =
        LIB_FOOD_DRINK_BUFF:GetFoodBuffInfos("player")
    local currentType
    if buffType and buffType ~= 0
        and type(isDrink) == "boolean"
        and type(abilityId) == "number"
        and type(buffName) == "string"
        and buffName ~= ""
        and type(timeEnding) == "number"
        and timeEnding > nowSeconds then
        currentType = isDrink and "drink" or "food"
    end

    for _, timeoutType in ipairs(FOOD_DRINK_TYPES) do
        local previous = addon.foodDrink[timeoutType]
        if not IsFoodDrinkEnabled(timeoutType) then
            addon.foodDrink[timeoutType] = nil
        elseif timeoutType == currentType then
            if not previous or previous.abilityId ~= abilityId or previous.timeEnding ~= timeEnding then
                if previous then
                    AddFoodDrinkExpiryAlert(timeoutType, previous, now, nowSeconds, zoneEnabled)
                end
                local durationMilliseconds = 0
                if type(timeStarted) == "number" and timeEnding > timeStarted then
                    durationMilliseconds = (timeEnding - timeStarted) * 1000
                end
                addon.foodDrink[timeoutType] = {
                    abilityId = abilityId,
                    name = buffName,
                    icon = iconTexture,
                    timeEnding = timeEnding,
                    durationMilliseconds = durationMilliseconds,
                    combatCountdown = addon.inCombat,
                }
            else
                previous.name = buffName
                previous.icon = iconTexture
            end
        elseif previous then
            addon.foodDrink[timeoutType] = nil
            AddFoodDrinkExpiryAlert(timeoutType, previous, now, nowSeconds, zoneEnabled)
        end
    end
end

local function TrackUltimate(now, zoneEnabled)
    if not addon.settings.monitorUltimate
        or type(GetUnitPower) ~= "function"
        or type(_G.COMBAT_MECHANIC_FLAGS_ULTIMATE) ~= "number" then
        addon.ultimateReady = nil
        return
    end

    local current, maximum, effectiveMaximum =
        GetUnitPower("player", _G.COMBAT_MECHANIC_FLAGS_ULTIMATE)
    local threshold = tonumber(effectiveMaximum) or 0
    if threshold <= 0 then
        threshold = tonumber(maximum) or 0
    end
    if threshold <= 0 or type(current) ~= "number" then
        addon.ultimateReady = nil
        return
    end

    local isReady = current >= threshold
    local previousReady = addon.ultimateReady
    addon.ultimateReady = isReady
    if previousReady == nil or previousReady or not isReady or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    AddAlert("ultimate:ready", "Ultimate ready", now)
end

local function TrackSeethingFury(now, zoneEnabled)
    if not addon.settings.monitorSeethingFury or not IsDragonknight() then
        addon.seethingFuryStacks = nil
        return
    end

    local buff = GetPlayerBuffByIds(SEETHING_FURY_BUFF_IDS)
    local stacks = buff and math.max(0, math.floor(buff.stackCount)) or 0
    local previousStacks = addon.seethingFuryStacks
    addon.seethingFuryStacks = stacks
    if previousStacks == nil
        or previousStacks >= MAX_SEETHING_FURY_STACKS
        or stacks < MAX_SEETHING_FURY_STACKS
        or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    AddAlert(
        "seething-fury:ready",
        "Seething Fury ready",
        now,
        buff and buff.icon or GetAbilityIcon(20805)
    )
end

local function TrackNightblade(now, zoneEnabled)
    if not addon.settings.monitorNightblade or not IsNightblade() then
        addon.nightbladeStacks = {}
        return
    end

    for trackerId, tracker in pairs(NIGHTBLADE_PROC_DATA) do
        local buff = GetPlayerBuffByIds(tracker.buffIds)
        local stacks = buff and math.max(0, math.floor(buff.stackCount)) or 0
        local previousStacks = addon.nightbladeStacks[trackerId]
        addon.nightbladeStacks[trackerId] = stacks
        if previousStacks
            and previousStacks < tracker.threshold
            and stacks >= tracker.threshold
            and CanShowResourceAlert(zoneEnabled) then
            AddAlert(
                "nightblade:" .. tostring(trackerId),
                tracker.name,
                now,
                buff and buff.icon or GetAbilityIcon(tracker.skillId)
            )
        end
    end
end

local function UpdateCrystalFragmentsReady(isReady, now, zoneEnabled, icon)
    local previousReady = addon.crystalFragmentsReady
    addon.crystalFragmentsReady = isReady
    if previousReady == nil or previousReady or not isReady or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    AddAlert(
        "crystal-fragments:ready",
        "Crystal Fragments ready",
        now,
        icon or GetAbilityIcon(46324)
    )
end

local function TrackCrystalFragments(now, zoneEnabled)
    if not addon.settings.monitorCrystalFragments or not IsSorcerer() then
        addon.crystalFragmentsReady = nil
        addon.crystalFragmentsEventSeen = false
        return
    end

    local buff = GetPlayerBuffByIds(CRYSTAL_FRAGMENTS_BUFF_IDS)
    if buff then
        UpdateCrystalFragmentsReady(true, now, zoneEnabled, buff.icon)
    elseif not addon.crystalFragmentsEventSeen then
        UpdateCrystalFragmentsReady(false, now, zoneEnabled)
    end
end

local function PruneNecromancerCorpses(now)
    for index = #addon.necromancerCorpses, 1, -1 do
        if addon.necromancerCorpses[index] <= now then
            table.remove(addon.necromancerCorpses, index)
        end
    end
end

local function AddNecromancerCorpse(now)
    if #addon.necromancerCorpses < 3 then
        table.insert(addon.necromancerCorpses, now + NECROMANCER_CORPSE_LIFETIME_MS)
    end
end

local function ConsumeNecromancerCorpse()
    if #addon.necromancerCorpses > 0 then
        table.remove(addon.necromancerCorpses, 1)
    end
end

local function IsNamedNecromancerCorpseGenerator(abilityName)
    local lowerName = type(abilityName) == "string" and string.lower(abilityName) or ""
    return string.find(lowerName, "blastbones", 1, true)
        or string.find(lowerName, "skeletal", 1, true)
        or string.find(lowerName, "spirit mender", 1, true)
end

local function IsNamedNecromancerCorpseConsumer(abilityName)
    local lowerName = type(abilityName) == "string" and string.lower(abilityName) or ""
    return string.find(lowerName, "boneyard", 1, true)
        or string.find(lowerName, "siphon", 1, true)
        or string.find(lowerName, "tether", 1, true)
        or string.find(lowerName, "necrotic potency", 1, true)
end

local function OnCombatEvent(
    _,
    result,
    _,
    abilityName,
    _,
    _,
    _,
    sourceType,
    _,
    _,
    _,
    _,
    _,
    _,
    _,
    _,
    abilityId
)
    if not addon.settings
        or not addon.settings.monitorNecromancerCorpses
        or not IsNecromancer()
        or sourceType ~= COMBAT_UNIT_TYPE_PLAYER
        or result ~= ACTION_RESULT_BEGIN then
        return
    end

    local isGenerator = NECROMANCER_CORPSE_GENERATORS[abilityId] or IsNamedNecromancerCorpseGenerator(abilityName)
    local isConsumer = NECROMANCER_CORPSE_CONSUMERS[abilityId] or IsNamedNecromancerCorpseConsumer(abilityName)
    if not isGenerator and not isConsumer then
        return
    end

    local now = GetGameTimeMilliseconds()
    local eventKey = abilityId or abilityName
    if not eventKey then
        return
    end
    local previousEventAt = addon.lastNecromancerEventAt[eventKey]
    if previousEventAt and now - previousEventAt < 500 then
        return
    end
    addon.lastNecromancerEventAt[eventKey] = now

    if isGenerator then
        AddNecromancerCorpse(now)
    elseif isConsumer then
        ConsumeNecromancerCorpse()
    end
end

local function TrackNecromancerCorpses(now, zoneEnabled)
    if not addon.settings.monitorNecromancerCorpses or not IsNecromancer() then
        addon.necromancerCorpses = {}
        addon.necromancerCorpseReady = nil
        addon.lastNecromancerEventAt = {}
        return
    end

    PruneNecromancerCorpses(now)
    local threshold = math.max(1, math.min(3, math.floor(addon.settings.necromancerCorpseThreshold or 1)))
    local isReady = #addon.necromancerCorpses >= threshold
    local previousReady = addon.necromancerCorpseReady
    addon.necromancerCorpseReady = isReady
    if previousReady == nil or previousReady or not isReady or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    AddAlert(
        "necromancer:corpse",
        "Necromancer corpse available",
        now,
        GetAbilityIcon(117926)
    )
end

local function TrackWerewolf(now, zoneEnabled)
    if not addon.settings.monitorWerewolf or type(IsPlayerInWerewolfForm) ~= "function" then
        addon.werewolfForm = nil
        return
    end

    local inWerewolfForm = IsPlayerInWerewolfForm()
    local previousForm = addon.werewolfForm
    addon.werewolfForm = inWerewolfForm
    if previousForm == nil or previousForm == inWerewolfForm or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    if inWerewolfForm then
        local rampageBuff = GetPlayerBuffByIds(WEREWOLF_RAMPAGE_BUFF_IDS)
        AddAlert(
            "werewolf:started",
            "Werewolf form active",
            now,
            rampageBuff and rampageBuff.icon or GetAbilityIcon(32458)
        )
    else
        AddAlert("werewolf:ended", "Werewolf form expired", now)
    end
end

local function TrackVampire(now, zoneEnabled)
    if not addon.settings.monitorVampire then
        addon.vampireStage = nil
        return
    end

    local buff = GetPlayerBuffByIds(VAMPIRE_STAGE_IDS)
    local currentStage = buff and VAMPIRE_STAGE_IDS[buff.abilityId] or nil
    local previousStage = addon.vampireStage
    addon.vampireStage = currentStage
    if previousStage == nil or previousStage == currentStage or not CanShowResourceAlert(zoneEnabled) then
        return
    end

    if currentStage then
        AddAlert(
            "vampire:stage",
            "Vampire stage " .. tostring(currentStage),
            now,
            buff.icon
        )
    else
        AddAlert("vampire:stage-ended", "Vampire stage ended", now)
    end
end

local function OnEffectChanged(
    _,
    change,
    _,
    _,
    unitTag,
    _,
    _,
    _,
    icon,
    _,
    _,
    _,
    _,
    _,
    _,
    abilityId
)
    if not addon.settings
        or unitTag ~= "player"
        or abilityId ~= CRYSTAL_FRAGMENTS_PASSIVE_ID
        or not addon.settings.monitorCrystalFragments
        or not IsSorcerer() then
        return
    end

    addon.crystalFragmentsEventSeen = true
    local zoneEnabled = IsCurrentZoneEnabled()
    UpdateCrystalFragmentsReady(change ~= EFFECT_RESULT_FADED, GetGameTimeMilliseconds(), zoneEnabled, icon)
end

local function TrackCrux(now, zoneEnabled)
    if not addon.settings.monitorCrux or not IsCruxAvailable() then
        addon.cruxCount = nil
        return
    end

    local cruxBuff = GetPlayerBuffByIds(CRUX_BUFF_IDS)
    local currentCrux = cruxBuff and cruxBuff.stackCount or 0

    currentCrux = math.max(0, math.min(MAX_CRUX, math.floor(currentCrux)))
    local previousCrux = addon.cruxCount
    addon.cruxCount = currentCrux
    if previousCrux == nil or currentCrux == previousCrux then
        return
    end

    if not zoneEnabled or (addon.settings.showInCombatOnly and not addon.inCombat) then
        return
    end

    if previousCrux < MAX_CRUX and currentCrux == MAX_CRUX then
        AddAlert("crux:max", "Max crux ready", now, nil, "", addon.settings.cruxReadySound)
    elseif previousCrux == MAX_CRUX and currentCrux < MAX_CRUX then
        PlayAlertSound(addon.settings.cruxBelowThreeSound)
    end
end

local function PollCooldowns()
    if not addon.settings.enabled then
        return
    end

    local zoneEnabled = IsCurrentZoneEnabled()
    if not zoneEnabled then
        addon.alerts = {}
    end

    local now = GetGameTimeMilliseconds()
    for _, hotbarCategory in ipairs(HOTBARS) do
        for slotIndex = FIRST_SKILL_SLOT, LAST_SKILL_SLOT do
            TrackCooldown(slotIndex, hotbarCategory, now, zoneEnabled)
        end
    end
    TrackFoodDrink(now, zoneEnabled)
    TrackUltimate(now, zoneEnabled)
    TrackSeethingFury(now, zoneEnabled)
    TrackNightblade(now, zoneEnabled)
    TrackCrystalFragments(now, zoneEnabled)
    TrackNecromancerCorpses(now, zoneEnabled)
    TrackWerewolf(now, zoneEnabled)
    TrackVampire(now, zoneEnabled)
    TrackCrux(now, zoneEnabled)
    RefreshOverlay(now)
end

local function RefreshMonitoring()
    if addon.settings.enabled then
        EVENT_MANAGER:RegisterForUpdate(UPDATE_NAME, POLL_INTERVAL_MS, PollCooldowns)
    else
        EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAME)
        addon.cooldowns = {}
        addon.foodDrink = {
            food = nil,
            drink = nil,
        }
        addon.cruxCount = nil
        addon.ultimateReady = nil
        addon.seethingFuryStacks = nil
        addon.nightbladeStacks = {}
        addon.crystalFragmentsReady = nil
        addon.crystalFragmentsEventSeen = false
        addon.necromancerCorpses = {}
        addon.necromancerCorpseReady = nil
        addon.lastNecromancerEventAt = {}
        addon.werewolfForm = nil
        addon.vampireStage = nil
    end

    if not addon.settings.enabled or (addon.settings.showInCombatOnly and not addon.inCombat) then
        addon.alerts = {}
    end
    RefreshOverlay(GetGameTimeMilliseconds())
end

local function GatherSlottedSkills()
    local found = {}
    local skills = {}
    for _, hotbarCategory in ipairs(HOTBARS) do
        for slotIndex = FIRST_SKILL_SLOT, LAST_SKILL_SLOT do
            local abilityId = GetSlotBoundId(slotIndex, hotbarCategory)
            local name = GetSkillName(slotIndex, hotbarCategory)
            if abilityId and abilityId > 0 and name and not found[abilityId] then
                found[abilityId] = true
                table.insert(skills, { id = abilityId, name = name })
            end
        end
    end
    table.sort(skills, function(left, right)
        return string.lower(left.name) < string.lower(right.name)
    end)
    return skills
end

local function RefreshSkillControls(control)
    if not control then
        return
    end

    local skills = GatherSlottedSkills()
    for index, skill in ipairs(skills) do
        local row = addon.skillRows[index]
        if not row then
            row = WINDOW_MANAGER:CreateControl(nil, control, CT_BUTTON)
            row:SetFont("ZoFontGame")
            row:SetHandler("OnClicked", function(button)
                local key = tostring(button.abilityId)
                if IsSkillEnabled(button.abilityId) then
                    addon.settings.skills[key] = false
                else
                    addon.settings.skills[key] = nil
                end
                RefreshSkillControls(control)
            end)
            addon.skillRows[index] = row
        end

        row.abilityId = skill.id
        row:ClearAnchors()
        row:SetAnchor(TOPLEFT, control, TOPLEFT, 0, (index - 1) * 26)
        row:SetDimensions(control:GetWidth(), 25)
        local enabled = IsSkillEnabled(skill.id)
        row:SetText((enabled and "[ON] " or "[OFF] ") .. GetAbilityIconMarkup(skill.id, SKILL_LIST_ICON_SIZE) .. skill.name)
        row:SetNormalFontColor(enabled and 0.65 or 0.6, enabled and 1 or 0.6, enabled and 0.65 or 0.6, 1)
        row:SetHidden(false)
    end

    for index = #skills + 1, #addon.skillRows do
        addon.skillRows[index]:SetHidden(true)
    end

    if not control.emptyLabel then
        control.emptyLabel = WINDOW_MANAGER:CreateControl(nil, control, CT_LABEL)
        control.emptyLabel:SetAnchor(TOPLEFT, control, TOPLEFT, 0, 0)
        control.emptyLabel:SetDimensions(control:GetWidth(), 26)
        control.emptyLabel:SetFont("ZoFontGame")
        control.emptyLabel:SetText("No skills are currently slotted.")
    end
    control.emptyLabel:SetHidden(#skills > 0)
    control:SetHeight(math.max(26, #skills * 26))
end

local function RegisterSettings()
    local library = LibAddonMenu2
    if not library or not LibZone then
        error("Recast Radar requires LibAddonMenu-2.0 and LibZone.")
    end

    addon.panel = library:RegisterAddonPanel(PANEL_ID, {
        type = "panel",
        name = "Recast Radar",
        displayName = "Recast Radar",
        author = "Ixis",
        version = "1.0.0",
        registerForRefresh = true,
        registerForDefaults = true,
    })
    RefreshFontChoices()

    addon.fontOption = {
        type = "dropdown",
        name = "Font type",
        tooltip = "Each font is previewed using its own typeface.",
        choices = GetFontNames(),
        scrollable = true,
        reference = FONT_DROPDOWN_REFERENCE,
        getFunc = function() return addon.settings.fontName end,
        setFunc = function(value)
            addon.settings.fontName = value
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = SYSTEM_FONTS[1].name,
    }
    addon.alertSoundOption = {
        type = "dropdown",
        name = "Alert sound",
        tooltip = "Choose the sound played when a Recast alert appears. Choose None to mute alerts.",
        choices = BuildAlertSoundChoices(),
        scrollable = 7,
        reference = SOUND_DROPDOWN_REFERENCE,
        getFunc = function() return addon.settings.alertSound end,
        setFunc = function(value)
            addon.settings.alertSound = value
            PlayAlertSound(value)
        end,
        default = DEFAULTS.alertSound,
    }

    local generalControls = {
        {
            type = "description",
            text = "Shows transparent alerts for monitored cooldowns, timed effects, consumables, and class mechanics.",
        },
        {
            type = "checkbox",
            name = "Enable monitoring",
            getFunc = function() return addon.settings.enabled end,
            setFunc = function(value)
                addon.settings.enabled = value
                RefreshMonitoring()
            end,
            default = DEFAULTS.enabled,
        },
        {
            type = "checkbox",
            name = "Show in combat only",
            tooltip = "When enabled, alerts appear for timers that finish during combat or are active when combat begins and finish afterward.",
            getFunc = function() return addon.settings.showInCombatOnly end,
            setFunc = function(value)
                addon.settings.showInCombatOnly = value
                if value then
                    addon.alerts = {}
                end
                RefreshMonitoring()
            end,
            default = DEFAULTS.showInCombatOnly,
        },
        {
            type = "slider",
            name = "Minimum cooldown or effect duration (seconds)",
            tooltip = "Only alert for monitored timers whose full duration meets this threshold.",
            min = 0,
            max = 120,
            step = 1,
            getFunc = function() return addon.settings.minimumCooldownSeconds end,
            setFunc = function(value) addon.settings.minimumCooldownSeconds = value end,
            default = DEFAULTS.minimumCooldownSeconds,
        },
    }

    local cooldownControls = {
        {
            type = "checkbox",
            name = "Monitor food timeouts",
            tooltip = "When enabled, show an alert when the active food effect expires. Requires LibFoodDrinkBuff.",
            disabled = function() return not IsFoodDrinkAvailable() end,
            getFunc = function() return addon.settings.monitorFood end,
            setFunc = function(value)
                addon.settings.monitorFood = value
                if not value then
                    addon.foodDrink.food = nil
                end
                RefreshMonitoring()
            end,
            default = DEFAULTS.monitorFood,
        },
        {
            type = "checkbox",
            name = "Monitor drink timeouts",
            tooltip = "When enabled, show an alert when the active drink effect expires. Requires LibFoodDrinkBuff.",
            disabled = function() return not IsFoodDrinkAvailable() end,
            getFunc = function() return addon.settings.monitorDrink end,
            setFunc = function(value)
                addon.settings.monitorDrink = value
                if not value then
                    addon.foodDrink.drink = nil
                end
                RefreshMonitoring()
            end,
            default = DEFAULTS.monitorDrink,
        },
    }

    addon.cruxReadySoundOption = {
        type = "dropdown",
        name = "Crux ready sound",
        tooltip = "Sound played when crux increases to three. Choose None to disable it.",
        choices = BuildAlertSoundChoices(),
        scrollable = 7,
        reference = CRUX_READY_SOUND_DROPDOWN_REFERENCE,
        disabled = function() return not IsCruxAvailable() end,
        getFunc = function() return addon.settings.cruxReadySound end,
        setFunc = function(value)
            addon.settings.cruxReadySound = value
            PlayAlertSound(value)
        end,
        default = DEFAULTS.cruxReadySound,
    }
    addon.cruxBelowThreeSoundOption = {
        type = "dropdown",
        name = "Crux below-three sound",
        tooltip = "Sound played once when crux drops from three to below three. Choose None to disable it.",
        choices = BuildAlertSoundChoices(),
        scrollable = 7,
        reference = CRUX_BELOW_THREE_SOUND_DROPDOWN_REFERENCE,
        disabled = function() return not IsCruxAvailable() end,
        getFunc = function() return addon.settings.cruxBelowThreeSound end,
        setFunc = function(value)
            addon.settings.cruxBelowThreeSound = value
            PlayAlertSound(value)
        end,
        default = DEFAULTS.cruxBelowThreeSound,
    }

    local classControls = {
        {
            type = "description",
            text = "Class alerts are opt-in. Each tracker initializes silently and alerts only when its ready threshold is crossed.",
        },
        {
            type = "checkbox",
            name = "Monitor Ultimate ready",
            tooltip = "Show an alert when Ultimate reaches its current maximum, once per charge.",
            getFunc = function() return addon.settings.monitorUltimate end,
            setFunc = function(value)
                addon.settings.monitorUltimate = value
                addon.ultimateReady = nil
            end,
            default = DEFAULTS.monitorUltimate,
        },
        {
            type = "checkbox",
            name = "Monitor Dragonknight Seething Fury",
            tooltip = "Show an alert when Seething Fury reaches three stacks.",
            disabled = function() return not IsDragonknight() end,
            getFunc = function() return addon.settings.monitorSeethingFury end,
            setFunc = function(value)
                addon.settings.monitorSeethingFury = value
                addon.seethingFuryStacks = nil
            end,
            default = DEFAULTS.monitorSeethingFury,
        },
        {
            type = "checkbox",
            name = "Monitor Nightblade Focus stacks",
            tooltip = "Show an alert when Grim Focus, Merciless Resolve, or Relentless Focus reaches its spectral-bow threshold.",
            disabled = function() return not IsNightblade() end,
            getFunc = function() return addon.settings.monitorNightblade end,
            setFunc = function(value)
                addon.settings.monitorNightblade = value
                addon.nightbladeStacks = {}
            end,
            default = DEFAULTS.monitorNightblade,
        },
        {
            type = "checkbox",
            name = "Monitor Sorcerer Crystal Fragments",
            tooltip = "Show an alert when the Crystal Fragments instant-cast proc becomes available.",
            disabled = function() return not IsSorcerer() end,
            getFunc = function() return addon.settings.monitorCrystalFragments end,
            setFunc = function(value)
                addon.settings.monitorCrystalFragments = value
                addon.crystalFragmentsReady = nil
                addon.crystalFragmentsEventSeen = false
            end,
            default = DEFAULTS.monitorCrystalFragments,
        },
        {
            type = "checkbox",
            name = "Monitor Necromancer corpse estimate",
            tooltip = "Estimate available corpses from known generator and consumer events. The estimate is approximate and may drift after missed or external events.",
            disabled = function() return not IsNecromancer() end,
            getFunc = function() return addon.settings.monitorNecromancerCorpses end,
            setFunc = function(value)
                addon.settings.monitorNecromancerCorpses = value
                addon.necromancerCorpses = {}
                addon.necromancerCorpseReady = nil
                addon.lastNecromancerEventAt = {}
            end,
            default = DEFAULTS.monitorNecromancerCorpses,
        },
        {
            type = "slider",
            name = "Necromancer corpse alert threshold",
            tooltip = "Alert when the estimated corpse count reaches this many corpses.",
            min = 1,
            max = 3,
            step = 1,
            disabled = function()
                return not IsNecromancer() or not addon.settings.monitorNecromancerCorpses
            end,
            getFunc = function() return addon.settings.necromancerCorpseThreshold end,
            setFunc = function(value)
                addon.settings.necromancerCorpseThreshold = value
                addon.necromancerCorpseReady = nil
            end,
            default = DEFAULTS.necromancerCorpseThreshold,
        },
        {
            type = "checkbox",
            name = "Monitor Arcanist Crux",
            tooltip = "When enabled for an Arcanist, show Max crux ready when three crux are available and play the configured threshold sounds.",
            disabled = function() return not IsCruxAvailable() end,
            getFunc = function() return addon.settings.monitorCrux end,
            setFunc = function(value)
                addon.settings.monitorCrux = value
                addon.cruxCount = nil
            end,
            default = DEFAULTS.monitorCrux,
        },
        addon.cruxReadySoundOption,
        addon.cruxBelowThreeSoundOption,
    }

    local worldControls = {
        {
            type = "description",
            text = "Werewolf form transitions and Vampire stage changes are optional. Disable Show in combat only if you want to see non-combat Vampire stage changes.",
        },
        {
            type = "checkbox",
            name = "Monitor Werewolf form changes",
            tooltip = "Show alerts when Werewolf form starts and expires.",
            getFunc = function() return addon.settings.monitorWerewolf end,
            setFunc = function(value)
                addon.settings.monitorWerewolf = value
                addon.werewolfForm = nil
            end,
            default = DEFAULTS.monitorWerewolf,
        },
        {
            type = "checkbox",
            name = "Monitor Vampire stage changes",
            tooltip = "Show alerts when the active Vampire stage changes or ends. This is an approximate skill-line state based on the player's stage buff.",
            getFunc = function() return addon.settings.monitorVampire end,
            setFunc = function(value)
                addon.settings.monitorVampire = value
                addon.vampireStage = nil
            end,
            default = DEFAULTS.monitorVampire,
        },
    }

    local zoneControls = {}
    for _, option in ipairs(ZONE_OPTIONS) do
        local key = option.key
        table.insert(zoneControls, {
            type = "checkbox",
            name = option.name,
            getFunc = function() return addon.settings.zones[key] ~= false end,
            setFunc = function(value)
                addon.settings.zones[key] = value
                addon.cooldowns = {}
            end,
            default = DEFAULTS.zones[key],
        })
    end

    local appearanceControls = {
        addon.fontOption,
        {
        type = "slider",
        name = "Font size",
        min = 12,
        max = 64,
        step = 2,
        getFunc = function() return addon.settings.fontSize end,
        setFunc = function(value)
            addon.settings.fontSize = value
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = DEFAULTS.fontSize,
        },
        {
        type = "slider",
        name = "Seconds before recast messages fade",
        tooltip = "How long each recast message stays fully visible before fading out.",
        min = 1,
        max = 10,
        step = 0.5,
        getFunc = function() return addon.settings.alertDisplaySeconds end,
        setFunc = function(value)
            addon.settings.alertDisplaySeconds = value
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = DEFAULTS.alertDisplaySeconds,
        },
        addon.alertSoundOption,
        {
        type = "colorpicker",
        name = "Font color",
        getFunc = function()
            local color = addon.settings.fontColor
            return color.r, color.g, color.b, color.a
        end,
        setFunc = function(r, g, b, a)
            addon.settings.fontColor = { r = r, g = g, b = b, a = a or 1 }
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = DEFAULTS.fontColor,
        },
        {
        type = "checkbox",
        name = "Lock alert position",
        tooltip = "Lock the alert position. Move mode unlocks it automatically.",
        getFunc = function() return addon.settings.locked end,
        setFunc = function(value)
            addon.settings.locked = value
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = DEFAULTS.locked,
        },
        {
        type = "button",
        name = "Toggle move mode",
        tooltip = "Keep a visible Recast Radar block on screen so you can drag it. Toggle again to hide it.",
        func = ToggleMoveMode,
        },
    }

    local skillControls = {
        {
        type = "description",
        text = "Click a skill to include or exclude it. The list follows the abilities on both weapon bars.",
        },
        {
        type = "custom",
        minHeight = 26,
        maxHeight = 312,
        createFunc = function(control)
            addon.skillsControl = control
            RefreshSkillControls(control)
        end,
        refreshFunc = function(control)
            addon.skillsControl = control
            RefreshSkillControls(control)
        end,
        },
    }

    local options = {
        {
            type = "submenu",
            name = "General",
            controls = generalControls,
        },
        {
            type = "submenu",
            name = "Cooldowns and effects",
            controls = cooldownControls,
        },
        {
            type = "submenu",
            name = "Class resources and procs",
            controls = classControls,
        },
        {
            type = "submenu",
            name = "Werewolf and Vampire",
            controls = worldControls,
        },
        {
            type = "submenu",
            name = "Zones",
            controls = zoneControls,
        },
        {
            type = "submenu",
            name = "Alert appearance and position",
            controls = appearanceControls,
        },
        {
            type = "submenu",
            name = "Slotted skills",
            controls = skillControls,
        },
    }

    library:RegisterOptionControls(PANEL_ID, options)
end

local function SetEnabled(enabled)
    addon.settings.enabled = enabled
    RefreshMonitoring()
end

local function HandleSlashCommand(argument)
    local command = string.lower(string.match(argument or "", "^%s*(.-)%s*$"))
    if command == "on" then
        SetEnabled(true)
    elseif command == "off" then
        SetEnabled(false)
    elseif command == "move" then
        ToggleMoveMode()
    elseif command == "" then
        LibAddonMenu2:OpenToPanel(addon.panel)
    else
        d("[Recast Radar] Usage: /recastradar [on|off|move]")
    end
end

local function OnActionSlotUpdated()
    if addon.skillsControl and not addon.skillsControl:IsHidden() then
        RefreshSkillControls(addon.skillsControl)
    end
end

local function OnPlayerActivated()
    addon.inCombat = IsUnitInCombat("player")
    if addon.panel and addon.panel.RefreshPanel then
        addon.panel:RefreshPanel()
    end
    RefreshMonitoring()
end

local function OnMediaRegistered(mediaType)
    if LibMediaProvider then
        if mediaType == LibMediaProvider.MediaType.FONT then
            RefreshFontChoices()
            RefreshOverlay(GetGameTimeMilliseconds())
        elseif mediaType == "sound" or mediaType == LibMediaProvider.MediaType.SOUND then
            RefreshAlertSoundChoices()
        end
    end
end

local function OnCombatStateChanged(_, inCombat)
    addon.inCombat = inCombat
    if inCombat then
        for _, cooldown in pairs(addon.cooldowns) do
            if cooldown.wasCoolingDown and cooldown.remaining > 0 then
                cooldown.combatCountdown = true
            end
        end
        local nowSeconds = GetGameTimeMilliseconds() / 1000
        for _, timeout in pairs(addon.foodDrink) do
            if timeout.timeEnding > nowSeconds then
                timeout.combatCountdown = true
            end
        end
    else
        addon.lastAlertAt = {}
    end
    RefreshMonitoring()
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    if type(_G[SAVED_VARIABLES]) ~= "table" and type(_G[LEGACY_SAVED_VARIABLES]) == "table" then
        _G[SAVED_VARIABLES] = ZO_DeepTableCopy(_G[LEGACY_SAVED_VARIABLES])
    end
    _G[LEGACY_SAVED_VARIABLES] = nil
    addon.settings = ZO_SavedVars:NewAccountWide(SAVED_VARIABLES, 1, nil, DEFAULTS)
    addon.settings.zones = addon.settings.zones or {}
    addon.settings.skills = addon.settings.skills or {}
    local booleanSettings = {
        "enabled",
        "showInCombatOnly",
        "monitorFood",
        "monitorDrink",
        "monitorCrux",
        "monitorUltimate",
        "monitorSeethingFury",
        "monitorNightblade",
        "monitorCrystalFragments",
        "monitorNecromancerCorpses",
        "monitorWerewolf",
        "monitorVampire",
    }
    for _, settingName in ipairs(booleanSettings) do
        if type(addon.settings[settingName]) ~= "boolean" then
            addon.settings[settingName] = DEFAULTS[settingName]
        end
    end
    addon.settings.minimumCooldownSeconds = tonumber(addon.settings.minimumCooldownSeconds) or DEFAULTS.minimumCooldownSeconds
    addon.settings.minimumCooldownSeconds = math.max(0, math.min(120, addon.settings.minimumCooldownSeconds))
    addon.settings.necromancerCorpseThreshold =
        math.max(1, math.min(3, math.floor(tonumber(addon.settings.necromancerCorpseThreshold) or DEFAULTS.necromancerCorpseThreshold)))
    local legacyFontIndex = math.max(1, math.min(#SYSTEM_FONTS, tonumber(addon.settings.fontIndex) or 1))
    addon.settings.fontName = addon.settings.fontName or SYSTEM_FONTS[legacyFontIndex].name
    addon.settings.fontIndex = nil
    addon.settings.fontSize = math.max(12, math.min(64, tonumber(addon.settings.fontSize) or DEFAULTS.fontSize))
    addon.settings.alertDisplaySeconds = math.max(1, math.min(10, tonumber(addon.settings.alertDisplaySeconds) or DEFAULTS.alertDisplaySeconds))
    if type(addon.settings.alertSound) ~= "string" or not IsAlertSoundChoice(addon.settings.alertSound) then
        addon.settings.alertSound = DEFAULTS.alertSound
    end
    if type(addon.settings.cruxReadySound) ~= "string" or not IsAlertSoundChoice(addon.settings.cruxReadySound) then
        addon.settings.cruxReadySound = DEFAULTS.cruxReadySound
    end
    if type(addon.settings.cruxBelowThreeSound) ~= "string" or not IsAlertSoundChoice(addon.settings.cruxBelowThreeSound) then
        addon.settings.cruxBelowThreeSound = DEFAULTS.cruxBelowThreeSound
    end
    addon.settings.fontColor = addon.settings.fontColor or {
        r = DEFAULTS.fontColor.r,
        g = DEFAULTS.fontColor.g,
        b = DEFAULTS.fontColor.b,
        a = DEFAULTS.fontColor.a,
    }
    if (tonumber(addon.settings.overlayPositionVersion) or 0) < OVERLAY_POSITION_VERSION then
        addon.settings.positionX = 0
        addon.settings.positionY = GuiRoot:GetHeight() / 3
        addon.settings.overlayPositionVersion = OVERLAY_POSITION_VERSION
    else
        addon.settings.positionX = tonumber(addon.settings.positionX) or DEFAULTS.positionX
        addon.settings.positionY = tonumber(addon.settings.positionY) or GuiRoot:GetHeight() / 3
    end

    CreateOverlay()
    RegisterSettings()
    if LibMediaProvider then
        CALLBACK_MANAGER:RegisterCallback("LibMediaProvider_Registered", OnMediaRegistered)
    end
    SLASH_COMMANDS["/recastradar"] = HandleSlashCommand
    addon.inCombat = IsUnitInCombat("player")
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTION_SLOT_UPDATED, OnActionSlotUpdated)
    local effectEventName = ADDON_NAME .. "_EffectChanged"
    EVENT_MANAGER:RegisterForEvent(effectEventName, EVENT_EFFECT_CHANGED, OnEffectChanged)
    EVENT_MANAGER:AddFilterForEvent(effectEventName, EVENT_EFFECT_CHANGED, REGISTER_FILTER_UNIT_TAG, "player")
    local combatEventName = ADDON_NAME .. "_CombatEvent"
    EVENT_MANAGER:RegisterForEvent(combatEventName, EVENT_COMBAT_EVENT, OnCombatEvent)
    EVENT_MANAGER:AddFilterForEvent(combatEventName, EVENT_COMBAT_EVENT, REGISTER_FILTER_SOURCE_COMBAT_UNIT_TYPE, COMBAT_UNIT_TYPE_PLAYER)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME .. "_PlayerActivated", EVENT_PLAYER_ACTIVATED, OnPlayerActivated)
    RefreshMonitoring()
end

RegisterBuiltinAlertSounds()
SecurePostHook(ZO_ComboBoxDropdown_Keyboard, "SetupEntryLabel", ApplyFontDropdownEntryFont)
SecurePostHook(ZO_ComboBox_Base, "ItemSelectedClickHelper", ApplyFontDropdownSelectedFont)

CreateOverlay = function()
    local overlay = WINDOW_MANAGER:CreateControl(nil, GuiRoot, CT_TOPLEVELCONTROL)
    local width = GetOverlayWidth()
    overlay:SetDimensions(width, MIN_OVERLAY_HEIGHT)
    overlay:SetAnchor(TOP, GuiRoot, TOP, addon.settings.positionX, addon.settings.positionY)
    overlay:SetDrawTier(DT_HIGH)
    overlay:SetDrawLayer(DL_OVERLAY)
    overlay:SetDrawLevel(100)
    overlay:SetClampedToScreen(true)
    overlay:SetMouseEnabled(false)
    overlay:SetMovable(false)
    overlay:SetHidden(true)
    overlay:SetHandler("OnEffectivelyShown", function(control)
        control:SetAlpha(1)
    end)
    overlay:SetHandler("OnMouseDown", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and addon.moveMode and not addon.settings.locked then
            control:StartMoving()
        end
    end)
    overlay:SetHandler("OnReceiveDrag", StartMovingOverlay)
    overlay:SetHandler("OnMouseUp", function(control)
        control:StopMovingOrResizing()
        local centerX = control:GetCenter()
        local rootCenterX = GuiRoot:GetCenter()
        local rootTop = GuiRoot:GetTop()
        addon.settings.positionX = centerX - rootCenterX
        addon.settings.positionY = control:GetTop() - rootTop
        control:ClearAnchors()
        control:SetAnchor(TOP, GuiRoot, TOP, addon.settings.positionX, addon.settings.positionY)
        RefreshOverlay(GetGameTimeMilliseconds())
    end)
    addon.overlay = overlay

    local backdrop = WINDOW_MANAGER:CreateControl(nil, overlay, CT_BACKDROP)
    backdrop:SetAnchor(TOPLEFT, overlay, TOPLEFT, 0, 0)
    backdrop:SetAnchor(BOTTOMRIGHT, overlay, BOTTOMRIGHT, 0, 0)
    backdrop:SetDrawTier(DT_HIGH)
    backdrop:SetDrawLayer(DL_OVERLAY)
    backdrop:SetDrawLevel(100)
    backdrop:SetMouseEnabled(false)
    backdrop:SetCenterColor(0, 0, 0, 0)
    backdrop:SetEdgeColor(0, 0, 0, 0)
    backdrop:SetEdgeTexture("EsoUI/Art/Miscellaneous/border_1px_3color.dds", 1, 1, 1, 1)
    addon.overlayBackdrop = backdrop

    local accent = WINDOW_MANAGER:CreateControl(nil, overlay, CT_BACKDROP)
    accent:SetDimensions(4, 1)
    accent:SetDrawTier(DT_HIGH)
    accent:SetDrawLayer(DL_OVERLAY)
    accent:SetDrawLevel(101)
    accent:SetMouseEnabled(false)
    accent:SetCenterColor(0.95, 0.7, 0.25, 0.75)
    accent:SetEdgeColor(0, 0, 0, 0)
    addon.overlayAccent = accent

    local label = WINDOW_MANAGER:CreateControl(nil, overlay, CT_LABEL)
    label:SetAnchor(TOP, overlay, TOP, 0, OVERLAY_PADDING)
    label:SetDimensions(width - OVERLAY_PADDING * 2, 32)
    label:SetDrawTier(DT_HIGH)
    label:SetDrawLayer(DL_OVERLAY)
    label:SetDrawLevel(102)
    label:SetMouseEnabled(false)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    addon.overlayLabel = label

    addon.overlaySceneFragment = ZO_HUDFadeSceneFragment:New(overlay, 0, 0)
    HUD_SCENE:AddFragment(addon.overlaySceneFragment)
    HUD_UI_SCENE:AddFragment(addon.overlaySceneFragment)
    SIEGE_BAR_SCENE:AddFragment(addon.overlaySceneFragment)
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
