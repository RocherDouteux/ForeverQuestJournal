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
    map = ICON_PATH .. "Map",
}

local TEXT = {
    enUS = {
        search = "Search for Zones, Quests...", zones = "Zones", quests = "Quests", map = "Map",
        unfinished = "Unfinished", completed = "Finished", status_unfinished = "UNFINISHED", status_active = "IN QUEST LOG", status_completed = "FINISHED",
        locked = "LOCKED", questLevel = "Quest level %d  -  Requires level %d", giver = "QUEST GIVER",
        starts = "Starts from", item = "Starts from item", unknown = "Quest start: Unknown",
        objective = "OBJECTIVE", prerequisites = "PREREQUISITES", none = "None", any = "Complete any one of:",
        next = "NEXT IN CHAIN", rewards = "POSSIBLE REWARDS", showMap = "Show Start on Map", level = "Lv %d", zoneLevel = "LV AVG %s  ·  MED %s", range = "LV %d-%d",
        progress = "%d finished   -   %d unfinished", count = "%d/%d quests",
        other = "Other", eastern = "Eastern Kingdoms", kalimdor = "Kalimdor",
    },
    frFR = {
        search = "Rechercher une zone ou une quête...", zones = "Zones", quests = "Quêtes", map = "Carte",
        unfinished = "Inachevées", completed = "Terminées", status_unfinished = "INACHEVÉE", status_active = "DANS LE JOURNAL", status_completed = "TERMINÉE",
        locked = "VERROUILLÉE", questLevel = "Niveau %d  -  Niveau requis %d", giver = "DONNEUR DE QUÊTE",
        starts = "Commence auprès de", item = "Objet de départ", unknown = "Départ de quête : inconnu",
        objective = "OBJECTIF", prerequisites = "PRÉREQUIS", none = "Aucun", any = "Terminez l'une de ces quêtes :",
        next = "SUITE DE LA CHAÎNE", rewards = "RÉCOMPENSES POSSIBLES", showMap = "Voir le départ sur la carte", level = "Niv. %d", zoneLevel = "NIV. MOY. %s  ·  MÉD. %s", range = "NIV. %d-%d",
        progress = "%d terminées   -   %d inachevées", count = "%d/%d quêtes",
        other = "Autres", eastern = "Royaumes de l'Est", kalimdor = "Kalimdor",
    },
}

local rows, selectedQuestID, activeZoneKey = {}, nil, "zone_12"
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
local function SetFilter(filter) FQJ.DB.filter = filter; FQJ.Refresh() end

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
    frame.home:Show(); frame.zoneContent:Hide(); frame.backButton:Hide(); frame.prevZone:Hide(); frame.nextZone:Hide(); frame.searchBox:Show()
    for _,button in pairs(frame.filterButtons) do button:Hide() end
    FQJ.RefreshHome()
end
function FQJ.ShowZone(zoneKey)
    local frame=FQJ.Frame; if not frame then return end
    if zoneKey and FQJ.Zones[zoneKey] then activeZoneKey=zoneKey end
    selectedQuestID=nil; frame.home:Hide(); frame.zoneContent:Show(); frame.backButton:Show(); frame.prevZone:Show(); frame.nextZone:Show(); frame.searchBox:Show()
    for _,button in pairs(frame.filterButtons) do button:Show() end
    local zone=ActiveZone(); local stats=ZoneStats(zone); frame.zoneTitle:SetText(ZoneName(zone).." ("..string.format(L("range"),stats.minLevel,stats.maxLevel)..")"); frame.zoneMeta:SetText(ZoneLevelText(stats)); frame.zoneRange:SetText(""); FQJ.Refresh()
end

local function NavigateZone(delta)
    local zones, current = SortedZones(), 1
    for index, zone in ipairs(zones) do if zone.key == activeZoneKey then current = index break end end
    local target = ((current - 1 + delta) % #zones) + 1
    FQJ.Frame.searchBox:SetText("")
    FQJ.ShowZone(zones[target].key)
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
local function SelectQuest(questID)
    selectedQuestID=questID
    local zone,detail=ActiveZone(),FQJ.Frame.detail; local quest=zone and zone.quests[questID]; if not quest then return end
    detail.title:SetText(QuestName(quest)); detail.level:SetText(string.format(L("questLevel"),quest.level or 0,quest.requiredLevel or 0))
    local rawStatus=FQJ.GetQuestStatus(questID); local _,label,color=StatusText(questID); detail.status:SetText(label); detail.status:SetTextColor(unpack(color)); detail.questIcon:SetTexture(rawStatus=="active" and ICONS.active or ICONS.giver)
    for _,old in ipairs(detail.lines) do old:Hide() end; wipe(detail.lines)
    local anchor
    local function block(label,value,icon,color)
        local item=AddDetailBlock(detail.content,anchor,label,value,icon,color); table.insert(detail.lines,item); anchor=item
    end
    if quest.start then
        local kind=quest.start.kind=="npc" and L("giver") or (quest.start.kind=="object" and L("starts") or L("item"))
        block(kind,Localized(quest.start,"name"),ICONS.giver)
    else block(L("starts"),L("unknown"),ICONS.giver) end
    local objective=Localized(quest,"objective")
    if objective~="" then block(L("objective"),objective,ICONS.objective) end
    local all,any=quest.prerequisitesAll or {},quest.prerequisitesAny or {}; local prerequisiteLines={}
    for _,pre in ipairs(all) do local done=FQJ.IsCompleted(pre.id); table.insert(prerequisiteLines,(done and "|cFF45B854[done]|r " or "|cFFC88A65[ ]|r ")..Localized(pre,"name")) end
    if #any>0 then
        table.insert(prerequisiteLines,L("any"))
        for _,pre in ipairs(any) do local done=FQJ.IsCompleted(pre.id); table.insert(prerequisiteLines,(done and "|cFF45B854[done]|r " or "|cFFC88A65[ ]|r ")..Localized(pre,"name")) end
    end
    if #prerequisiteLines==0 then table.insert(prerequisiteLines,L("none")) end
    block(L("prerequisites"),table.concat(prerequisiteLines,"\n"),ICONS.prerequisites)
    if quest.nextQuest then block(L("next"),Localized(quest.nextQuest,"name"),ICONS.next) end
    if quest.rewards and #quest.rewards>0 then local item=AddRewardsBlock(detail.content,anchor,quest.rewards); table.insert(detail.lines,item); anchor=item end
    detail.mapButton:SetEnabled(quest.start and quest.start.x and quest.start.y); detail.mapButton:SetAlpha(detail.mapButton:IsEnabled() and 1 or 0.45)
    detail.scrollChild:SetHeight(math.max(460,anchor and (detail.scrollChild:GetTop()-anchor:GetBottom()+35) or 460)); detail.scrollFrame:SetVerticalScroll(0)
    for _,row in ipairs(rows) do
        if row.questID==questID then row:SetBackdropColor(0.34,0.21,0.07,0.98) else row:SetBackdropColor(0.12,0.08,0.04,0.90) end
    end
end
local function AcquireRow(parent,index)
    if rows[index] then return rows[index] end
    local row=CreateFrame("Button",nil,parent,"BackdropTemplate"); row:SetSize(292,44); Backdrop(row); row:SetBackdropColor(0.12,0.08,0.04,0.90); row:SetBackdropBorderColor(0.42,0.29,0.12,1)
    row.name=Font(row,12,{0.95,0.82,0.55}); row.name:SetPoint("TOPLEFT",10,-7); row.name:SetPoint("RIGHT",-52,0); row.name:SetWordWrap(false)
    row.level=Font(row,11,{0.72,0.62,0.42},"RIGHT"); row.level:SetPoint("TOPRIGHT",-8,-7)
    row.state=Font(row,9,{0.78,0.78,0.78}); row.state:SetPoint("BOTTOMLEFT",10,7)
    row.activeIcon=row:CreateTexture(nil,"ARTWORK"); row.activeIcon:SetSize(16,16); row.activeIcon:SetPoint("BOTTOMRIGHT",-7,4); row.activeIcon:SetTexture(ICONS.active); row.activeIcon:SetTexCoord(0,1,0,1); row.activeIcon:Hide()
    row:SetScript("OnClick",function(self) SelectQuest(self.questID) end); row:SetScript("OnEnter",function(self) self:SetBackdropBorderColor(0.93,0.72,0.28,1) end); row:SetScript("OnLeave",function(self) self:SetBackdropBorderColor(0.42,0.29,0.12,1) end)
    rows[index]=row; return row
end
function FQJ.Refresh()
    if not FQJ.Frame or not FQJ.Frame.zoneContent:IsShown() then return end
    local zone,visible=ActiveZone(),{}; local totals={completed=0,active=0,unstarted=0}; local query=SearchText()
    for _,quest in pairs(zone.quests) do
        if FQJ.IsQuestRelevant(quest) and not quest.special then
            local status=FQJ.GetQuestStatus(quest.id); totals[status]=totals[status]+1
            local filterMatch=(FQJ.DB.filter=="completed" and status=="completed") or (FQJ.DB.filter~="completed" and status~="completed")
            if filterMatch and (query=="" or QuestName(quest):lower():find(query,1,true)) then table.insert(visible,quest) end
        end
    end
    table.sort(visible,function(a,b) if a.level~=b.level then return a.level<b.level end return QuestName(a)<QuestName(b) end)
    for index,quest in ipairs(visible) do
        local row=AcquireRow(FQJ.Frame.listChild,index); row.questID=quest.id; row.name:SetText(QuestName(quest)); row.level:SetText(string.format(L("level"),quest.level or 0))
        local rawStatus=FQJ.GetQuestStatus(quest.id); local _,label,color=StatusText(quest.id); local available=FQJ.ArePrerequisitesMet(quest) and UnitLevel("player")>=(quest.requiredLevel or 0)
        row.state:SetText(label..((rawStatus~="completed" and not available) and "  -  "..L("locked") or "")); row.state:SetTextColor(unpack(color)); row.activeIcon:SetShown(rawStatus=="active"); row:ClearAllPoints(); row:SetPoint("TOPLEFT",0,-(index-1)*47); row:Show()
    end
    for index=#visible+1,#rows do rows[index]:Hide() end
    FQJ.Frame.listChild:SetHeight(math.max(480,#visible*47)); FQJ.Frame.progress:SetText(string.format(L("progress"),totals.completed,totals.active+totals.unstarted))
    for filter,button in pairs(FQJ.Frame.filterButtons) do local selected=filter==FQJ.DB.filter; button:SetSelected(selected); button:SetEnabled(not selected) end
    if selectedQuestID and zone.quests[selectedQuestID] then SelectQuest(selectedQuestID) elseif visible[1] then SelectQuest(visible[1].id) else FQJ.Frame.detail.title:SetText(""); FQJ.Frame.detail.level:SetText(""); FQJ.Frame.detail.status:SetText("") end
end
local function CreateFilter(parent,filter,x)
    local button=CreateFlatButton(parent,76,22); button:SetPoint("TOPLEFT",x,-43); button:SetScript("OnClick",function() SetFilter(filter) end); parent.filterButtons[filter]=button
end
local function ApplyLanguage()
    local frame=FQJ.Frame; if not frame then return end
    if frame.languageMenu then frame.languageMenu:Hide() end
    local activeLanguage=Language(); frame.languageText:SetText(activeLanguage=="frFR" and "Français" or "English"); frame.languageCode:SetText(activeLanguage=="frFR" and "FR" or "EN")
    if frame.languageOptions then
        for code,option in pairs(frame.languageOptions) do
            local selected=code==activeLanguage
            option.check:SetShown(selected); option.label:SetTextColor(selected and 1.00 or 0.86,selected and 0.82 or 0.81,selected and 0.27 or 0.72)
            option.code:SetTextColor(selected and 1.00 or 0.62,selected and 0.82 or 0.59,selected and 0.27 or 0.53)
        end
    end
    frame.placeholder:SetText(L("search")); frame.backButton:SetText(L("zones")); frame.listTitle:SetText(L("quests"))
    frame.questsTab:SetText("!  "..L("quests")); frame.mapTab:SetText(L("map")); frame.detail.mapButton:SetText(L("showMap"))
    frame.filterButtons.unfinished:SetText(L("unfinished")); frame.filterButtons.completed:SetText(L("completed"))
    if frame.home:IsShown() then FQJ.RefreshHome() else FQJ.ShowZone(activeZoneKey) end
end

function FQJ.CreateUI()
    local frame=CreateFrame("Frame","ForeverQuestJournalFrame",UIParent,"BackdropTemplate"); frame:SetSize(850,590); frame:SetPoint("CENTER",0,10); frame:SetFrameStrata(FQJ.MAIN_FRAME_STRATA or "DIALOG"); frame:SetFrameLevel(FQJ.MAIN_FRAME_LEVEL or 20)
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton"); frame:SetScript("OnDragStart",frame.StartMoving); frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
    frame:SetScript("OnMouseDown",function() if FQJ.BringToFront then FQJ.BringToFront() end end)
    frame:SetBackdrop({bgFile="Interface\\FrameGeneral\\UI-Background-Rock",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=24,insets={left=6,right=6,top=6,bottom=6}}); frame:SetBackdropColor(0.045,0.042,0.037,0.99)
    local top=frame:CreateTexture(nil,"BACKGROUND"); top:SetColorTexture(0.14,0.10,0.055,0.96); top:SetPoint("TOPLEFT",12,-10); top:SetPoint("TOPRIGHT",-12,-10); top:SetHeight(34)
    local title=Font(frame,16,{0.96,0.79,0.25},"CENTER"); title:SetPoint("TOP",0,-18); title:SetText("Forever Quest Journal")
    local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-3,-3)
    local searchBox=CreateFrame("EditBox",nil,frame,"BackdropTemplate"); searchBox:SetSize(265,26); searchBox:SetPoint("TOPLEFT",18,-14); searchBox:SetAutoFocus(false); searchBox:SetMaxLetters(40); searchBox:SetFont("Fonts\\FRIZQT__.TTF",12,""); searchBox:SetTextInsets(27,8,0,0); searchBox:SetTextColor(0.94,0.91,0.84)
    Backdrop(searchBox,"Interface\\Buttons\\WHITE8X8","Interface\\Tooltips\\UI-Tooltip-Border"); searchBox:SetBackdropColor(0.045,0.043,0.040,0.98); searchBox:SetBackdropBorderColor(0.34,0.31,0.27,1)
    local searchIcon=searchBox:CreateTexture(nil,"ARTWORK"); searchIcon:SetSize(14,14); searchIcon:SetPoint("LEFT",7,0); searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    local placeholder=Font(searchBox,12,{0.55,0.54,0.50}); placeholder:SetPoint("LEFT",28,0)
    searchBox:SetScript("OnTextChanged",function(self) placeholder:SetShown((self:GetText() or "")=="" and not self:HasFocus()); if frame.home and frame.home:IsShown() then FQJ.RefreshHome() elseif frame.zoneContent and frame.zoneContent:IsShown() then FQJ.Refresh() end end)
    searchBox:SetScript("OnEditFocusGained",function() placeholder:Hide() end); searchBox:SetScript("OnEditFocusLost",function(self) placeholder:SetShown((self:GetText() or "")=="") end); searchBox:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    frame.searchBox,frame.placeholder=searchBox,placeholder
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
    frame.prevZone=CreateFlatButton(frame,22,22); frame.prevZone:SetPoint("TOPLEFT",18,-47); frame.prevZone:SetText("<"); frame.prevZone:SetScript("OnClick",function() NavigateZone(-1) end)
    frame.backButton=CreateFlatButton(frame,116,24,"primary"); frame.backButton:SetPoint("TOPLEFT",44,-46); frame.backButton:SetScript("OnClick",FQJ.ShowHome)
    frame.nextZone=CreateFlatButton(frame,22,22); frame.nextZone:SetPoint("TOPLEFT",164,-47); frame.nextZone:SetText(">"); frame.nextZone:SetScript("OnClick",function() NavigateZone(1) end)

    local content=CreateFrame("Frame",nil,frame,"BackdropTemplate"); content:SetPoint("TOPLEFT",18,-90); content:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(content); content:SetBackdropColor(0.17,0.12,0.07,0.96); content:SetBackdropBorderColor(0.47,0.34,0.16,1); frame.zoneContent=content
    local header=CreateFrame("Frame",nil,content,"BackdropTemplate"); header:SetPoint("TOPLEFT",14,-12); header:SetPoint("TOPRIGHT",-14,-12); header:SetHeight(62); Backdrop(header); header:SetBackdropColor(0.24,0.17,0.09,0.94); header:SetBackdropBorderColor(0.52,0.33,0.11,1)
    frame.zoneTitle=Font(header,20,{1,0.82,0.27}); frame.zoneTitle:SetPoint("TOPLEFT",15,-10); frame.zoneMeta=Font(header,10,{0.88,0.80,0.66}); frame.zoneMeta:SetPoint("BOTTOMLEFT",15,9)
    frame.zoneRange=Font(header,10,{0.76,0.70,0.60},"RIGHT"); frame.zoneRange:SetPoint("BOTTOMRIGHT",-15,9)
    frame.questsTab=CreateFlatButton(header,108,30); frame.questsTab:SetPoint("TOPRIGHT",-13,-14); frame.questsTab:SetSelected(true); frame.questsTab:Disable()
    frame.mapTab=CreateFlatButton(header,108,30,"primary"); frame.mapTab:SetPoint("TOPRIGHT",-127,-14)
    local mapBadge=CreateFrame("Frame",nil,frame.mapTab,"BackdropTemplate"); mapBadge:SetSize(28,20); mapBadge:SetPoint("LEFT",5,0); mapBadge:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1}); mapBadge:SetBackdropColor(0.20,0.145,0.055,1); mapBadge:SetBackdropBorderColor(0.58,0.41,0.13,1)
    local mapIcon=mapBadge:CreateTexture(nil,"OVERLAY"); mapIcon:SetSize(19,19); mapIcon:SetPoint("CENTER",0,0); mapIcon:SetTexture(ICONS.map); mapIcon:SetTexCoord(0,1,0,1)
    frame.mapTab.label:ClearAllPoints(); frame.mapTab.label:SetPoint("CENTER",13,0)
    frame.mapTab:SetScript("OnClick",function() local zone=ActiveZone(); if FQJ.YieldToNewWindow then FQJ.YieldToNewWindow() end; if C_Map and C_Map.OpenWorldMap then C_Map.OpenWorldMap(zone.uiMapID) elseif ToggleWorldMap then ToggleWorldMap() end end)
    local listPanel=CreateFrame("Frame",nil,content,"BackdropTemplate"); listPanel:SetPoint("TOPLEFT",14,-84); listPanel:SetPoint("BOTTOMLEFT",14,14); listPanel:SetWidth(344); Backdrop(listPanel); listPanel:SetBackdropColor(0.19,0.13,0.07,0.94); listPanel:SetBackdropBorderColor(0.39,0.24,0.08,1)
    frame.listTitle=Font(listPanel,16,{1,0.82,0.27}); frame.listTitle:SetPoint("TOPLEFT",12,-10)
    frame.filterButtons={}; CreateFilter(frame,"unfinished",10); CreateFilter(frame,"completed",162)
    local filterOrder={"unfinished","completed"}
    for index,filter in ipairs(filterOrder) do
        local button=frame.filterButtons[filter]; button:SetParent(listPanel); button:ClearAllPoints(); button:SetSize(145,22); button:SetPoint("TOPLEFT",10+((index-1)*152),-43)
    end
    local listScroll=CreateFrame("ScrollFrame",nil,listPanel,"UIPanelScrollFrameTemplate"); listScroll:SetPoint("TOPLEFT",10,-72); listScroll:SetPoint("BOTTOMRIGHT",-28,30)
    frame.listChild=CreateFrame("Frame",nil,listScroll); frame.listChild:SetWidth(292); frame.listChild:SetHeight(480); listScroll:SetScrollChild(frame.listChild)
    frame.progress=Font(listPanel,11,{0.76,0.63,0.37},"CENTER"); frame.progress:SetPoint("BOTTOM",listPanel,"BOTTOM",0,9); frame.listPanel=listPanel

    local detail=CreateFrame("Frame",nil,content,"BackdropTemplate"); detail:SetPoint("TOPLEFT",listPanel,"TOPRIGHT",12,0); detail:SetPoint("BOTTOMRIGHT",-14,14); Backdrop(detail); detail:SetBackdropColor(0.21,0.15,0.08,0.94); detail:SetBackdropBorderColor(0.42,0.27,0.10,1)
    local inset=CreateFrame("Frame",nil,detail,"BackdropTemplate"); inset:SetPoint("TOPLEFT",8,-8); inset:SetPoint("BOTTOMRIGHT",-14,8); inset:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=10,insets={left=3,right=3,top=3,bottom=3}}); inset:SetBackdropColor(0.19,0.13,0.07,0.98); inset:SetBackdropBorderColor(0.36,0.23,0.09,1)
    local questIcon=inset:CreateTexture(nil,"ARTWORK"); questIcon:SetSize(42,42); questIcon:SetPoint("TOPLEFT",14,-12); questIcon:SetTexture(ICONS.giver); questIcon:SetTexCoord(0,1,0,1); detail.questIcon=questIcon
    detail.title=Font(inset,18,{1.00,0.80,0.28}); detail.title:SetPoint("TOPLEFT",66,-14); detail.title:SetPoint("RIGHT",-112,0); detail.title:SetWordWrap(false); detail.title:SetShadowColor(0,0,0,0.9); detail.title:SetShadowOffset(1,-1)
    detail.level=Font(inset,11,{0.84,0.76,0.62}); detail.level:SetPoint("TOPLEFT",detail.title,"BOTTOMLEFT",0,-5); detail.status=Font(inset,10,{0.84,0.76,0.62},"RIGHT"); detail.status:SetPoint("TOPRIGHT",-16,-18)
    local divider=inset:CreateTexture(nil,"ARTWORK"); divider:SetColorTexture(0.49,0.31,0.10,0.9); divider:SetPoint("TOPLEFT",14,-66); divider:SetPoint("TOPRIGHT",-14,-66); divider:SetHeight(1)
    detail.scrollFrame=CreateFrame("ScrollFrame",nil,inset); detail.scrollFrame:SetPoint("TOPLEFT",16,-78); detail.scrollFrame:SetPoint("BOTTOMRIGHT",-28,54); detail.scrollFrame:EnableMouseWheel(true); detail.scrollFrame:SetScript("OnMouseWheel",function(self,delta) self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScroll()-(delta*34),self:GetVerticalScrollRange()))) end)
    detail.scrollChild=CreateFrame("Frame",nil,detail.scrollFrame); detail.scrollChild:SetWidth(350); detail.scrollChild:SetHeight(460); detail.scrollFrame:SetScrollChild(detail.scrollChild); detail.content,detail.lines=detail.scrollChild,{}
    detail.mapButton=CreateFlatButton(inset,180,27,"primary"); detail.mapButton:SetPoint("BOTTOM",0,18); detail.mapButton:SetScript("OnClick",function() local zone=ActiveZone(); FQJ.ShowQuestStartOnMap(zone.quests[selectedQuestID],zone) end); frame.detail=detail

    local home=CreateFrame("Frame",nil,frame,"BackdropTemplate"); home:SetPoint("TOPLEFT",18,-52); home:SetPoint("BOTTOMRIGHT",-18,18); Backdrop(home); home:SetBackdropColor(0.16,0.12,0.07,0.96); home:SetBackdropBorderColor(0.47,0.34,0.16,1); frame.home=home
    local homeScroll=CreateFrame("ScrollFrame",nil,home,"UIPanelScrollFrameTemplate"); homeScroll:SetPoint("TOPLEFT",18,-10); homeScroll:SetPoint("BOTTOMRIGHT",-28,12)
    frame.homeChild=CreateFrame("Frame",nil,homeScroll); frame.homeChild:SetWidth(742); frame.homeChild:SetHeight(500); homeScroll:SetScrollChild(frame.homeChild); frame.zoneCards,frame.homeHeaders={},{}
    tinsert(UISpecialFrames,frame:GetName()); FQJ.Frame=frame; ApplyLanguage(); FQJ.ShowHome()
end
