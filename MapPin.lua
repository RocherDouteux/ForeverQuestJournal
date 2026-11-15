local _, FQJ = ...

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

    if FQJ.YieldToNewWindow then FQJ.YieldToNewWindow() end
    if C_Map and C_Map.OpenWorldMap then
        C_Map.OpenWorldMap(uiMapID)
    elseif ToggleWorldMap then
        ToggleWorldMap()
    end
end
