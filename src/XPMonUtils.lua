
--------------------
-- Utility functions
--------------------
XPMonUtil = {};

-- http://lua-users.org/wiki/CopyTable
function XPMonUtil.deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[XPMonUtil.deepcopy(orig_key)] = XPMonUtil.deepcopy(orig_value)
        end
        setmetatable(copy, XPMonUtil.deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end