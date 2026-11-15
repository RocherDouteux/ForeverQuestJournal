local ADDON_NAME, FQJ = ...
_G.ForeverQuestJournal_NS = FQJ

FQJ.ADDON_NAME = ADDON_NAME
FQJ.VERSION = "1.3.0"
FQJ.Zones = FQJ.Zones or {}
FQJ.MEDIA = "Interface\\AddOns\\ForeverQuestJournal\\Media\\"

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_ACCEPTED")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")

local function IsCompleted(questID)
    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questID) == true
    end
    if IsQuestFlaggedCompleted then return IsQuestFlaggedCompleted(questID) == true end
    return false
end

local function IsInLog(questID)
    if C_QuestLog and C_QuestLog.IsOnQuest then return C_QuestLog.IsOnQuest(questID) == true end
    if C_QuestLog and C_QuestLog.GetLogIndexForQuestID then
        local index = C_QuestLog.GetLogIndexForQuestID(questID)
        return index and index > 0
    end
    if GetQuestLogIndexByID then
        local index = GetQuestLogIndexByID(questID)
        return index and index > 0
    end
    if GetNumQuestLogEntries and GetQuestLogTitle then
        for index = 1, GetNumQuestLogEntries() do
            local _, _, _, _, _, _, _, id = GetQuestLogTitle(index)
            if id == questID then return true end
        end
    end
    return false
end

function FQJ.GetQuestStatus(questID)
    if IsCompleted(questID) then return "completed" end
    if IsInLog(questID) then return "active" end
    return "unstarted"
end

function FQJ.ArePrerequisitesMet(quest)
    for _, prerequisite in ipairs(quest.prerequisitesAll or {}) do
        if not IsCompleted(prerequisite.id) then return false end
    end
    local alternatives = quest.prerequisitesAny
    if alternatives and #alternatives > 0 then
        for _, prerequisite in ipairs(alternatives) do
            if IsCompleted(prerequisite.id) then return true end
        end
        return false
    end
    return true
end

function FQJ.IsQuestRelevant(quest)
    if not quest.classMask then return true end
    local _, _, classID = UnitClass("player")
    if not classID then return true end
    local classBit = 2 ^ (classID - 1)
    return math.floor(quest.classMask / classBit) % 2 >= 1
end

function FQJ.IsCompleted(questID)
    return IsCompleted(questID)
end

function FQJ.BringToFront()
    if not FQJ.Frame then return end
    FQJ.Frame:SetFrameStrata("TOOLTIP")
    FQJ.Frame:SetFrameLevel(100)
    FQJ.Frame:Raise()
end

function FQJ.Toggle()
    if not FQJ.Frame then FQJ.CreateUI() end
    if FQJ.Frame:IsShown() then
        if FQJ.Frame:GetFrameStrata() ~= "TOOLTIP" then FQJ.BringToFront()
        else FQJ.Frame:Hide() end
    else
        FQJ.Frame:Show()
        FQJ.BringToFront()
        FQJ.ShowHome()
        FQJ.Refresh()
    end
end

local function InstallJournalCoordination()
    local dungeonJournal = ForeverDungeonJournalFrame
    if not dungeonJournal or dungeonJournal.FQJCoordinationHooked then return end
    dungeonJournal.FQJCoordinationHooked = true
    dungeonJournal:HookScript("OnShow", function()
        if FQJ.Frame and FQJ.Frame:IsShown() then
            FQJ.Frame:SetFrameStrata("MEDIUM")
            FQJ.Frame:SetFrameLevel(10)
        end
    end)
end

SLASH_FOREVERQUESTJOURNAL1 = "/fqj"
SLASH_FOREVERQUESTJOURNAL2 = "/questjournal"
SlashCmdList.FOREVERQUESTJOURNAL = FQJ.Toggle

function ForeverQuestJournal_OnAddonCompartmentClick() FQJ.Toggle() end
function ForeverQuestJournal_OnAddonCompartmentEnter(button)
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Forever Quest Journal")
    GameTooltip:AddLine("Browse quests by zone.", 1, 1, 1)
    GameTooltip:Show()
end
function ForeverQuestJournal_OnAddonCompartmentLeave() GameTooltip:Hide() end

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        ForeverQuestJournalCharacterDB = ForeverQuestJournalCharacterDB or { filter = "all", language = "enUS" }
        FQJ.DB = ForeverQuestJournalCharacterDB
        FQJ.DB.filter = FQJ.DB.filter == "completed" and "completed" or "unfinished"
        FQJ.DB.language = FQJ.DB.language or "enUS"
        InstallJournalCoordination()
    elseif event == "ADDON_LOADED" and arg1 == "ForeverDungeonJournal" then
        InstallJournalCoordination()
    elseif FQJ.Frame and FQJ.Frame:IsShown() and FQJ.Refresh then
        FQJ.Refresh()
    end
end)
