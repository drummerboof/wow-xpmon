
--------------------
-- Utility functions
--------------------

-- http://lua-users.org/wiki/CopyTable
function XPMon_deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[XPMon_deepcopy(orig_key)] = XPMon_deepcopy(orig_value)
        end
        setmetatable(copy, XPMon_deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end