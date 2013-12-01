XPMon = XPMon or {}

XPMon.DataAccessor = {}

function XPMon.DataAccessor:totals(level)

end

function XPMon.DataAccessor:query(params, level)

end

XPMon.DataAccessor.query({
    type = "Professions",
    filter = { name = "Something" },
    group = { "zone" },
    order = { experience = "asc" }
}, 10)