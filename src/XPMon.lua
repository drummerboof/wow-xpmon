------------------------------------------------------
-- XPMon Addon Instance
------------------------------------------------------

XPMon = XPMon or {}

XPMon.DEBUG = false
XPMon.NAME = "XPMon"
XPMon.XP_GAIN_TIMEOUT = 2

XPMon.nextXPGain = nil
XPMon.currentXP = nil
XPMon.currentXPRemaining = nil
XPMon.currentLevel = nil
XPMon.XPEvents = {
    CHAT_MSG_SYSTEM = true,
    CHAT_MSG_COMBAT_XP_GAIN = true,
    CHAT_MSG_OPENING = true,
    LFG_COMPLETION_REWARD = true,
    PET_BATTLE_FINAL_ROUND = true
}
XPMon.otherEvents = {
    PLAYER_XP_UPDATE = "onPlayerXPUpdate",
    ADDON_LOADED = "onAddonLoaded",
    PLAYER_LOGIN = "onPlayerLogin"
}

XPMon.commands = {
    level = "commandLevel",
    total = "commadTotal"
}

function XPMon:onLoad(addon)

    -- XP related events to listen to
    for key, value in pairs(self.XPEvents) do
        self:log("registering", key)
        addon:RegisterEvent(key)
    end

    -- Other events to listen to
    for key, value in pairs(self.otherEvents) do
        self:log("registering", key)
        addon:RegisterEvent(key)
    end

    XPMon:log("XPMon:onLoad")
end

function XPMon:onAddonLoaded(event, addon)
    if addon == self.NAME then
        self:log("XPMon:onAddonLoaded", addon)
    end
end

function XPMon:onPlayerLogin(event)
    self:setCurrentPlayerInfo()
end

function XPMon:onEvent(addon, event, ...)
    -- XP related event here
    if self.XPEvents[event] ~= nil then
        for key, value in pairs(self.filters) do
            if value.events[event] ~= nil then
                self.nextXPGain = value.handler(event, ...)
            end
            if self.nextXPGain ~= nil then
                break
            end
        end

    -- Other events
    else
        if self.otherEvents[event] ~= nil then
            self[self.otherEvents[event]](self, event, ...)
        end
    end
end

function XPMon:onPlayerXPUpdate()
    -- Check that the xpEvent we have registered didn't happen too long ago to
    -- avoid logging XP data against the wrong event, better it is logged as Unknown
    if self.nextXPGain and self.nextXPGain:get("time") > 0 then
        if time() - self.nextXPGain:get("time") > self.XP_GAIN_TIMEOUT then
            self:log("XPEvent too old, ignoring")
            self.nextXPGain = nil
        end
    end

    self:log("Player XP update!")

    local xpEventPrevLevel, xpEventCurrentLevel

    xpEventCurrentLevel = self.nextXPGain or XPEvent:new()
    xpEventCurrentLevel:set("zone", GetRealZoneText())

    self:log(" - remaining XP:", self.currentXPRemaining)

    if UnitLevel("player") > self.currentLevel then
        xpEventPrevLevel = XPEvent:new(xpEventCurrentLevel:data())
        xpEventPrevLevel:set("experience", self.currentXPRemaining)

        xpEventCurrentLevel:set("experience", UnitXP("player"))

        if xpEventCurrentLevel:get("rested") > 0 then
            xpEventPrevLevel:set("rested", math.max(0, xpEventPrevLevel:get("experience") - xpEventPrevLevel:get("rested")))
            xpEventCurrentLevel:set("rested", xpEventCurrentLevel:get("rested") - xpEventPrevLevel:get("rested"))
        end

        XPMon:log("Saving XP event for previous level: ", xpEventPrevLevel:get("source"), xpEventPrevLevel:get("experience"), xpEventPrevLevel:get("rested"))
        XPMon:addXPEventForLevel(self.currentLevel, xpEventPrevLevel)
    else
        xpEventCurrentLevel:set("experience", UnitXP("player") - self.currentXP)
    end

    XPMon:log("Saving XP event for current level: ", xpEventCurrentLevel:get("source"), xpEventCurrentLevel:get("experience"), xpEventCurrentLevel:get("rested"))
    XPMon:addXPEventForLevel(UnitLevel("player"), xpEventCurrentLevel)

    XPMon:setCurrentPlayerInfo()
end

function XPMon:addXPEventForLevel(level, event)
    local source = event:get("source")
    event:unset("source")

    if XPMon_DATA[level] == nil then
        XPMon_DATA[level] = {
            total = 0,
            max = UnitXPMax("player"),
            data = {}
        }
    end
    if XPMon_DATA[level].data[source] == nil then
        XPMon_DATA[level].data[source] = {
            total = 0,
            events = {}
        }
    end
    table.insert(XPMon_DATA[level].data[source].events, event:data())
    XPMon_DATA[level].total = XPMon_DATA[level].total + event:get("experience")
    XPMon_DATA[level].data[source].total = XPMon_DATA[level].data[source].total + event:get("experience")
end

function XPMon:setCurrentPlayerInfo()
    self.currentXP = UnitXP("player")
    self.currentXPRemaining = UnitXPMax("player") - self.currentXP
    self.currentLevel = UnitLevel("player")
    self.nextXPGain = nil
    self:log("Setting player info", self.currentXP, self.currentXPRemaining)
end

function XPMon:log(...)
    if self.DEBUG == true then
        print("XPMon:log: ", ...)
    end
end

function XPMon:commandLevel(args)
    local totals = {}
    local level = args ~= "" and args or self.currentLevel
    local data = XPMon_DATA[tonumber(level)]

    if data then
        for type, stats in pairs(data.data) do
            table.insert(totals, {
                type = type,
                total = stats.total
            })
        end
        table.sort(totals, function (a, b)
            return a.total > b.total
        end)

        local xp = level == UnitLevel("player") and self.currentXP or data.max
        print("|cffffff00XPMon: stats for level " .. level)
        for i, item in pairs(totals) do
            print("|cff1BB8F7    ", item.type .. ":", item.total, "(" .. string.format("%.1f", (item.total / xp * 100)) .. "%)")
        end
        if data.total < xp then
            print("|cffB3C2C7    ", "Uncaptured:", xp - data.total, "(" .. string.format("%.1f", ((xp - data.total) / xp * 100)) .. "%)")
        end
        print("|cff1BB8F7    ", "Total:", xp)
    else
        print("|cffcc0000XPMon: no XP data found for level '" .. level .."'")
    end
end

function XPMon:commandTotal()
    print("|cffcc0000XPMon: coming soon...|r")
end

------------------------------------------------------
-- WOW Global Stuff
------------------------------------------------------

SlashCmdList = SlashCmdList or {}

-- Slash commands
SLASH_XPMON1 = '/xpmon'

-- XPMon saved data
XPMon_DATA = {}
XPMon_USER_CONFIG = {}

-- Slash command handler
function SlashCmdList.XPMON(str, editBox)
    local command, args, s, e = str, nil
    if command:find(" ") then
        s, e, command, args = str:find("^([%a]+) ([%a%d%s]+)$")
    end
    if (command == "") then
        print("|cffffff00XPMon: usage|r")
        print("|cffffff00    /xpmon level|r show XP information for the given level or the current level if none given")
        print("|cffffff00    /xpmon total|r show total XP information for all levels")
        return
    end
    if (XPMon.commands[command]) then
        XPMon[XPMon.commands[command]](XPMon, args)
    else
        print("|cffcc0000XPMon: invalid command,", command)
    end
end

function XPMon_onLoad(self)
    XPMon:onLoad(self)
end

function XPMon_onEvent(addon, event, ...)
    XPMon:onEvent(addon, event, ...)
end
