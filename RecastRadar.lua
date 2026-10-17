local ADDON_NAME = "RecastRadar"
local PANEL_ID = ADDON_NAME .. "_Settings"
local SAVED_VARIABLES = "CooldownLapseMonitorSavedVariables"
local UPDATE_NAME = ADDON_NAME .. "_Update"
local ALERT_DURATION_MS = 3500
local POLL_INTERVAL_MS = 100
local FIRST_SKILL_SLOT = ACTION_BAR_FIRST_NORMAL_SLOT_INDEX + 1
local LAST_SKILL_SLOT = ACTION_BAR_ULTIMATE_SLOT_INDEX + 1
local HOTBARS = { HOTBAR_CATEGORY_PRIMARY, HOTBAR_CATEGORY_BACKUP }
local FONT_DROPDOWN_REFERENCE = "RecastRadar_FontDropdown"

local DEFAULTS = {
    enabled = true,
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
    locked = true,
    positionX = 0,
    positionY = 130,
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
    lastAlertAt = {},
    alerts = {},
    skillRows = {},
    fontChoices = {},
    fontOption = nil,
    previewing = false,
    panel = nil,
    skillsControl = nil,
    overlay = nil,
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

local function GetFontPath()
    for _, font in ipairs(addon.fontChoices) do
        if font.name == addon.settings.fontName then
            return font.path
        end
    end
    return SYSTEM_FONTS[1].path
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

local function AddAlert(abilityId, skillName, now)
    local previousAlert = addon.lastAlertAt[abilityId]
    if previousAlert and now - previousAlert < 1000 then
        return
    end

    addon.lastAlertAt[abilityId] = now
    table.insert(addon.alerts, {
        text = "Recast " .. skillName,
        expiresAt = now + ALERT_DURATION_MS,
    })
end

local function RefreshOverlay(now)
    local activeAlerts = {}
    for index = #addon.alerts, 1, -1 do
        local alert = addon.alerts[index]
        if alert.expiresAt <= now then
            table.remove(addon.alerts, index)
        else
            table.insert(activeAlerts, 1, alert.text)
        end
    end

    if addon.previewing then
        table.insert(activeAlerts, 1, "Recast [Preview]")
    end

    addon.overlayLabel:SetText(table.concat(activeAlerts, "\n"))
    local color = addon.settings.fontColor
    addon.overlayLabel:SetColor(color.r, color.g, color.b, color.a or 1)
    addon.overlayLabel:SetFont(string.format("%s|%d|soft-shadow-thin", GetFontPath(), addon.settings.fontSize))
    local canMove = addon.previewing and not addon.settings.locked
    addon.overlay:SetMouseEnabled(canMove)
    addon.overlay:SetMovable(canMove)
    addon.overlay:SetHidden(#activeAlerts == 0)
end

local function TrackCooldown(slotIndex, hotbarCategory, now)
    local abilityId = GetSlotBoundId(slotIndex, hotbarCategory)
    local skillName = GetSkillName(slotIndex, hotbarCategory)
    local key = tostring(hotbarCategory) .. ":" .. tostring(slotIndex)
    local previous = addon.cooldowns[key]

    if not abilityId or abilityId == 0 or not skillName then
        addon.cooldowns[key] = nil
        return
    end

    local remaining, duration, isGlobal = GetSlotCooldownInfo(slotIndex, hotbarCategory)
    local isCoolingDown = remaining > 0 and not isGlobal
    if not previous or previous.abilityId ~= abilityId then
        addon.cooldowns[key] = {
            abilityId = abilityId,
            wasCoolingDown = isCoolingDown,
            remaining = remaining,
            duration = duration,
        }
        return
    end

    if isCoolingDown then
        previous.wasCoolingDown = true
        previous.remaining = remaining
        if duration > previous.duration then
            previous.duration = duration
        end
        return
    end

    if previous.wasCoolingDown and previous.remaining > 0
        and previous.duration >= addon.settings.minimumCooldownSeconds * 1000
        and IsSkillEnabled(abilityId) then
        AddAlert(abilityId, skillName, now)
    end

    previous.wasCoolingDown = false
    previous.remaining = 0
    previous.duration = 0
end

local function PollCooldowns()
    if not addon.settings.enabled or not addon.inCombat then
        return
    end

    if not IsCurrentZoneEnabled() then
        addon.cooldowns = {}
        addon.alerts = {}
        RefreshOverlay(GetGameTimeMilliseconds())
        return
    end

    local now = GetGameTimeMilliseconds()
    for _, hotbarCategory in ipairs(HOTBARS) do
        for slotIndex = FIRST_SKILL_SLOT, LAST_SKILL_SLOT do
            TrackCooldown(slotIndex, hotbarCategory, now)
        end
    end
    RefreshOverlay(now)
end

local function RefreshMonitoring()
    if addon.settings.enabled and addon.inCombat then
        EVENT_MANAGER:RegisterForUpdate(UPDATE_NAME, POLL_INTERVAL_MS, PollCooldowns)
    else
        EVENT_MANAGER:UnregisterForUpdate(UPDATE_NAME)
        addon.cooldowns = {}
        addon.alerts = {}
        RefreshOverlay(GetGameTimeMilliseconds())
    end
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
        row:SetText((enabled and "[ON] " or "[OFF] ") .. skill.name)
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

    local options = {
        {
            type = "description",
            text = "Shows a transparent Recast alert when a slotted skill finishes a cooldown during combat.",
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
            type = "slider",
            name = "Minimum cooldown duration (seconds)",
            tooltip = "Only alert for cooldowns whose full duration meets this threshold.",
            min = 0,
            max = 120,
            step = 1,
            getFunc = function() return addon.settings.minimumCooldownSeconds end,
            setFunc = function(value) addon.settings.minimumCooldownSeconds = value end,
            default = DEFAULTS.minimumCooldownSeconds,
        },
        {
            type = "header",
            name = "Zone types",
        },
    }

    for _, option in ipairs(ZONE_OPTIONS) do
        local key = option.key
        table.insert(options, {
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

    table.insert(options, {
        type = "header",
        name = "Alert appearance and position",
    })
    addon.fontOption = {
        type = "dropdown",
        name = "Font type",
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
    table.insert(options, addon.fontOption)
    table.insert(options, {
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
    })
    table.insert(options, {
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
    })
    table.insert(options, {
        type = "checkbox",
        name = "Lock alert position",
        tooltip = "Unlock the alert to drag it while the position preview is visible.",
        getFunc = function() return addon.settings.locked end,
        setFunc = function(value)
            addon.settings.locked = value
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
        default = DEFAULTS.locked,
    })
    table.insert(options, {
        type = "button",
        name = "Toggle alert position preview",
        tooltip = "Show a sample alert. Unlock the position above and drag the text to move it.",
        func = function()
            addon.previewing = not addon.previewing
            RefreshOverlay(GetGameTimeMilliseconds())
        end,
    })
    table.insert(options, {
        type = "header",
        name = "Slotted skills",
    })
    table.insert(options, {
        type = "description",
        text = "Click a skill to include or exclude it. The list follows the abilities on both weapon bars.",
    })
    table.insert(options, {
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
    })

    library:RegisterOptionControls(PANEL_ID, options)
end

local function SetEnabled(enabled)
    addon.settings.enabled = enabled
    RefreshMonitoring()
    d(string.format("[Recast Radar] %s.", enabled and "enabled" or "disabled"))
end

local function HandleSlashCommand(argument)
    local command = string.lower(string.match(argument or "", "^%s*(.-)%s*$"))
    if command == "on" then
        SetEnabled(true)
    elseif command == "off" then
        SetEnabled(false)
    elseif command == "" then
        LibAddonMenu2:OpenToPanel(addon.panel)
    else
        d("[Recast Radar] Usage: /recast [on|off]")
    end
end

local function OnActionSlotUpdated()
    if addon.skillsControl and not addon.skillsControl:IsHidden() then
        RefreshSkillControls(addon.skillsControl)
    end
end

local function OnMediaRegistered(mediaType)
    if LibMediaProvider and mediaType == LibMediaProvider.MediaType.FONT then
        RefreshFontChoices()
        RefreshOverlay(GetGameTimeMilliseconds())
    end
end

local function OnCombatStateChanged(_, inCombat)
    addon.inCombat = inCombat
    if not inCombat then
        addon.cooldowns = {}
        addon.lastAlertAt = {}
    end
    RefreshMonitoring()
end

local function OnAddonLoaded(_, addonName)
    if addonName ~= ADDON_NAME then
        return
    end

    EVENT_MANAGER:UnregisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED)
    addon.settings = ZO_SavedVars:NewAccountWide(SAVED_VARIABLES, 1, nil, DEFAULTS)
    addon.settings.zones = addon.settings.zones or {}
    addon.settings.skills = addon.settings.skills or {}
    addon.settings.minimumCooldownSeconds = tonumber(addon.settings.minimumCooldownSeconds) or DEFAULTS.minimumCooldownSeconds
    addon.settings.minimumCooldownSeconds = math.max(0, math.min(120, addon.settings.minimumCooldownSeconds))
    local legacyFontIndex = math.max(1, math.min(#SYSTEM_FONTS, tonumber(addon.settings.fontIndex) or 1))
    addon.settings.fontName = addon.settings.fontName or SYSTEM_FONTS[legacyFontIndex].name
    addon.settings.fontIndex = nil
    addon.settings.fontSize = math.max(12, math.min(64, tonumber(addon.settings.fontSize) or DEFAULTS.fontSize))
    addon.settings.fontColor = addon.settings.fontColor or {
        r = DEFAULTS.fontColor.r,
        g = DEFAULTS.fontColor.g,
        b = DEFAULTS.fontColor.b,
        a = DEFAULTS.fontColor.a,
    }
    addon.settings.positionX = tonumber(addon.settings.positionX) or DEFAULTS.positionX
    addon.settings.positionY = tonumber(addon.settings.positionY) or DEFAULTS.positionY

    CreateOverlay()
    RegisterSettings()
    if LibMediaProvider then
        CALLBACK_MANAGER:RegisterCallback("LibMediaProvider_Registered", OnMediaRegistered)
    end
    SLASH_COMMANDS["/recast"] = HandleSlashCommand
    addon.inCombat = IsUnitInCombat("player")
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
    EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ACTION_SLOT_UPDATED, OnActionSlotUpdated)
    RefreshMonitoring()
end

CreateOverlay = function()
    local overlay = WINDOW_MANAGER:CreateControl(nil, GuiRoot, CT_CONTROL)
    overlay:SetDimensions(640, 180)
    overlay:SetAnchor(CENTER, GuiRoot, CENTER, addon.settings.positionX, addon.settings.positionY)
    overlay:SetClampedToScreen(true)
    overlay:SetMouseEnabled(false)
    overlay:SetMovable(false)
    overlay:SetHidden(true)
    overlay:SetHandler("OnMouseDown", function(control, button)
        if button == MOUSE_BUTTON_INDEX_LEFT and addon.previewing and not addon.settings.locked then
            control:StartMoving()
        end
    end)
    overlay:SetHandler("OnMouseUp", function(control)
        control:StopMovingOrResizing()
        local centerX, centerY = control:GetCenter()
        local rootCenterX, rootCenterY = GuiRoot:GetCenter()
        addon.settings.positionX = centerX - rootCenterX
        addon.settings.positionY = centerY - rootCenterY
        control:ClearAnchors()
        control:SetAnchor(CENTER, GuiRoot, CENTER, addon.settings.positionX, addon.settings.positionY)
    end)
    addon.overlay = overlay

    local label = WINDOW_MANAGER:CreateControl(nil, overlay, CT_LABEL)
    label:SetAnchor(CENTER, overlay, CENTER, 0, 0)
    label:SetDimensions(640, 180)
    label:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
    label:SetVerticalAlignment(TEXT_ALIGN_CENTER)
    addon.overlayLabel = label
end

EVENT_MANAGER:RegisterForEvent(ADDON_NAME, EVENT_ADD_ON_LOADED, OnAddonLoaded)
