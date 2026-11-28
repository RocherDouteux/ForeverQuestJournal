local _, FQJ = ...

local COLORS = { completed = { 0.22, 0.72, 0.30 }, active = { 0.28, 0.70, 1.00 }, unfinished = { 0.86, 0.78, 0.62 } }
local ICON_PATH = "Interface\\AddOns\\ForeverQuestJournal\\Media\\Icons\\"
local ICONS = {
    giver = ICON_PATH .. "QuestGiver",
    objective = ICON_PATH .. "Objective",
    prerequisites = ICON_PATH .. "Prerequisites",
    rewards = ICON_PATH .. "Rewards",
    next = ICON_PATH .. "NextChain",
    active = ICON_PATH .. "ActiveQuest",
}
local NODE_ART = {
    start = ICON_PATH .. "TreeStart",
    step = ICON_PATH .. "TreeStep",
    locked = ICON_PATH .. "TreeLocked",
    remote = ICON_PATH .. "TreeRemote",
}
local DISC_TEXTURE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local TREE_WIDTH, TREE_HEIGHT = 1450, 900

local TEXT = {
    enUS = {
        search = "Search for Zones, Quests...", zoneGallery = "Return to zone gallery",
        searchTree = "Find a quest in this tree...", searchResults = "%d matches  ·  Enter to jump", searchNone = "No matching quests",
        unfinished = "Unfinished", completed = "Finished", status_unfinished = "UNFINISHED", status_active = "IN QUEST LOG", status_completed = "FINISHED",
        locked = "LOCKED", questLevel = "Quest level %d  -  Requires level %d", giver = "QUEST GIVER",
        starts = "Starts from", item = "Starts from item", unknown = "Quest start: Unknown",
        objective = "OBJECTIVE", prerequisites = "PREREQUISITES", none = "No known prerequisites",
        requiredQuest = "REQUIRED QUEST", requiredAll = "COMPLETE ALL OF THESE", any = "COMPLETE ANY ONE OF THESE",
        met = "Completed", unmet = "Still required", viewQuest = "View quest",
        next = "NEXT IN CHAIN", rewards = "POSSIBLE REWARDS", showMap = "Show Start on Map", level = "Lv %d", zoneLevel = "LV AVG %s  ·  MED %s", range = "LV %d-%d",
        progress = "%d finished   -   %d unfinished", count = "%d/%d quests",
        other = "Other", eastern = "Eastern Kingdoms", kalimdor = "Kalimdor",
        chain = "CHAIN  ·  %d STEPS", standalone = "STANDALONE QUESTS",
        startStep = "START",
        unavailableZone = "Zone unavailable", previous = "PREVIOUS STEPS",
        empty = "No quests match this view.", center = "Recenter", treeControls = "Drag to pan  ·  Scroll to zoom",
        alternative = "Alternative prerequisite",
        legend = "Legend", legendStart = "Chain start", legendStep = "Quest step",
        legendLocked = "Locked", legendRemote = "Another zone", legendActive = "In quest log",
        treeBack = "< Back", treeBackTo = "Return to %s",
    },
    frFR = {
        search = "Rechercher une zone ou une quête...", zoneGallery = "Retour à la galerie des zones",
        searchTree = "Chercher dans cet arbre...", searchResults = "%d résultats  ·  Entrée pour accéder", searchNone = "Aucune quête trouvée",
        unfinished = "Inachevées", completed = "Terminées", status_unfinished = "INACHEVÉE", status_active = "DANS LE JOURNAL", status_completed = "TERMINÉE",
        locked = "VERROUILLÉE", questLevel = "Niveau %d  -  Niveau requis %d", giver = "DONNEUR DE QUÊTE",
        starts = "Commence auprès de", item = "Objet de départ", unknown = "Départ de quête : inconnu",
        objective = "OBJECTIF", prerequisites = "PRÉREQUIS", none = "Aucun prérequis connu",
        requiredQuest = "QUÊTE REQUISE", requiredAll = "TERMINER TOUTES CES QUÊTES", any = "TERMINER UNE DE CES QUÊTES",
        met = "Terminée", unmet = "Reste à terminer", viewQuest = "Voir la quête",
        next = "SUITE DE LA CHAÎNE", rewards = "RÉCOMPENSES POSSIBLES", showMap = "Voir le départ sur la carte", level = "Niv. %d", zoneLevel = "NIV. MOY. %s  ·  MÉD. %s", range = "NIV. %d-%d",
        progress = "%d terminées   -   %d inachevées", count = "%d/%d quêtes",
        other = "Autres", eastern = "Royaumes de l'Est", kalimdor = "Kalimdor",
        chain = "CHAÎNE  ·  %d ÉTAPES", standalone = "QUÊTES INDÉPENDANTES",
        startStep = "DÉPART",
        unavailableZone = "Zone inconnue", previous = "ÉTAPES PRÉCÉDENTES",
        empty = "Aucune quête ne correspond.", center = "Recentrer", treeControls = "Glisser pour déplacer  ·  Molette pour zoomer",
        alternative = "Prérequis au choix",
        legend = "Légende", legendStart = "Début de chaîne", legendStep = "Étape de quête",
        legendLocked = "Verrouillée", legendRemote = "Autre zone", legendActive = "Dans le journal",
        treeBack = "< Retour", treeBackTo = "Retour à %s",
    },
}

local rows, selectedQuestID, activeZoneKey = {}, nil, "zone_12"
local JumpToNode, PaintQuestNode
local function Language() return FQJ.DB and FQJ.DB.language == "frFR" and "frFR" or "enUS" end
local function L(key) return (TEXT[Language()] and TEXT[Language()][key]) or TEXT.enUS[key] or key end
local function Localized(record, field)
    if not record then return "" end
    if Language() == "frFR" and record[field .. "_fr"] and record[field .. "_fr"] ~= "" then return record[field .. "_fr"] end
    return record[field] or ""
end
FQJ.Localized = Localized
local function ActiveZone() return FQJ.Zones[activeZoneKey] or FQJ.Zones.zone_12 end
FQJ.GetActiveZone = ActiveZone

local function Backdrop(frame, bg, border)
    frame:SetBackdrop({ bgFile = bg or "Interface\\Buttons\\WHITE8X8", edgeFile = border or "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 14, insets = { left=3,right=3,top=3,bottom=3 } })
end
local function Font(parent, size, color, justify)
    local text = parent:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size or 12, "")
    text:SetTextColor(unpack(color or { 0.10, 0.055, 0.02 })); text:SetJustifyH(justify or "LEFT")
    return text
end
local function CreateFlatButton(parent,width,height,variant)
    local button=CreateFrame("Button",nil,parent,"BackdropTemplate"); button:SetSize(width,height); button.variant=variant or "default"; button.selected=false
    button:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    button.label=Font(button,12,{0.90,0.84,0.73},"CENTER"); button.label:SetPoint("CENTER",0,0)
    button.label:SetShadowColor(0,0,0,0.9); button.label:SetShadowOffset(1,-1)
    button.SetText=function(self,text) self.label:SetText(text or "") end
    local function Paint(self,pressed)
        if self.selected then
            self:SetBackdropColor(0.23,0.155,0.055,0.98); self:SetBackdropBorderColor(0.72,0.50,0.14,1); self.label:SetTextColor(1.00,0.82,0.27)
        elseif not self:IsEnabled() then
            self:SetBackdropColor(0.055,0.053,0.050,0.92); self:SetBackdropBorderColor(0.20,0.19,0.17,1); self.label:SetTextColor(0.42,0.40,0.36)
        elseif pressed then
            self:SetBackdropColor(0.19,0.135,0.050,1); self:SetBackdropBorderColor(0.82,0.58,0.17,1); self.label:SetTextColor(1.00,0.84,0.31)
        elseif self:IsMouseOver() then
            self:SetBackdropColor(0.14,0.105,0.055,0.99); self:SetBackdropBorderColor(0.66,0.47,0.18,1); self.label:SetTextColor(1.00,0.86,0.38)
        elseif self.variant=="primary" then
            self:SetBackdropColor(0.14,0.095,0.035,0.98); self:SetBackdropBorderColor(0.56,0.39,0.13,1); self.label:SetTextColor(1.00,0.82,0.27)
        else
            self:SetBackdropColor(0.075,0.073,0.068,0.98); self:SetBackdropBorderColor(0.30,0.29,0.25,1); self.label:SetTextColor(0.90,0.84,0.73)
        end
    end
    button.SetSelected=function(self,value) self.selected=value and true or false; Paint(self,false) end
    button:SetScript("OnEnter",function(self) Paint(self,false) end); button:SetScript("OnLeave",function(self) Paint(self,false) end)
    button:SetScript("OnMouseDown",function(self) if self:IsEnabled() then Paint(self,true) end end); button:SetScript("OnMouseUp",function(self) Paint(self,false) end)
    button:SetScript("OnEnable",function(self) Paint(self,false) end); button:SetScript("OnDisable",function(self) Paint(self,false) end)
    Paint(button,false); return button
end
local function ZoneName(zone) return Localized(zone, "name") end
local function QuestName(quest) return Localized(quest, "name") end
local function ZoneStats(zone)
    local totals = { completed=0, active=0, unstarted=0, meanLevel=1, medianLevel=1, minLevel=1, maxLevel=1 }
    local levels,levelSum = {},0
    for _, quest in pairs(zone.quests) do
        if FQJ.IsQuestRelevant(quest) and not quest.special then
            local status = FQJ.GetQuestStatus(quest.id); totals[status] = totals[status] + 1
            local level = math.max(1, quest.level or quest.requiredLevel or 1)
            table.insert(levels,level); levelSum=levelSum+level
        end
    end
    if #levels>0 then
        table.sort(levels)
        totals.minLevel=levels[1]; totals.maxLevel=levels[#levels]
        totals.meanLevel=levelSum/#levels
        local middle=math.floor((#levels+1)/2)
        if #levels%2==1 then totals.medianLevel=levels[middle]
        else totals.medianLevel=(levels[middle]+levels[middle+1])/2 end
    end
    return totals
end
local function SortedZones()
    local result,averages = {},{}
    for _,zone in pairs(FQJ.Zones) do
        if zone.key and zone.quests and next(zone.quests) then
            local stats=ZoneStats(zone)
            if stats.completed+stats.active+stats.unstarted>0 then
                table.insert(result,zone); averages[zone]=stats.meanLevel
            end
        end
    end
    table.sort(result,function(a,b)
        if a.continent~=b.continent then return a.continent<b.continent end
        local averageA,averageB=averages[a],averages[b]
        if averageA~=averageB then return averageA<averageB end
        return ZoneName(a)<ZoneName(b)
    end)
    return result
end
local function LevelNumber(value)
    return tostring(math.floor((value or 0)+0.5))
end
local function ZoneLevelText(stats)
    return string.format(L("zoneLevel"),LevelNumber(stats.meanLevel),LevelNumber(stats.medianLevel))
end
local function StatusText(questID)
    local rawStatus = FQJ.GetQuestStatus(questID)
    local status = rawStatus == "completed" and "completed" or (rawStatus == "active" and "active" or "unfinished")
    return status, L("status_" .. status), COLORS[status]
end
local function SearchText() return FQJ.Frame and FQJ.Frame.searchBox and (FQJ.Frame.searchBox:GetText() or ""):lower() or "" end
local function MatchesZone(zone, query)
    if query == "" or ZoneName(zone):lower():find(query,1,true) then return true end
    for _, quest in pairs(zone.quests) do if QuestName(quest):lower():find(query,1,true) then return true end end
    return false
end
local function AddCardArt(card, zone)
    local art = card:CreateTexture(nil,"ARTWORK",nil,1); art:SetPoint("TOPLEFT",4,-4); art:SetPoint("BOTTOMRIGHT",-4,4)
    local bundled = FQJ.ZoneArt and FQJ.ZoneArt[zone.key]
    if bundled then
        art:SetTexture(bundled)
        art:SetTexCoord(0,1,0,1)
    else
        art:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        art:SetVertexColor(0.38,0.32,0.24,1)
    end
    card.art=art
end
local function CreateZoneCard(zone)
    local card = CreateFrame("Button",nil,FQJ.Frame.homeChild,"BackdropTemplate"); card:SetSize(352,126); Backdrop(card)
    card:SetBackdropColor(0.02,0.02,0.02,0.50); card:SetBackdropBorderColor(0.34,0.34,0.34,1); AddCardArt(card,zone)
    local shade=card:CreateTexture(nil,"ARTWORK",nil,2); shade:SetPoint("TOPLEFT",4,-4); shade:SetPoint("TOPRIGHT",-4,-4); shade:SetHeight(42); shade:SetColorTexture(0,0,0,0.62)
    local bottomShade=card:CreateTexture(nil,"ARTWORK",nil,2); bottomShade:SetPoint("BOTTOMLEFT",4,4); bottomShade:SetPoint("BOTTOMRIGHT",-4,4); bottomShade:SetHeight(30); bottomShade:SetColorTexture(0,0,0,0.42)
    local full=card:CreateTexture(nil,"ARTWORK",nil,2); full:SetPoint("TOPLEFT",4,-4); full:SetPoint("BOTTOMRIGHT",-4,4); full:SetColorTexture(0.02,0.02,0.02,0.08)
    local highlight=card:CreateTexture(nil,"HIGHLIGHT"); highlight:SetPoint("TOPLEFT",4,-4); highlight:SetPoint("BOTTOMRIGHT",-4,4); highlight:SetColorTexture(1,0.84,0.25,0.11)
    card.title=Font(card,16,{1,0.88,0.24}); card.title:SetPoint("TOPLEFT",16,-14); card.title:SetShadowColor(0,0,0,1); card.title:SetShadowOffset(1,-1)
    card.progress=Font(card,12,{0.97,0.89,0.54},"RIGHT"); card.progress:SetPoint("TOPRIGHT",-14,-11); card.progress:SetShadowColor(0,0,0,1); card.progress:SetShadowOffset(1,-1)
    card.level=Font(card,10,{1,0.95,0.82}); card.level:SetPoint("BOTTOMLEFT",14,10); card.level:SetShadowColor(0,0,0,1); card.level:SetShadowOffset(1,-1)
    card.range=Font(card,10,{0.82,0.76,0.66},"RIGHT"); card.range:SetPoint("BOTTOMRIGHT",-14,10); card.range:SetShadowColor(0,0,0,1); card.range:SetShadowOffset(1,-1)
    card:SetScript("OnClick",function() FQJ.Frame.searchBox:SetText(""); FQJ.ShowZone(zone.key) end)
    card:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(1,0.76,0.22,1) end)
    card:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.34,0.34,0.34,1) end)
    return card
end
local function ContinentLabel(continent)
    if continent=="Eastern Kingdoms" then return L("eastern") end
    if continent=="Kalimdor" then return L("kalimdor") end
    return L("other")
end
local function AcquireHeader(continent)
    local frame=FQJ.Frame
    if frame.homeHeaders[continent] then return frame.homeHeaders[continent] end
    local header=CreateFrame("Frame",nil,frame.homeChild); header:SetSize(742,34)
    local icon=header:CreateTexture(nil,"ARTWORK"); icon:SetSize(29,29); icon:SetPoint("LEFT",3,0); icon:SetTexture("Interface\\Icons\\INV_Misc_Map_01"); icon:SetTexCoord(0.08,0.92,0.08,0.92)
    header.text=Font(header,16,{1,0.78,0.20}); header.text:SetPoint("LEFT",41,1)
    local rule=header:CreateTexture(nil,"ARTWORK"); rule:SetColorTexture(0.50,0.34,0.13,0.75); rule:SetPoint("BOTTOMLEFT",0,0); rule:SetPoint("BOTTOMRIGHT",0,0); rule:SetHeight(1)
    frame.homeHeaders[continent]=header; return header
end
function FQJ.RefreshHome()
    local frame=FQJ.Frame; if not frame then return end
    local query,groups=SearchText(),{["Eastern Kingdoms"]={},Kalimdor={},Other={}}
    for _,zone in ipairs(SortedZones()) do if MatchesZone(zone,query) then table.insert(groups[zone.continent] or groups.Other,zone) end end
    for _,card in pairs(frame.zoneCards) do card:Hide() end
    for _,header in pairs(frame.homeHeaders) do header:Hide() end
    local y=6
    for _,continent in ipairs({"Eastern Kingdoms","Kalimdor","Other"}) do
        local group=groups[continent]
        if #group>0 then
            local header=AcquireHeader(continent); header.text:SetText(ContinentLabel(continent)); header:ClearAllPoints(); header:SetPoint("TOPLEFT",0,-y); header:Show(); y=y+43
            for index,zone in ipairs(group) do
                local card=frame.zoneCards[zone.key]; if not card then card=CreateZoneCard(zone); frame.zoneCards[zone.key]=card end
                local stats=ZoneStats(zone); local total=stats.completed+stats.active+stats.unstarted
                card.title:SetText(ZoneName(zone)); card.progress:SetText(string.format(L("count"),stats.completed,total)); card.level:SetText(ZoneLevelText(stats)); card.range:SetText(string.format(L("range"),stats.minLevel,stats.maxLevel))
                card:ClearAllPoints(); card:SetPoint("TOPLEFT",((index-1)%2)*366,-(y+math.floor((index-1)/2)*138)); card:Show()
            end
            y=y+math.ceil(#group/2)*138+8
        end
    end
    frame.homeChild:SetHeight(math.max(500,y))
end
function FQJ.ShowHome()
    local frame=FQJ.Frame; if not frame then return end
    frame:SetSize(850,590)
    frame:SetScale(1)
    wipe(frame.treeHistory)
    frame.placeholder:SetText(L("search"))
    frame.treeSearchInfo:Hide()
    frame.home:Show(); frame.zoneContent:Hide(); frame.searchBox:Show()
    FQJ.RefreshHome()
end
function FQJ.ShowZone(zoneKey, questID, previousView)
    local frame=FQJ.Frame; if not frame then return end
    if zoneKey and FQJ.Zones[zoneKey] then activeZoneKey=zoneKey end
    frame:SetSize(TREE_WIDTH,TREE_HEIGHT)
    frame:SetScale(math.min(1,(UIParent:GetWidth()-24)/TREE_WIDTH,(UIParent:GetHeight()-32)/TREE_HEIGHT))
    selectedQuestID = questID
    frame.home:Hide(); frame.zoneContent:Show(); frame.searchBox:Show()
    frame.placeholder:SetText(L("searchTree"))
    local zone=ActiveZone(); local stats=ZoneStats(zone); frame.zoneTitle:SetText(ZoneName(zone).." ("..string.format(L("range"),stats.minLevel,stats.maxLevel)..")"); frame.zoneMeta:SetText(ZoneLevelText(stats))
    frame.zoneLink:SetWidth(math.max(1,frame.zoneTitle:GetStringWidth()+4))
    frame.treeBack:SetEnabled(#frame.treeHistory > 0)
    if previousView then
        local camera = frame.treeCamera
        camera.x,camera.y,camera.zoom = previousView.x,previousView.y,previousView.zoom
        frame.treeReset = nil
        frame.detail:SetShown(previousView.detailsShown)
        FQJ.Refresh()
    else
        frame.treeReset = true
        if not questID then frame.detail:Hide() end
        FQJ.Refresh(questID)
    end
end

local function AddDetailBlock(parent,anchor,label,value,iconPath,valueColor)
    local block=CreateFrame("Frame",nil,parent,"BackdropTemplate"); block:SetWidth(parent:GetWidth()-4)
    block:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
    block:SetBackdropColor(0.12,0.075,0.035,0.96); block:SetBackdropBorderColor(0.40,0.25,0.08,1)
    local icon=block:CreateTexture(nil,"ARTWORK"); icon:SetSize(34,34); icon:SetPoint("TOPLEFT",8,-8); icon:SetTexture(iconPath); icon:SetTexCoord(0,1,0,1)
    local heading=Font(block,12,{1.00,0.79,0.25}); heading:SetPoint("TOPLEFT",50,-8); heading:SetPoint("RIGHT",-8,0); heading:SetText(label)
    local body=Font(block,12,valueColor or {0.90,0.82,0.68}); body:SetPoint("TOPLEFT",50,-25); body:SetWidth(block:GetWidth()-60); body:SetWordWrap(true); body:SetText(value)
    block:SetHeight(math.max(50,33+(body:GetStringHeight() or 14)))
    if anchor then block:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-8) else block:SetPoint("TOPLEFT",0,0) end
    return block
end
local function AddQuestLinksBlock(parent,anchor,label,iconPath,entries)
    local block = AddDetailBlock(parent,anchor,label,"",iconPath)
    local width = block:GetWidth()-58
    local top = 28
    for _, entry in ipairs(entries) do
        local row = CreateFrame("Button",nil,block,"BackdropTemplate")
        row:SetWidth(width)
        row:SetPoint("TOPLEFT",49,-top)
        row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
        row:SetBackdropColor(0.17,0.12,0.075,1)
        row:SetBackdropBorderColor(0.33,0.24,0.14,1)
        local title = Font(row,12,{0.98,0.89,0.70})
        title:SetPoint("TOPLEFT",8,-6)
        title:SetWidth(width-(entry.done and 36 or 16))
        title:SetWordWrap(true)
        title:SetText(QuestName(entry.quest))
        if entry.done then
            local check = row:CreateTexture(nil,"ARTWORK")
            check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            check:SetSize(19,19)
            check:SetPoint("TOPRIGHT",-5,-2)
            check:SetVertexColor(0.65,1,0.68)
        end
        local info = Font(row,11,entry.color or {0.76,0.69,0.57})
        info:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-4)
        info:SetWidth(width-16)
        info:SetWordWrap(true)
        info:SetText(entry.text)
        row:SetHeight(math.max(38,17+title:GetStringHeight()+info:GetStringHeight()))
        if entry.target and entry.target.zone then
            local target = entry.target
            row:SetScript("OnClick",function() JumpToNode(target) end)
            row:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(0.80,0.60,0.28,1) end)
            row:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.33,0.24,0.14,1) end)
        else
            row:EnableMouse(false)
        end
        top = top + row:GetHeight()+5
    end
    block:SetHeight(top+4)
    return block
end
local function GetRewardIcon(itemID)
    if C_Item and C_Item.GetItemIconByID then
        local ok, icon = pcall(C_Item.GetItemIconByID,itemID)
        if ok and icon then return icon end
    end
    if GetItemIcon then
        local ok, icon = pcall(GetItemIcon,itemID)
        if ok and icon then return icon end
    end
    if GetItemInfo then
        local ok, icon = pcall(function() return select(10,GetItemInfo(itemID)) end)
        if ok and icon then return icon end
    end
    return ICONS.rewards
end
local function AddRewardsBlock(parent,anchor,rewards)
    local height=48+(#rewards*36)
    local block=CreateFrame("Frame",nil,parent,"BackdropTemplate"); block:SetWidth(parent:GetWidth()-4); block:SetHeight(height)
    block:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=2,right=2,top=2,bottom=2}})
    block:SetBackdropColor(0.12,0.075,0.035,0.96); block:SetBackdropBorderColor(0.40,0.25,0.08,1)
    local icon=block:CreateTexture(nil,"ARTWORK"); icon:SetSize(34,34); icon:SetPoint("TOPLEFT",8,-8); icon:SetTexture(ICONS.rewards); icon:SetTexCoord(0,1,0,1)
    local heading=Font(block,12,{1.00,0.79,0.25}); heading:SetPoint("TOPLEFT",50,-8); heading:SetPoint("RIGHT",-8,0); heading:SetText(L("rewards"))
    for index,reward in ipairs(rewards) do
        local item=CreateFrame("Button",nil,block,"BackdropTemplate"); item:SetHeight(31); item:SetPoint("TOPLEFT",50,-25-((index-1)*36)); item:SetPoint("RIGHT",-8,0)
        item:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); item:SetBackdropColor(0.075,0.052,0.030,0.98); item:SetBackdropBorderColor(0.28,0.18,0.07,1)
        local itemIcon=item:CreateTexture(nil,"ARTWORK"); itemIcon:SetSize(27,27); itemIcon:SetPoint("LEFT",2,0); itemIcon:SetTexture(GetRewardIcon(reward.id)); itemIcon:SetTexCoord(0.08,0.92,0.08,0.92)
        local name=Font(item,11,{0.90,0.82,0.68}); name:SetPoint("LEFT",36,0); name:SetPoint("RIGHT",-6,0); name:SetText(Localized(reward,"name"))
        item:SetScript("OnEnter",function(self)
            self:SetBackdropBorderColor(0.72,0.50,0.14,1); GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
            local ok=reward.id and pcall(GameTooltip.SetHyperlink,GameTooltip,"item:"..reward.id)
            if not ok then GameTooltip:SetText(Localized(reward,"name")) end
            GameTooltip:Show()
        end)
        item:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.28,0.18,0.07,1); GameTooltip:Hide() end)
    end
    if anchor then block:SetPoint("TOPLEFT",anchor,"BOTTOMLEFT",0,-8) else block:SetPoint("TOPLEFT",0,0) end
    return block
end

local DETAIL_EDGE_MARGIN = 12
-- Header, footer, and the two inset borders around the scroll area.
local DETAIL_VERTICAL_CHROME = 78 + 50 + 8 + 8

local function PositionQuestDetail(detail, left, top)
    local viewport = detail:GetParent()
    local margin = DETAIL_EDGE_MARGIN
    left = math.max(margin,math.min(viewport:GetWidth()-detail:GetWidth()-margin,left))
    top = math.max(margin,math.min(viewport:GetHeight()-detail:GetHeight()-margin,top))
    detail:ClearAllPoints()
    detail:SetPoint("TOPLEFT",viewport,"TOPLEFT",left,-top)
end

local function ResizeQuestDetail(detail, contentHeight, previousScroll)
    local viewport = detail:GetParent()
    local margin = DETAIL_EDGE_MARGIN
    local maximum = math.max(DETAIL_VERTICAL_CHROME+1,viewport:GetHeight()-margin*2)
    local height = math.min(maximum,contentHeight+DETAIL_VERTICAL_CHROME)
    local overflow = math.max(0,contentHeight-(height-DETAIL_VERTICAL_CHROME))
    detail:SetHeight(height)
    if detail.dragged then
        PositionQuestDetail(detail,detail:GetLeft()-viewport:GetLeft(),viewport:GetTop()-detail:GetTop())
    end

    local scroll = detail.scrollFrame
    scroll.questDetailsOverflow = overflow > 0
    detail.scrollChild:SetHeight(contentHeight)
    scroll:UpdateScrollChildRect()
    scroll:SetVerticalScroll(math.min(previousScroll,overflow))
    if scroll.ScrollBar then scroll.ScrollBar:SetShown(scroll.questDetailsOverflow) end
end

local function SelectQuest(questID)
    selectedQuestID=questID
    local zone,detail=ActiveZone(),FQJ.Frame.detail; local quest=zone and zone.quests[questID]; if not quest then return end
    local previousScroll = 0
    if detail:IsShown() and detail.renderedQuestID == questID then
        previousScroll = detail.scrollFrame:GetVerticalScroll()
    end
    detail.renderedQuestID = questID
    detail:Show()
    detail.title:SetText(QuestName(quest)); detail.level:SetText(string.format(L("questLevel"),quest.level or 0,quest.requiredLevel or 0))
    local rawStatus=FQJ.GetQuestStatus(questID); local _,label,color=StatusText(questID); detail.status:SetText(label); detail.status:SetTextColor(unpack(color)); detail.questIcon:SetTexture(rawStatus=="active" and ICONS.active or ICONS.giver)
    for _,old in ipairs(detail.lines) do old:Hide() end; wipe(detail.lines)
    local anchor, height = nil, 0
    local function AddBlock(item)
        table.insert(detail.lines,item)
        anchor, height = item, height + item:GetHeight() + 8
    end
    local function block(label,value,icon)
        AddBlock(AddDetailBlock(detail.content,anchor,label,value,icon))
    end
    if quest.start then
        local kind=quest.start.kind=="npc" and L("giver") or (quest.start.kind=="object" and L("starts") or L("item"))
        block(kind,Localized(quest.start,"name"),ICONS.giver)
    else block(L("starts"),L("unknown"),ICONS.giver) end
    local objective=Localized(quest,"objective")
    if objective~="" then block(L("objective"),objective,ICONS.objective) end
    local graph = FQJ.GetQuestTree()
    local shownPrerequisites = {}
    local function QuestLink(ref, status, color)
        local target = graph[ref.id]
        local parts = {}
        if status then table.insert(parts,status) end
        if target and target.zone then
            if target.zone ~= zone then table.insert(parts,ZoneName(target.zone)) end
            table.insert(parts,L("viewQuest"))
        else
            table.insert(parts,L("unavailableZone"))
        end
        return { quest=ref, target=target, text=table.concat(parts,"  ·  "), color=color }
    end
    local function Prerequisites(list, heading)
        if #list == 0 then return end
        local entries = {}
        for _,ref in ipairs(list) do
            local done = FQJ.IsCompleted(ref.id)
            local entry = QuestLink(ref,L(done and "met" or "unmet"),
                done and {0.48,0.86,0.53} or {0.93,0.70,0.41})
            entry.done = done
            table.insert(entries,entry)
            shownPrerequisites[ref.id] = true
        end
        AddBlock(AddQuestLinksBlock(detail.content,anchor,L(heading),ICONS.prerequisites,entries))
    end
    local all,any = quest.prerequisitesAll or {},quest.prerequisitesAny or {}
    if #all + #any == 0 then block(L("prerequisites"),L("none"),ICONS.prerequisites) end
    Prerequisites(all,#all == 1 and "requiredQuest" or "requiredAll")
    Prerequisites(any,#any == 1 and "requiredQuest" or "any")
    local function LinkedSteps(edges, direction, heading)
        local entries = {}
        for _, edge in ipairs(edges) do
            local target = edge[direction]
            if direction ~= "from" or not shownPrerequisites[target.quest.id] then
                table.insert(entries,QuestLink(target.quest,edge.kind == "alternative" and L("alternative") or nil))
            end
        end
        if #entries > 0 then
            AddBlock(AddQuestLinksBlock(detail.content,anchor,heading,ICONS.next,entries))
        end
    end
    local node = graph[questID]
    if node then
        LinkedSteps(node.before,"from",L("previous"))
        LinkedSteps(node.after,"to",L("next"))
    end
    if quest.rewards and #quest.rewards>0 then
        local item=AddRewardsBlock(detail.content,anchor,quest.rewards)
        table.insert(detail.lines,item)
        height = height + item:GetHeight() + 8
    end
    detail.mapButton:SetEnabled(quest.start and quest.start.x and quest.start.y); detail.mapButton:SetAlpha(detail.mapButton:IsEnabled() and 1 or 0.45)
    ResizeQuestDetail(detail,math.max(1,height-4),previousScroll)
    for _,button in ipairs(rows) do
        if button:IsShown() then PaintQuestNode(button) end
    end
end
JumpToNode = function(node)
    if not node.zone then return end
    local frame = FQJ.Frame
    if node.zone ~= ActiveZone() then
        local camera = frame.treeCamera
        table.insert(frame.treeHistory,{
            zoneKey = activeZoneKey, questID = selectedQuestID,
            query = frame.searchBox:GetText(),
            x = camera.x, y = camera.y, zoom = camera.zoom,
            detailsShown = frame.detail:IsShown(),
        })
    end
    frame.suppressSearchRefresh = true
    frame.searchBox:SetText("")
    frame.searchBox:ClearFocus()
    frame.suppressSearchRefresh = nil
    FQJ.ShowZone(node.zone.key, node.quest.id)
end

local function ReturnToPreviousZone()
    local frame = FQJ.Frame
    local view = table.remove(frame.treeHistory)
    if not view then return end
    if GameTooltip and GameTooltip:IsOwned(frame.treeBack) then GameTooltip:Hide() end
    frame.suppressSearchRefresh = true
    frame.searchBox:SetText(view.query or "")
    frame.searchBox:ClearFocus()
    frame.suppressSearchRefresh = nil
    FQJ.ShowZone(view.zoneKey,view.questID,view)
end

local function AnimateQuestHalo(button, elapsed)
    local period = 2.8
    button.haloTime = (button.haloTime + elapsed) % period
    local breath = (1-math.cos(button.haloTime/period * 2*math.pi))/2
    local size = 88 + 15*breath
    button.nodeGlow:SetSize(size,size)
    button.nodeGlow:SetAlpha(0.80 - 0.47*breath)
end

PaintQuestNode = function(button)
    local detail = FQJ.Frame.detail
    local selected = detail:IsShown() and button.node.quest.id == selectedQuestID
    local matches = button.searchMatch == true
    local glowing = selected or matches
    local color = button.color
    button.ring:SetVertexColor(color[1],color[2],color[3],1)
    if matches then
        button.nodeGlow:SetVertexColor(0.70,0.49,1,1)
    elseif selected then
        button.nodeGlow:SetVertexColor(1,0.62,0.24,1)
    end
    if button.nodeGlow:IsShown() ~= glowing then
        button.nodeGlow:SetShown(glowing)
        button:SetScript("OnUpdate",glowing and AnimateQuestHalo or nil)
        if glowing then
            button.haloTime = 0
            AnimateQuestHalo(button,0)
        end
    end
    button.halo:SetAlpha(selected and 0.80 or 0.25)
    button.halo:SetShown(selected or button.hovered)
    button:SetAlpha(button.searchDimmed and not selected and not button.hovered and 0.42 or 1)
end

local function AcquireNode(parent, index)
    if rows[index] then return rows[index] end
    local button = CreateFrame("Button",nil,parent)
    button:SetSize(66,66)
    local function Circle(layer, diameter, r, g, b, alpha)
        local texture = button:CreateTexture(nil,layer)
        texture:SetTexture(DISC_TEXTURE)
        texture:SetSize(diameter,diameter)
        texture:SetPoint("CENTER")
        texture:SetVertexColor(r,g,b,alpha)
        return texture
    end
    button.nodeGlow = button:CreateTexture(nil,"BACKGROUND",nil,-1)
    button.nodeGlow:SetTexture(ICON_PATH .. "TreeSelectionHalo")
    button.nodeGlow:SetBlendMode("ADD")
    button.nodeGlow:SetPoint("CENTER")
    button.nodeGlow:Hide()
    button.halo = Circle("BACKGROUND",66,1,0.76,0.43,1)
    button.ring = Circle("BORDER",60,0.86,0.65,0.34,1)
    button.fill = Circle("ARTWORK",54,0.14,0.098,0.061,1)
    button.icon = button:CreateTexture(nil,"OVERLAY")
    button.icon:SetSize(40,40)
    button.icon:SetPoint("CENTER")
    local badge = CreateFrame("Frame",nil,button)
    badge:SetSize(27,27)
    badge:SetPoint("CENTER",button,"CENTER",23,-23)
    local rim = badge:CreateTexture(nil,"BACKGROUND")
    rim:SetAllPoints()
    rim:SetTexture(DISC_TEXTURE)
    rim:SetVertexColor(0.06,0.10,0.07,1)
    local face = badge:CreateTexture(nil,"ARTWORK")
    face:SetTexture(DISC_TEXTURE)
    face:SetSize(23,23)
    face:SetPoint("CENTER")
    face:SetVertexColor(0.11,0.46,0.22,1)
    local function CheckStroke(x1,y1,x2,y2)
        local line = badge:CreateLine(nil,"OVERLAY")
        line:SetStartPoint("CENTER",badge,x1,y1)
        line:SetEndPoint("CENTER",badge,x2,y2)
        line:SetThickness(3)
        line:SetColorTexture(1,1,1,1)
    end
    CheckStroke(-5,0,-1,-4)
    CheckStroke(-1,-4,6,4)
    button.check = badge
    button.name = Font(button,14,{0.98,0.90,0.77},"CENTER")
    button.name:SetPoint("TOP",button,"BOTTOM",0,-4)
    button.name:SetWidth(153)
    button.name:SetShadowColor(0,0,0,1)
    button.name:SetShadowOffset(1,-1)
    button.name:SetWordWrap(false)
    button.subtitle = Font(button,11,{0.75,0.83,0.88},"CENTER")
    button.subtitle:SetPoint("TOP",button.name,"BOTTOM",0,-4)
    button.subtitle:SetWidth(153)
    button.subtitle:SetWordWrap(false)
    button:SetScript("OnClick",function(self)
        if self.node.zone == ActiveZone() then SelectQuest(self.node.quest.id)
        else JumpToNode(self.node) end
    end)
    button:SetScript("OnEnter",function(self)
        self.hovered = true
        PaintQuestNode(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(QuestName(self.node.quest))
        GameTooltip:AddLine(self.tooltipText,0.86,0.78,0.62,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function(self)
        self.hovered = false
        PaintQuestNode(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    button:SetScript("OnHide",button:GetScript("OnLeave"))
    rows[index] = button
    return button
end

local function ApplyTreeCamera(frame)
    local viewport, canvas, camera = frame.treeViewport, frame.treeCanvas, frame.treeCamera
    local width, height = viewport:GetWidth(),viewport:GetHeight()
    local function Clamp(offset, view, size)
        if size <= view then return (view-size)/2 end
        return math.max(view-size-36,math.min(36,offset))
    end
    camera.x = Clamp(camera.x,width,canvas:GetWidth()*camera.zoom)
    camera.y = Clamp(camera.y,height,canvas:GetHeight()*camera.zoom)
    canvas:SetScale(camera.zoom)
    canvas:ClearAllPoints()
    canvas:SetPoint("TOPLEFT",viewport,"TOPLEFT",camera.x/camera.zoom,-camera.y/camera.zoom)
end

local function CenterTree(frame, point)
    local camera, viewport = frame.treeCamera, frame.treeViewport
    camera.x, camera.y = 0, 0
    if point then
        camera.x = viewport:GetWidth()/2-point.x*camera.zoom
        camera.y = viewport:GetHeight()/2-point.y*camera.zoom
    end
    ApplyTreeCamera(frame)
end

local function UpdateTreeSearch(frame)
    local query = SearchText():match("^%s*(.-)%s*$")
    local searching = query ~= ""
    local matches = frame.treeSearchMatches
    wipe(matches)
    if query ~= frame.treeSearchQuery then frame.treeSearchIndex = 0 end
    frame.treeSearchQuery = query
    for _,button in ipairs(rows) do
        if button:IsShown() then
            button.searchMatch = searching and QuestName(button.node.quest):lower():find(query,1,true) ~= nil
            button.searchDimmed = searching and not button.searchMatch
            if button.searchMatch then table.insert(matches,button.node.quest.id) end
            PaintQuestNode(button)
        end
    end
    if searching then
        local result = #matches > 0 and string.format(L("searchResults"),#matches) or L("searchNone")
        frame.treeSearchInfo:SetText(result)
    end
    frame.treeSearchInfo:SetShown(searching)
end

local function ConfigureTreeCamera(frame)
    local viewport, camera = frame.treeViewport, frame.treeCamera
    local function Cursor()
        local x,y = GetCursorPosition()
        local scale = viewport:GetEffectiveScale()
        return x/scale-viewport:GetLeft(), viewport:GetTop()-y/scale
    end
    viewport:EnableMouse(true)
    viewport:EnableMouseWheel(true)
    viewport:RegisterForDrag("LeftButton")
    viewport:SetScript("OnDragStart",function()
        camera.dragX,camera.dragY = Cursor()
    end)
    local function StopDrag() camera.dragX,camera.dragY = nil,nil end
    viewport:SetScript("OnDragStop",StopDrag)
    viewport:SetScript("OnHide",StopDrag)
    viewport:SetScript("OnUpdate",function()
        if not camera.dragX then return end
        local x,y = Cursor()
        camera.x = camera.x + x-camera.dragX
        camera.y = camera.y + y-camera.dragY
        camera.dragX,camera.dragY = x,y
        ApplyTreeCamera(frame)
    end)
    viewport:SetScript("OnMouseWheel",function(_,delta)
        local x,y = Cursor()
        local zoom = math.max(0.45,math.min(1.45,camera.zoom * 1.16 ^ delta))
        local ratio = zoom/camera.zoom
        camera.x,camera.y = x-(x-camera.x)*ratio, y-(y-camera.y)*ratio
        camera.zoom = zoom
        ApplyTreeCamera(frame)
    end)
end

local function QuestOrder(a,b)
    local qa,qb = a.quest,b.quest
    if (qa.level or 0) ~= (qb.level or 0) then return (qa.level or 0) < (qb.level or 0) end
    if QuestName(qa) ~= QuestName(qb) then return QuestName(qa) < QuestName(qb) end
    return qa.id < qb.id
end

function FQJ.Refresh(focusID)
    local frame = FQJ.Frame
    if not frame or not frame.zoneContent:IsShown() then return end
    local zone, graph = ActiveZone(), FQJ.GetQuestTree()
    local chains, singles, included = {}, {}, {}
    local totals = { completed=0, active=0, unstarted=0 }
    for id in pairs(zone.quests) do
        local node = graph[id]
        if node then
            local status = FQJ.GetQuestStatus(id)
            totals[status] = totals[status] + 1
            local group = node.group
            if #group.nodes == 1 then
                table.insert(singles,node)
            elseif not included[group] then
                included[group] = true
                table.insert(chains,group)
            end
        end
    end
    table.sort(chains,function(a,b) return QuestOrder(a.roots[1] or a.nodes[1], b.roots[1] or b.nodes[1]) end)
    table.sort(singles,QuestOrder)
    local canvas = frame.treeCanvas
    local y, width, nodeIndex, lineIndex, headingIndex = 18, 0, 0, 0, 0
    local positions, firstLocal = {}, nil

    local function Heading(label)
        headingIndex = headingIndex + 1
        local heading = frame.treeHeadings[headingIndex]
        if not heading then
            heading = Font(canvas,12,{0.86,0.68,0.40})
            frame.treeHeadings[headingIndex] = heading
        end
        heading:ClearAllPoints()
        heading:SetPoint("TOPLEFT",canvas,"TOPLEFT",26,-y)
        heading:SetText(label)
        heading:Show()
        y = y + 48
    end

    local function Place(node, x, top)
        nodeIndex = nodeIndex + 1
        local button = AcquireNode(canvas,nodeIndex)
        button.node = node
        button:ClearAllPoints()
        button:SetPoint("CENTER",canvas,"TOPLEFT",x,-top)
        button.name:SetText(QuestName(node.quest))
        local status,label,color = StatusText(node.quest.id)
        local remote = node.zone ~= zone
        local locked = status == "unfinished" and node.zone and
            (not FQJ.ArePrerequisitesMet(node.quest) or UnitLevel("player") < (node.quest.requiredLevel or 0))
        local place = node.zone and ZoneName(node.zone) or L("unavailableZone")
        if locked then label = label .. "  ·  " .. L("locked") end
        button.tooltipText = place .. "  ·  " .. label
        button.color = color
        local art = NODE_ART.step
        if remote then art = NODE_ART.remote
        elseif locked then art = NODE_ART.locked
        elseif #node.before == 0 and #node.after > 0 then art = NODE_ART.start end
        button.icon:SetTexture(art)
        button.check:SetShown(status == "completed")
        local subtitle = locked and L("locked") or ""
        if remote then subtitle = place
        elseif #node.before == 0 and #node.after > 0 then subtitle = L("startStep") end
        button.subtitle:SetText(subtitle)
        PaintQuestNode(button)
        button:Show()
        if node.zone == zone then firstLocal = firstLocal or node.quest.id end
        positions[node.quest.id] = { x=x,y=top }
    end

    local function DrawEdge(edge)
        local from, to = positions[edge.from.quest.id],positions[edge.to.quest.id]
        lineIndex = lineIndex + 1
        local line = frame.treeLines[lineIndex]
        if not line then
            line = canvas:CreateLine(nil,"ARTWORK")
            frame.treeLines[lineIndex] = line
        end
        line:SetStartPoint("TOPLEFT",canvas,from.x,-from.y)
        line:SetEndPoint("TOPLEFT",canvas,to.x,-to.y)
        line:SetThickness(3)
        if edge.kind == "alternative" then line:SetColorTexture(0.57,0.66,0.78,0.68)
        else line:SetColorTexture(0.71,0.51,0.27,0.80) end
        line:Show()
    end

    local columnGap, rowGap = 174, 128
    for _,group in ipairs(chains) do
        Heading(string.format(L("chain"),#group.nodes))
        local columns, lanes = FQJ.LayoutQuestChain(group), 1
        for _,column in ipairs(columns) do lanes = math.max(lanes,#column) end
        for index,column in ipairs(columns) do
            local x = 79 + (index-1)*columnGap
            local top = y + (lanes-#column)*rowGap/2
            for lane,node in ipairs(column) do Place(node,x,top+(lane-1)*rowGap) end
            width = math.max(width,x+79)
        end
        for _,node in ipairs(group.nodes) do
            for _,edge in ipairs(node.after) do DrawEdge(edge) end
        end
        y = y + (lanes-1)*rowGap + 120
    end
    if #singles > 0 then
        Heading(L("standalone"))
        local perRow = math.max(1,math.floor(frame.treeViewport:GetWidth()/columnGap))
        for index,node in ipairs(singles) do
            Place(node,79+(index-1)%perRow*columnGap,y+math.floor((index-1)/perRow)*rowGap)
        end
        width = math.max(width,math.min(perRow,#singles)*columnGap)
        y = y + math.ceil(#singles/perRow)*rowGap
    end
    if nodeIndex == 0 then Heading(L("empty")); width = frame.treeViewport:GetWidth() end
    for i=nodeIndex+1,#rows do rows[i]:Hide() end
    for i=lineIndex+1,#frame.treeLines do frame.treeLines[i]:Hide() end
    for i=headingIndex+1,#frame.treeHeadings do frame.treeHeadings[i]:Hide() end
    canvas:SetSize(math.max(1,width),math.max(1,y))
    frame.treePositions = positions
    frame.progress:SetText(string.format(L("progress"),totals.completed,totals.active+totals.unstarted))
    if not positions[selectedQuestID] then selectedQuestID = firstLocal end
    if selectedQuestID and (focusID or frame.detail:IsShown()) then
        SelectQuest(selectedQuestID)
    elseif not selectedQuestID then
        frame.detail:Hide()
    end
    UpdateTreeSearch(frame)
    if frame.treeReset or focusID then
        CenterTree(frame,positions[focusID or selectedQuestID])
        frame.treeReset = nil
    else
        ApplyTreeCamera(frame)
    end
end
local function CreateTreeLegend(frame, parent)
    local title=Font(parent,11,{0.90,0.72,0.41})
    title:SetPoint("BOTTOMLEFT",14,13)
    frame.treeLegend = { legend=title }
    local previous = title
    local function Entry(key, texture, color)
        local icon = parent:CreateTexture(nil,"ARTWORK")
        icon:SetTexture(texture)
        local size = color and 10 or 22
        icon:SetSize(size,size)
        icon:SetPoint("LEFT",previous,"RIGHT",14,0)
        if color then icon:SetVertexColor(unpack(color)) end
        local label=Font(parent,11,{0.86,0.80,0.69})
        label:SetPoint("LEFT",icon,"RIGHT",5,0)
        frame.treeLegend[key] = label
        previous = label
    end
    Entry("legendStart",NODE_ART.start)
    Entry("legendStep",NODE_ART.step)
    Entry("legendLocked",NODE_ART.locked)
    Entry("legendRemote",NODE_ART.remote)
    Entry("unfinished",DISC_TEXTURE,COLORS.unfinished)
    Entry("legendActive",DISC_TEXTURE,COLORS.active)
    Entry("completed",DISC_TEXTURE,COLORS.completed)
end
local function ApplyLanguage()
    local frame=FQJ.Frame; if not frame then return end
    if FQJ.MarkZonePinsDirty then FQJ.MarkZonePinsDirty() end
    if frame.languageMenu then frame.languageMenu:Hide() end
    local activeLanguage=Language(); frame.languageText:SetText(activeLanguage=="frFR" and "Français" or "English"); frame.languageCode:SetText(activeLanguage=="frFR" and "FR" or "EN")
    if frame.languageOptions then
        for code,option in pairs(frame.languageOptions) do
            local selected=code==activeLanguage
            option.check:SetShown(selected); option.label:SetTextColor(selected and 1.00 or 0.86,selected and 0.82 or 0.81,selected and 0.27 or 0.72)
            option.code:SetTextColor(selected and 1.00 or 0.62,selected and 0.82 or 0.59,selected and 0.27 or 0.53)
        end
    end
    frame.placeholder:SetText(L("search"))
    frame.treeCenter:SetText(L("center"))
    frame.treeBack:SetText(L("treeBack"))
    frame.treeControls:SetText(L("treeControls"))
    for key,label in pairs(frame.treeLegend) do label:SetText(L(key)) end
    frame.detail.mapButton:SetText(L("showMap"))
    if frame.home:IsShown() then
        FQJ.RefreshHome()
    else
        FQJ.ShowZone(activeZoneKey,frame.detail:IsShown() and selectedQuestID or nil)
    end
end

function FQJ.CreateUI()
    local frame=CreateFrame("Frame","ForeverQuestJournalFrame",UIParent,"BackdropTemplate"); frame:SetSize(850,590); frame:SetPoint("CENTER",0,10); frame:SetFrameStrata(FQJ.MAIN_FRAME_STRATA or "DIALOG"); frame:SetFrameLevel(FQJ.MAIN_FRAME_LEVEL or 20)
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart",frame.StartMoving); frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    frame:SetScript("OnMouseDown",function() if FQJ.BringToFront then FQJ.BringToFront() end end)
    frame:SetBackdrop({bgFile="Interface\\FrameGeneral\\UI-Background-Rock",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=6,right=6,top=6,bottom=6}}); frame:SetBackdropColor(0.045,0.042,0.037,0.99)
    local top=frame:CreateTexture(nil,"BACKGROUND"); top:SetColorTexture(0.14,0.10,0.055,0.96); top:SetPoint("TOPLEFT",12,-10); top:SetPoint("TOPRIGHT",-12,-10); top:SetHeight(34)
    local title=Font(frame,16,{0.96,0.79,0.25},"CENTER"); title:SetPoint("TOP",0,-18); title:SetText("Forever Quest Journal")
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3)
    local searchBox=CreateFrame("EditBox",nil,frame,"BackdropTemplate"); searchBox:SetSize(265,26); searchBox:SetPoint("TOPLEFT",18,-14); searchBox:SetAutoFocus(false); searchBox:SetMaxLetters(40); searchBox:SetFont("Fonts\\FRIZQT__.TTF",12,""); searchBox:SetTextInsets(27,28,0,0); searchBox:SetTextColor(0.94,0.91,0.84)
    Backdrop(searchBox,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border"); searchBox:SetBackdropColor(0.045,0.043,0.040,0.98); searchBox:SetBackdropBorderColor(0.34,0.31,0.27,1)
    local searchIcon=searchBox:CreateTexture(nil,"ARTWORK"); searchIcon:SetSize(14,14); searchIcon:SetPoint("LEFT",7,0); searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    local placeholder=Font(searchBox,12,{0.55,0.54,0.50}); placeholder:SetPoint("LEFT",28,0)
    local clearSearch = CreateFrame("Button",nil,searchBox)
    clearSearch:SetSize(21,21)
    clearSearch:SetPoint("RIGHT",searchBox,"RIGHT",-3,0)
    local clearGlyph = Font(clearSearch,16,{0.74,0.71,0.64},"CENTER")
    clearGlyph:SetPoint("CENTER")
    clearGlyph:SetText("×")
    clearSearch:SetScript("OnEnter",function() clearGlyph:SetTextColor(1,0.85,0.45) end)
    clearSearch:SetScript("OnLeave",function() clearGlyph:SetTextColor(0.74,0.71,0.64) end)
    clearSearch:SetScript("OnHide",clearSearch:GetScript("OnLeave"))
    clearSearch:SetScript("OnClick",function()
        searchBox:SetText("")
        searchBox:ClearFocus()
    end)
    clearSearch:Hide()
    searchBox:SetScript("OnTextChanged",function(self)
        local hasText = (self:GetText() or "") ~= ""
        clearSearch:SetShown(hasText)
        placeholder:SetShown(not hasText and not self:HasFocus())
        if frame.suppressSearchRefresh then return end
        if frame.home and frame.home:IsShown() then
            FQJ.RefreshHome()
        elseif frame.zoneContent and frame.zoneContent:IsShown() then
            UpdateTreeSearch(frame)
        end
    end)
    searchBox:SetScript("OnEnterPressed",function(self)
        if frame.zoneContent and frame.zoneContent:IsShown() and #frame.treeSearchMatches > 0 then
            frame.treeSearchIndex = frame.treeSearchIndex % #frame.treeSearchMatches + 1
            local id = frame.treeSearchMatches[frame.treeSearchIndex]
            CenterTree(frame,frame.treePositions[id])
            return
        end
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEditFocusGained",function() placeholder:Hide() end); searchBox:SetScript("OnEditFocusLost",function(self) placeholder:SetShown((self:GetText() or "")=="") end); searchBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    frame.searchBox,frame.placeholder=searchBox,placeholder
    frame.treeSearchMatches,frame.treeSearchIndex = {},0
    frame.treeSearchInfo=Font(frame,11,{0.84,0.72,1})
    frame.treeSearchInfo:SetPoint("LEFT",searchBox,"RIGHT",10,0)
    frame.treeSearchInfo:Hide()
    local language=CreateFrame("Button",nil,frame,"BackdropTemplate"); language:SetSize(132,26); language:SetPoint("TOPRIGHT",frame,"TOPRIGHT",-49,-14)
    language:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); language:SetBackdropColor(0.075,0.073,0.068,0.98); language:SetBackdropBorderColor(0.30,0.29,0.25,1)
    local codeBadge=CreateFrame("Frame",nil,language,"BackdropTemplate"); codeBadge:SetSize(28,18); codeBadge:SetPoint("LEFT",5,0); codeBadge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); codeBadge:SetBackdropColor(0.20,0.145,0.055,1); codeBadge:SetBackdropBorderColor(0.58,0.41,0.13,1)
    frame.languageCode=Font(codeBadge,10,{1,0.82,0.27},"CENTER"); frame.languageCode:SetPoint("CENTER",0,0)
    frame.languageText=Font(language,12,{0.93,0.88,0.78},"LEFT"); frame.languageText:SetPoint("LEFT",40,0)
    local languageCaret=language:CreateTexture(nil,"OVERLAY"); languageCaret:SetTexture("Interface\\Buttons\\Arrow-Down-Up"); languageCaret:SetSize(12,12); languageCaret:SetPoint("RIGHT",-7,-3)
    local hover=language:CreateTexture(nil,"HIGHLIGHT"); hover:SetTexture("Interface\\Buttons\\WHITE8X8"); hover:SetAllPoints(); hover:SetColorTexture(1,0.76,0.20,0.07)
    local languageMenu=CreateFrame("Frame",nil,frame,"BackdropTemplate"); languageMenu:SetSize(154,76); languageMenu:SetPoint("TOPRIGHT",language,"BOTTOMRIGHT",0,-4); languageMenu:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); languageMenu:SetBackdropColor(0.045,0.043,0.039,0.995); languageMenu:SetBackdropBorderColor(0.34,0.31,0.25,1); languageMenu:SetFrameStrata(FQJ.MAIN_FRAME_STRATA or "DIALOG"); languageMenu:SetFrameLevel((FQJ.MAIN_FRAME_LEVEL or 20)+100); languageMenu:Hide()
    frame.languageOptions={}
    local function LanguageOption(label,shortCode,code,y)
        local option=CreateFrame("Button",nil,languageMenu); option:SetSize(144,31); option:SetPoint("TOPLEFT",5,y)
        local optionHover=option:CreateTexture(nil,"HIGHLIGHT"); optionHover:SetTexture("Interface\\Buttons\\WHITE8X8"); optionHover:SetAllPoints(); optionHover:SetColorTexture(1,0.72,0.18,0.09)
        option.code=Font(option,10,{0.62,0.59,0.53},"CENTER"); option.code:SetPoint("LEFT",8,0); option.code:SetWidth(24); option.code:SetText(shortCode)
        option.label=Font(option,12,{0.86,0.81,0.72},"LEFT"); option.label:SetPoint("LEFT",39,0); option.label:SetText(label)
        option.check=option:CreateTexture(nil,"OVERLAY"); option.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check"); option.check:SetSize(18,18); option.check:SetPoint("RIGHT",-7,0)
        option:SetScript("OnClick",function() FQJ.DB.language=code; languageMenu:Hide(); ApplyLanguage() end)
        frame.languageOptions[code]=option
    end
    LanguageOption("English","EN","enUS",-6); LanguageOption("Français","FR","frFR",-39)
    language:SetScript("OnClick",function() languageMenu:SetShown(not languageMenu:IsShown()) end); frame.languageMenu=languageMenu
    local content=CreateFrame("Frame",nil,frame,"BackdropTemplate"); content:SetPoint("TOPLEFT",18,-50); content:SetPoint("BOTTOMRIGHT",-18,16); Backdrop(content); content:SetBackdropColor(0.17,0.12,0.07,0.96); content:SetBackdropBorderColor(0.47,0.34,0.16,1); frame.zoneContent=content
    local header=CreateFrame("Frame",nil,content,"BackdropTemplate"); header:SetPoint("TOPLEFT",8,-8); header:SetPoint("TOPRIGHT",-8,-8); header:SetHeight(42); Backdrop(header); header:SetBackdropColor(0.24,0.17,0.09,0.94); header:SetBackdropBorderColor(0.52,0.33,0.11,1)
    local zoneLink = CreateFrame("Button",nil,header)
    zoneLink:SetPoint("TOPLEFT",14,-2)
    zoneLink:SetPoint("BOTTOMLEFT",14,2)
    frame.zoneTitle=Font(zoneLink,20,{1,0.82,0.27})
    frame.zoneTitle:SetPoint("LEFT")
    frame.zoneTitle:SetWordWrap(false)
    frame.zoneLink = zoneLink
    zoneLink:SetScript("OnClick",function()
        frame.suppressSearchRefresh = true
        frame.searchBox:SetText("")
        frame.searchBox:ClearFocus()
        frame.suppressSearchRefresh = nil
        FQJ.ShowHome()
    end)
    zoneLink:SetScript("OnEnter",function(self)
        frame.zoneTitle:SetTextColor(1,0.93,0.61)
        GameTooltip:SetOwner(self,"ANCHOR_BOTTOM")
        GameTooltip:SetText(L("zoneGallery"))
        GameTooltip:Show()
    end)
    local function ResetZoneLink(self)
        frame.zoneTitle:SetTextColor(1,0.82,0.27)
        if GameTooltip and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    zoneLink:SetScript("OnLeave",ResetZoneLink)
    zoneLink:SetScript("OnHide",ResetZoneLink)
    frame.zoneMeta=Font(header,11,{0.88,0.80,0.66},"RIGHT"); frame.zoneMeta:SetPoint("RIGHT",-14,0)
    local listPanel=CreateFrame("Frame",nil,content,"BackdropTemplate"); listPanel:SetPoint("TOPLEFT",8,-56); listPanel:SetPoint("BOTTOMRIGHT",-8,8); Backdrop(listPanel); listPanel:SetBackdropColor(0.19,0.13,0.07,0.94); listPanel:SetBackdropBorderColor(0.39,0.24,0.08,1)
    local viewport = CreateFrame("Frame",nil,listPanel,"BackdropTemplate")
    viewport:SetPoint("TOPLEFT",10,-40)
    viewport:SetPoint("BOTTOMRIGHT",-10,38)
    viewport:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    viewport:SetBackdropColor(0.09,0.067,0.045,1)
    viewport:SetBackdropBorderColor(0.35,0.25,0.15,1)
    viewport:SetClipsChildren(true)
    frame.treeViewport = viewport
    frame.treeCanvas = CreateFrame("Frame",nil,viewport)
    frame.treeCamera = { x=0,y=0,zoom=1 }
    frame.treeHistory = {}
    frame.treeLines, frame.treeHeadings = {}, {}
    ConfigureTreeCamera(frame)
    frame.treeCenter = CreateFlatButton(listPanel,96,22)
    frame.treeCenter:SetPoint("TOPRIGHT",-10,-10)
    frame.treeCenter:SetScript("OnClick",function()
        CenterTree(frame,frame.treePositions and frame.treePositions[selectedQuestID])
    end)
    frame.treeBack = CreateFlatButton(listPanel,96,22)
    frame.treeBack:SetPoint("RIGHT",frame.treeCenter,"LEFT",-8,0)
    frame.treeBack:SetEnabled(false)
    frame.treeBack:SetScript("OnClick",ReturnToPreviousZone)
    frame.treeBack:HookScript("OnEnter",function(self)
        local view = frame.treeHistory[#frame.treeHistory]
        if not view then return end
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(string.format(L("treeBackTo"),ZoneName(FQJ.Zones[view.zoneKey])))
        GameTooltip:Show()
    end)
    frame.treeBack:HookScript("OnLeave",function(self)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)
    frame.treeControls = Font(listPanel,10,{0.78,0.68,0.52})
    frame.treeControls:SetPoint("TOPLEFT",13,-16)
    CreateTreeLegend(frame,listPanel)
    frame.progress=Font(listPanel,11,{0.76,0.63,0.37},"RIGHT"); frame.progress:SetPoint("BOTTOMRIGHT",listPanel,"BOTTOMRIGHT",-14,13); frame.listPanel=listPanel

    local detail = CreateFrame("Frame",nil,viewport,"BackdropTemplate")
    detail:SetSize(412,DETAIL_VERTICAL_CHROME+1)
    detail:SetPoint("TOPRIGHT",viewport,"TOPRIGHT",-DETAIL_EDGE_MARGIN,-DETAIL_EDGE_MARGIN)
    detail:SetFrameLevel(viewport:GetFrameLevel()+15)
    detail:EnableMouse(true)
    Backdrop(detail)
    detail:SetBackdropColor(0.15,0.103,0.057,1)
    detail:SetBackdropBorderColor(0.80,0.60,0.30,1)
    local inset=CreateFrame("Frame",nil,detail,"BackdropTemplate"); inset:SetPoint("TOPLEFT",8,-8); inset:SetPoint("BOTTOMRIGHT",-14,8); inset:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}}); inset:SetBackdropColor(0.19,0.13,0.07,0.98); inset:SetBackdropBorderColor(0.36,0.23,0.09,1)
    local questIcon=inset:CreateTexture(nil,"ARTWORK"); questIcon:SetSize(42,42); questIcon:SetPoint("TOPLEFT",14,-12); questIcon:SetTexture(ICONS.giver); questIcon:SetTexCoord(0,1,0,1); detail.questIcon=questIcon
    detail.title=Font(inset,16,{1.00,0.80,0.28}); detail.title:SetPoint("TOPLEFT",66,-12); detail.title:SetPoint("RIGHT",-42,0); detail.title:SetWordWrap(false); detail.title:SetShadowColor(0,0,0,0.9); detail.title:SetShadowOffset(1,-1)
    detail.level=Font(inset,11,{0.84,0.76,0.62}); detail.level:SetPoint("TOPLEFT",detail.title,"BOTTOMLEFT",0,-5)
    detail.status=Font(inset,10,{0.84,0.76,0.62}); detail.status:SetPoint("TOPLEFT",detail.level,"BOTTOMLEFT",0,-5)
    local grip = CreateFrame("Frame",nil,inset)
    grip:SetPoint("TOPLEFT",inset,"TOPLEFT",0,0)
    grip:SetPoint("TOPRIGHT",inset,"TOPRIGHT",-42,0)
    grip:SetHeight(68)
    grip:EnableMouse(true)
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart",function(self)
        local x,y = GetCursorPosition()
        self.dragX,self.dragY = x,y
        self.startLeft = detail:GetLeft()-viewport:GetLeft()
        self.startTop = viewport:GetTop()-detail:GetTop()
    end)
    grip:SetScript("OnUpdate",function(self)
        if not self.dragX then return end
        local x,y = GetCursorPosition()
        local scale = viewport:GetEffectiveScale()
        detail.dragged = true
        PositionQuestDetail(detail,self.startLeft+(x-self.dragX)/scale,self.startTop+(self.dragY-y)/scale)
    end)
    local function StopDetailDrag(self) self.dragX = nil end
    grip:SetScript("OnDragStop",StopDetailDrag)
    grip:SetScript("OnHide",StopDetailDrag)
    local closeDetail = CreateFlatButton(inset,32,32,"primary")
    closeDetail:SetPoint("TOPRIGHT",-4,-4)
    closeDetail.label:SetFont("Fonts\\FRIZQT__.TTF",22,"OUTLINE")
    closeDetail:SetText("×")
    closeDetail:SetSelected(true)
    local closeHighlight = closeDetail:CreateTexture(nil,"HIGHLIGHT")
    closeHighlight:SetAllPoints()
    closeHighlight:SetColorTexture(1,0.83,0.38,0.15)
    closeDetail:SetScript("OnClick",function()
        detail:Hide()
        for _,button in ipairs(rows) do
            if button:IsShown() then PaintQuestNode(button) end
        end
    end)
    local divider=inset:CreateTexture(nil,"ARTWORK"); divider:SetColorTexture(0.49,0.31,0.10,0.9); divider:SetPoint("TOPLEFT",14,-68); divider:SetPoint("TOPRIGHT",-14,-68); divider:SetHeight(1)
    detail.scrollFrame=CreateFrame("ScrollFrame",nil,inset,"UIPanelScrollFrameTemplate"); detail.scrollFrame:SetPoint("TOPLEFT",13,-78); detail.scrollFrame:SetPoint("BOTTOMRIGHT",-30,50)
    detail.scrollFrame:HookScript("OnScrollRangeChanged",function(self)
        if self.ScrollBar then self.ScrollBar:SetShown(self.questDetailsOverflow == true) end
    end)
    detail.scrollChild=CreateFrame("Frame",nil,detail.scrollFrame); detail.scrollChild:SetWidth(343); detail.scrollChild:SetHeight(1); detail.scrollFrame:SetScrollChild(detail.scrollChild); detail.content,detail.lines=detail.scrollChild,{}
    detail.mapButton=CreateFlatButton(inset,180,27,"primary"); detail.mapButton:SetPoint("BOTTOM",0,18); detail.mapButton:SetScript("OnClick",function() local zone=ActiveZone(); FQJ.ShowQuestStartOnMap(zone.quests[selectedQuestID],zone) end); frame.detail=detail
    detail:Hide()

    local home=CreateFrame("Frame",nil,frame,"BackdropTemplate"); home:SetPoint("TOPLEFT",18,-52); home:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(home); home:SetBackdropColor(0.16,0.12,0.07,0.96); home:SetBackdropBorderColor(0.47,0.34,0.16,1); frame.home=home
    local homeScroll=CreateFrame("ScrollFrame",nil,home,"UIPanelScrollFrameTemplate"); homeScroll:SetPoint("TOPLEFT",18,-10); homeScroll:SetPoint("BOTTOMRIGHT",-28,12)
    frame.homeChild=CreateFrame("Frame",nil,homeScroll); frame.homeChild:SetWidth(742); frame.homeChild:SetHeight(500); homeScroll:SetScrollChild(frame.homeChild); frame.zoneCards,frame.homeHeaders={},{}
    tinsert(UISpecialFrames,frame:GetName()); FQJ.Frame=frame; ApplyLanguage(); FQJ.ShowHome()
end
