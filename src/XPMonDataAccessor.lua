XPMonDataAccessor = {}

XPMonDataAccessor = {}

--- addXPEventForLevel
-- @param level The character level for which the event should be added
-- @param event The XP event object
--
function XPMonDataAccessor:addXPEventForLevel(store, level, event)
    local insert
    local source = event:get("source")
    event:unset("source")

    if store[level] == nil then
        store[level] = {
            total = 0,
            max = UnitXPMax("player"),
            data = {}
        }
    end
    if store[level].data[source] == nil then
        store[level].data[source] = {
            keys = {},
            total = 0,
            events = {}
        }
    end
    insert = store[level].data[source].events
    if event:get("key") then
        if store[level].data[source].keys[event:get("key")] == nil then
            store[level].data[source].keys[event:get("key")] = true
            store[level].data[source].events[event:get("key")] = {}
        end
        insert = store[level].data[source].events[event:get("key")]
        event:unset("key")
    end
    table.insert(insert, event:data())
    store[level].total = store[level].total + event:get("experience")
    store[level].data[source].total = store[level].data[source].total + event:get("experience")
end

function XPMonDataAccessor:getTotalsForLevel(store, level)

end

function XPMonDataAccessor:getDataForLevel(store, level)
    return store[level]
end

function XPMonDataAccessor:query(store, level, params)

end

--XPMonDataAccessor.query(XPMon_DATA, 10, {
--    type = "Professions",
--    filter = { name = "Something" },
--    group = { "zone" },
--    order = { experience = "asc" }
--})