local _, FQJ = ...

local button

local function PositionButton()
    if not button or not Minimap then return end
    ForeverQuestJournalCharacterDB = ForeverQuestJournalCharacterDB or {}
    local angle = math.rad(ForeverQuestJournalCharacterDB.minimapAngle or 190)
    local radius = (math.max(Minimap:GetWidth() or 140, Minimap:GetHeight() or 140) * 0.5) + 8
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function CreateButton()
    if button or not Minimap then return end
    button = CreateFrame("Button", "LibDBIcon10_ForeverQuestJournal", Minimap)
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Achievement_Zone_ElwynnForest")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", -1, 1)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            FQJ.Toggle()
        elseif mouseButton == "RightButton" then
            FQJ.ShowHome()
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Forever Quest Journal", 1, 0.82, 0.25)
        GameTooltip:AddLine("Left-click: Open journal", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Return to zones", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: Move this button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local centerX, centerY = Minimap:GetCenter()
            if not centerX or not centerY then return end
            local cursorX, cursorY = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            cursorX, cursorY = cursorX / scale, cursorY / scale
            ForeverQuestJournalCharacterDB.minimapAngle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX))
            PositionButton()
        end)
    end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    PositionButton()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", CreateButton)
