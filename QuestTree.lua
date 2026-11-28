local _, FQJ = ...

local function ByLevel(a, b)
    local levelA, levelB = a.quest.level or 0, b.quest.level or 0
    if levelA == levelB then return a.quest.id < b.quest.id end
    return levelA < levelB
end

-- Lay out each connected chain left to right. Shared steps occupy one node.
function FQJ.LayoutQuestChain(group)
    if group.columns then return group.columns end
    local pending, rank, placed, columns = {}, {}, {}, {}
    for _, node in ipairs(group.nodes) do
        pending[node], rank[node] = #node.before, 1
    end
    for _ = 1, #group.nodes do
        local nextNode
        for _, node in ipairs(group.nodes) do
            if not placed[node] then
                nextNode = nextNode or node
                if pending[node] == 0 then nextNode = node; break end
            end
        end
        placed[nextNode] = true
        local level = rank[nextNode]
        local column = columns[level] or {}
        columns[level] = column
        table.insert(column, nextNode)
        for _, edge in ipairs(nextNode.after) do
            if not placed[edge.to] then
                pending[edge.to] = pending[edge.to] - 1
                rank[edge.to] = math.max(rank[edge.to], level + 1)
            end
        end
    end
    group.columns = columns
    return columns
end

local graph
function FQJ.GetQuestTree()
    if graph then return graph end
    local nodes, indexed = {}, {}
    for _, zone in pairs(FQJ.Zones) do
        for id, quest in pairs(zone.quests) do
            indexed[id] = true
            if not quest.special and FQJ.IsQuestRelevant(quest) then
                nodes[id] = { quest = quest, zone = zone, before = {}, after = {} }
            end
        end
    end
    local function Resolve(ref)
        if not nodes[ref.id] and not indexed[ref.id] then
            nodes[ref.id] = { quest = ref, before = {}, after = {} }
        end
        return nodes[ref.id]
    end
    local function Link(from, to, kind)
        if not from or not to or from == to then return end
        for _, edge in ipairs(from.after) do
            if edge.to == to then
                if kind ~= "follow" then edge.kind = kind end
                return
            end
        end
        local edge = { from = from, to = to, kind = kind }
        table.insert(from.after, edge)
        table.insert(to.before, edge)
    end
    for _, zone in pairs(FQJ.Zones) do
        for id, quest in pairs(zone.quests) do
            local node = nodes[id]
            if node then
                if quest.nextQuest then Link(node, Resolve(quest.nextQuest), "follow") end
                for _, ref in ipairs(quest.prerequisitesAll or {}) do Link(Resolve(ref), node, "required") end
                local alternatives = quest.prerequisitesAny or {}
                local kind = #alternatives > 1 and "alternative" or "required"
                for _, ref in ipairs(alternatives) do Link(Resolve(ref), node, kind) end
            end
        end
    end
    for _, node in pairs(nodes) do
        table.sort(node.after, function(a, b) return ByLevel(a.to, b.to) end)
        table.sort(node.before, function(a, b) return ByLevel(a.from, b.from) end)
        if not node.group then
            local group = { nodes = { node }, roots = {} }
            node.group = group
            local index = 1
            while index <= #group.nodes do
                local current = group.nodes[index]
                local function Visit(other)
                    if other.group then return end
                    other.group = group
                    table.insert(group.nodes, other)
                end
                for _, edge in ipairs(current.before) do Visit(edge.from) end
                for _, edge in ipairs(current.after) do Visit(edge.to) end
                if #current.before == 0 then table.insert(group.roots, current) end
                index = index + 1
            end
            table.sort(group.nodes, ByLevel)
            table.sort(group.roots, ByLevel)
        end
    end
    graph = nodes
    return graph
end
