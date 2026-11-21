local _, FQJ = ...

local pinPool, activePinCount = {}, 0
local mapToggleButton
local pinsDirty, lastMapID = true, nil

local STATUS_COLORS = {
    completed = { 0.22, 0.72, 0.30 },
    active = { 0.28, 0.70, 1.00 },
    unstarted = { 1.00, 0.78, 0.20 },
}

local function Localized(record, field)
    if FQJ.Localized then return FQJ.Localized(record, field) end
    return record and record[field] or ""
end

local function GetWorldMapCanvasChild()
    if not WorldMapFrame then return nil end
    if type(WorldMapFrame.GetCanvas) == "function" then
        local ok, canvas = pcall(WorldMapFrame.GetCanvas, WorldMapFrame)
        if ok and canvas then return canvas end
    end
    if WorldMapFrame.ScrollContainer then
        return WorldMapFrame.ScrollContainer.Child or WorldMapFrame.ScrollContainer
    end
    return nil
end

local function GetCurrentMapID()
    if not WorldMapFrame or type(WorldMapFrame.GetMapID) ~= "function" then return nil end
    local ok, mapID = pcall(WorldMapFrame.GetMapID, WorldMapFrame)
    return ok and mapID or nil
end

local function FindZoneForMap(mapID)
    if not mapID then return nil end
    for _, zone in pairs(FQJ.Zones or {}) do
        if zone.uiMapID == mapID then return zone end
    end
    return nil
end

local function StatusLabel(status)
    local french = FQJ.DB and FQJ.DB.language == "frFR"
    if status == "completed" then return french and "Terminée" or "Finished" end
    if status == "active" then return french and "Dans le journal" or "In quest log" end
    return french and "Disponible" or "Available"
end

local function PinHeading()
    return FQJ.DB and FQJ.DB.language == "frFR" and "DÉPARTS DE QUÊTES" or "QUEST STARTS"
end

local function LevelLabel(level)
    return (FQJ.DB and FQJ.DB.language == "frFR" and "Niv. " or "Lv ") .. tostring(level)
end

local function CreateQuestPin(parent)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetSize(32, 32)
    pin:SetFrameLevel(10000)
    pin:EnableMouse(true)

    pin.symbol = pin:CreateTexture(nil, "OVERLAY")
    pin.symbol:SetPoint("CENTER", 0, 1)
    pin.symbol:SetSize(24, 24)
    pin.symbol:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    pin.symbol:SetTexCoord(0, 1, 0, 1)

    pin:SetScript("OnEnter", function(self)
        local group = self.group
        if not group then return end
        self.symbol:SetSize(30, 30)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(PinHeading(), 1, 0.82, 0.25)
        if group.giverText and group.giverText ~= "" then
            GameTooltip:AddLine(group.giverText, 0.80, 0.74, 0.64, true)
        end
        for _, entry in ipairs(group.entries) do
            local status = FQJ.GetQuestStatus(entry.quest.id)
            local color = STATUS_COLORS[status] or STATUS_COLORS.unstarted
            local level = entry.quest.level or entry.quest.requiredLevel or 0
            GameTooltip:AddDoubleLine(Localized(entry.quest, "name"), StatusLabel(status) .. "  ·  " .. LevelLabel(level), color[1], color[2], color[3], 0.82, 0.78, 0.68)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function(self) self.symbol:SetSize(24, 24); GameTooltip:Hide() end)
    pin:SetScript("OnClick", function(self)
        local group = self.group
        if not group then return end
        local point
        if UiMapPoint and UiMapPoint.CreateFromCoordinates then
            point = UiMapPoint.CreateFromCoordinates(group.mapID, group.x, group.y)
        elseif CreateVector2D then
            point = { uiMapID = group.mapID, position = CreateVector2D(group.x, group.y) }
        end
        if C_Map and C_Map.SetUserWaypoint and point then
            C_Map.SetUserWaypoint(point)
            if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end
    end)
    pin:Hide()
    return pin
end

local function AcquireQuestPin(index, parent)
    local pin = pinPool[index]
    if not pin then
        pin = CreateQuestPin(parent)
        pinPool[index] = pin
    elseif pin:GetParent() ~= parent then
        pin:SetParent(parent)
    end
    pin:SetFrameLevel(10000)
    return pin
end

local function HideQuestPins()
    for _, pin in ipairs(pinPool) do pin:Hide(); pin.group = nil end
    activePinCount = 0
end

local function PinsEnabled()
    return not FQJ.DB or FQJ.DB.showMapQuestPins ~= false
end

local function PaintMapToggle(button)
    local enabled = PinsEnabled()
    if enabled then
        button:SetBackdropColor(0.16, 0.105, 0.035, 0.96)
        button:SetBackdropBorderColor(0.78, 0.53, 0.14, 1)
        button.icon:SetDesaturated(false)
        button.icon:SetAlpha(1)
    else
        button:SetBackdropColor(0.055, 0.053, 0.050, 0.94)
        button:SetBackdropBorderColor(0.28, 0.27, 0.24, 1)
        button.icon:SetDesaturated(true)
        button.icon:SetAlpha(0.55)
    end
end

local function EnsureMapToggle()
    if mapToggleButton or not WorldMapFrame then return mapToggleButton end
    local button = CreateFrame("Button", "ForeverQuestJournalMapPinToggle", WorldMapFrame, "BackdropTemplate")
    button:SetSize(32, 30)
    local mapViewport = WorldMapFrame.ScrollContainer or WorldMapFrame
    button:SetPoint("TOPRIGHT", mapViewport, "TOPRIGHT", -12, -12)
    button:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 1) + 100)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetTexture("Interface\\GossipFrame\\AvailableQuestIcon")
    button.icon:SetSize(23, 23)
    button.icon:SetPoint("CENTER", 0, 0)

    button:SetScript("OnClick", function(self)
        if not FQJ.DB then return end
        FQJ.DB.showMapQuestPins = not PinsEnabled()
        pinsDirty = true
        if not PinsEnabled() then HideQuestPins() end
        PaintMapToggle(self)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        local french = FQJ.DB and FQJ.DB.language == "frFR"
        GameTooltip:SetText(french and "Marqueurs de quêtes" or "Quest markers")
        GameTooltip:AddLine(french and (PinsEnabled() and "Affichés — cliquez pour masquer." or "Masqués — cliquez pour afficher.") or (PinsEnabled() and "Shown — click to hide." or "Hidden — click to show."), 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mapToggleButton = button
    PaintMapToggle(button)
    button:Hide()
    return button
end

local function UpdateMapToggle(mapID)
    local button = EnsureMapToggle()
    if not button then return end
    if FindZoneForMap(mapID) then
        PaintMapToggle(button)
        button:Show()
    else
        button:Hide()
    end
end

local function QuestIsAvailable(quest)
    if FQJ.GetQuestStatus(quest.id) ~= "unstarted" then return false end
    if not FQJ.ArePrerequisitesMet(quest) then return false end
    return UnitLevel("player") >= (quest.requiredLevel or 0)
end

local function BuildQuestGroups(zone, mapID)
    local groupsByLocation = {}
    for _, quest in pairs(zone.quests or {}) do
        local start = quest.start
        local startMapID = start and (start.uiMapID or zone.uiMapID)
        if not quest.special and FQJ.IsQuestRelevant(quest) and QuestIsAvailable(quest) and start and start.x and start.y and startMapID == mapID then
            local x, y = start.x / 100, start.y / 100
            local key = string.format("%.4f:%.4f", x, y)
            local group = groupsByLocation[key]
            if not group then
                group = { mapID = mapID, x = x, y = y, entries = {}, givers = {} }
                groupsByLocation[key] = group
            end
            table.insert(group.entries, { quest = quest, start = start })
            local giver = Localized(start, "name")
            if giver ~= "" then group.givers[giver] = true end
        end
    end

    local groups = {}
    for _, group in pairs(groupsByLocation) do
        table.sort(group.entries, function(a, b)
            local levelA, levelB = a.quest.level or 0, b.quest.level or 0
            if levelA ~= levelB then return levelA < levelB end
            return Localized(a.quest, "name") < Localized(b.quest, "name")
        end)
        local giverNames = {}
        for giver in pairs(group.givers) do table.insert(giverNames, giver) end
        table.sort(giverNames)
        group.giverText = table.concat(giverNames, " / ")
        table.insert(groups, group)
    end
    table.sort(groups, function(a, b) return a.y == b.y and a.x < b.x or a.y < b.y end)
    return groups
end

local function PositionQuestPin(pin, group, parent)
    local width, height = parent:GetWidth(), parent:GetHeight()
    if not width or not height or width <= 1 or height <= 1 then pin:Hide(); return end
    local canvasScale = parent:GetScale() or 1
    if canvasScale <= 0 then canvasScale = 1 end
    -- Counter-scale beyond a constant-size pin: as the map zooms in, quest
    -- locations spread apart while their icons become progressively smaller.
    local markerScale = 1 / (canvasScale ^ 1.25)
    pin:SetScale(markerScale)
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", parent, "TOPLEFT", width * group.x / markerScale, -height * group.y / markerScale)
    pin:Show()
end

local function RefreshZoneQuestPins(force)
    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        if activePinCount > 0 or lastMapID ~= nil then HideQuestPins(); lastMapID = nil end
        return
    end
    local mapID = GetCurrentMapID()
    UpdateMapToggle(mapID)
    local zone = FindZoneForMap(mapID)
    local parent = GetWorldMapCanvasChild()
    if not mapID or not zone or not parent then
        if activePinCount > 0 or lastMapID ~= mapID then HideQuestPins() end
        lastMapID, pinsDirty = mapID, false
        return
    end
    if not PinsEnabled() then
        if activePinCount > 0 then HideQuestPins() end
        lastMapID, pinsDirty = mapID, false
        return
    end

    if force or pinsDirty or mapID ~= lastMapID then
        local groups = BuildQuestGroups(zone, mapID)
        activePinCount = #groups
        for index, group in ipairs(groups) do
            local pin = AcquireQuestPin(index, parent)
            pin.group = group
            pin:SetAlpha(1)
        end
        for index = #groups + 1, #pinPool do pinPool[index]:Hide(); pinPool[index].group = nil end
        lastMapID, pinsDirty = mapID, false
    end

    for index = 1, activePinCount do
        local pin = pinPool[index]
        if pin and pin.group then PositionQuestPin(pin, pin.group, parent) end
    end
end

function FQJ.MarkZonePinsDirty()
    pinsDirty = true
end

function FQJ.ShowZoneQuestPins()
    pinsDirty = true
    if C_Timer and C_Timer.After then
        for _, delay in ipairs({ 0.03, 0.12, 0.30, 0.60 }) do
            C_Timer.After(delay, function() RefreshZoneQuestPins(true) end)
        end
    else
        RefreshZoneQuestPins(true)
    end
end

function FQJ.ShowQuestStartOnMap(quest, zone)
    zone = zone or (FQJ.GetActiveZone and FQJ.GetActiveZone())
    local start = quest and quest.start
    if not start or not start.x or not start.y then
        UIErrorsFrame:AddMessage("No start location is known for this quest.", 1, 0.35, 0.1)
        return
    end
    local uiMapID = start.uiMapID or (zone and zone.uiMapID)
    if not uiMapID then return end

    local point
    if UiMapPoint and UiMapPoint.CreateFromCoordinates then
        point = UiMapPoint.CreateFromCoordinates(uiMapID, start.x / 100, start.y / 100)
    elseif CreateVector2D then
        point = { uiMapID = uiMapID, position = CreateVector2D(start.x / 100, start.y / 100) }
    end

    if C_Map and C_Map.SetUserWaypoint and point then
        C_Map.SetUserWaypoint(point)
        if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
    end

    FQJ.ShowZoneQuestPins()
    if FQJ.YieldToNewWindow then FQJ.YieldToNewWindow() end
    if C_Map and C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(uiMapID)
    elseif ToggleWorldMap then
        ToggleWorldMap()
    end
end

local mapPinDriver = CreateFrame("Frame")
mapPinDriver.elapsed = 0
mapPinDriver:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed < 0.12 then return end
    self.elapsed = 0
    RefreshZoneQuestPins(false)
end)

local function InstallMapHooks()
    if not WorldMapFrame or WorldMapFrame.FQJQuestPinsHooked then return end
    WorldMapFrame.FQJQuestPinsHooked = true
    WorldMapFrame:HookScript("OnShow", function() pinsDirty = true end)
    WorldMapFrame:HookScript("OnHide", function() HideQuestPins(); lastMapID = nil end)
    if type(WorldMapFrame.OnMapChanged) == "function" and type(hooksecurefunc) == "function" then
        pcall(hooksecurefunc, WorldMapFrame, "OnMapChanged", function() pinsDirty = true end)
    end
end

local mapHookFrame = CreateFrame("Frame")
mapHookFrame:RegisterEvent("PLAYER_LOGIN")
mapHookFrame:SetScript("OnEvent", InstallMapHooks)
InstallMapHooks()
