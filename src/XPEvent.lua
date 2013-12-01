-- This is a "class" which represents an XP event. There is a lot of fluff in the
-- constructor which I will ideally get rid of or move into a more generic class
-- but it will do for now

XPEvent = {}

function XPEvent:new(vars)
    local _defaults = {
        source = "Unknown",
        experience = 0,
        restedBonus = 0,
        details = {}
    }
    local instance = {
        _data = XPMonUtil.deepcopy(vars) or {}
    }
    setmetatable(instance, self)
    self.__index = self
    for k, v in pairs(_defaults) do
        if instance:get(k) == nil then
            instance:set(k, v)
        end
    end
    instance:set("time", time())
    return instance
end

function XPEvent:data()
    return self._data
end

function XPEvent:set(key, val)
    self._data[key] = val
end

function XPEvent:unset(key)
    if (self._data[key]) then
        self._data[key] = nil
    end
end

function XPEvent:get(key)
    return self._data[key]
end

