------------------------------------------------------
-- XPMon Addon Instance
------------------------------------------------------

XPMon = XPMon or {}

XPMon.DEBUG = true
XPMon.NAME = "XPMon"
XPMon.LEVEL_CAP = 90
XPMon.XP_GAIN_TIMEOUT = 5
XPMon.COLOURS = {
    SYSTEM = "ffff00",
    DATA = "1bb8f7",
    KNOCKBACK = "b3c2c7",
    ERROR = "cc0000"
}
XPMon.EVENTS_XP = {
    CHAT_MSG_SYSTEM = true,
    CHAT_MSG_COMBAT_XP_GAIN = true,
    CHAT_MSG_OPENING = true,
    LFG_COMPLETION_REWARD = true,
    PET_BATTLE_FINAL_ROUND = true
}
XPMon.EVENT_HANDLERS = {
    PLAYER_XP_UPDATE = "onPlayerXPUpdate",
    ADDON_LOADED = "onAddonLoaded",
    PLAYER_LOGIN = "onPlayerLogin"
}

XPMon.nextXPGains = {}
XPMon.currentXP = nil
XPMon.currentXPRested = 0
XPMon.currentXPRemaining = nil
XPMon.currentLevel = nil

function XPMon:onLoad(addon)

    -- XP related events to listen to
    for key, value in pairs(self.EVENTS_XP) do
        self:log("registering", key)
        addon:RegisterEvent(key)
    end

    -- Other events to listen to
    for key, value in pairs(self.EVENT_HANDLERS) do
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

function XPMon:onEvent(frame, event, ...)
    local xpGain
    -- XP related event here
    if self.EVENTS_XP[event] ~= nil then
        for key, value in pairs(self.filters) do
            if value.events[event] ~= nil then
                xpGain = value.handler(event, ...)
            end
            if xpGain ~= nil then
                table.insert(self.nextXPGains, xpGain)
                break
            end
        end

        -- Other events
    else
        if self.EVENT_HANDLERS[event] ~= nil then
            self[self.EVENT_HANDLERS[event]](self, event, ...)
        end
    end
end

function XPMon:onPlayerXPUpdate()
    self:log("Player XP update!")

    if (table.getn(self.nextXPGains) == 0) then
        self:handleXPGain(nil)
    else
        local xpGain = table.remove(self.nextXPGains, 1)
        while xpGain do
            self:handleXPGain(xpGain)
            xpGain = table.remove(self.nextXPGains, 1)
        end
    end
end

function XPMon:handleXPGain(xpGain)

    -- Check that the xpEvent we have registered didn't happen too long ago to
    -- avoid logging XP data against the wrong event, better it is logged as Unknown
    if xpGain and xpGain:get("t") > 0 then
        if time() - xpGain:get("t") > self.XP_GAIN_TIMEOUT then
            self:log("XPEvent too old, ignoring")
            xpGain = nil
        end
    end

    local xpEventPrevLevel, xpEventCurrentLevel

    xpEventCurrentLevel = self:createXPEvent(xpGain)

    if UnitLevel("player") > self.currentLevel then
        xpEventPrevLevel = XPEvent:new(xpEventCurrentLevel:data())
        xpEventPrevLevel:set("xp", self.currentXPRemaining)

        xpEventCurrentLevel:set("xp", UnitXP("player"))

        if xpEventCurrentLevel:get("rxp") > 0 then
            xpEventPrevLevel:set("rxp", math.max(0, xpEventPrevLevel:get("xp") - xpEventPrevLevel:get("rxp")))
            xpEventCurrentLevel:set("rxp", xpEventCurrentLevel:get("rxp") - xpEventPrevLevel:get("rxp"))
        end

        XPMon:log("Saving XP event for previous level: ", xpEventPrevLevel:get("src"), xpEventPrevLevel:get("xp"), xpEventPrevLevel:get("rxp"))
        XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, self.currentLevel, xpEventPrevLevel)
    else
        xpEventCurrentLevel:set("xp", UnitXP("player") - self.currentXP)
    end

    XPMon:log("Saving XP event for current level: ", xpEventCurrentLevel:get("src"), xpEventCurrentLevel:get("xp"), xpEventCurrentLevel:get("rxp"))
    XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, UnitLevel("player"), xpEventCurrentLevel)

    XPMon:setCurrentPlayerInfo()
end

function XPMon:createXPEvent(originalEvent)
    local x, y = GetPlayerMapPosition("player")
    local xpEvent = originalEvent or XPEvent:new()
    xpEvent:set("z", GetRealZoneText())
    xpEvent:set("r", self.currentXPRested > 0)
    xpEvent:set("p", {
        x = XPMonUtil.round(x * 100, 2),
        y = XPMonUtil.round(y * 100, 2)
    })
    return xpEvent
end

function XPMon:setCurrentPlayerInfo()
    self.currentXP = UnitXP("player")
    self.currentXPRested = GetXPExhaustion("player") or 0
    self.currentXPRemaining = UnitXPMax("player") - self.currentXP
    self.currentLevel = UnitLevel("player")
    self:log("Setting player info", self.currentXP, self.currentXPRemaining)
end

function XPMon:log(...)
    if self.DEBUG == true then
        print("XPMon:log: ", ...)
    end
end

------------------------------------------------------
-- Addon slash command handlers
------------------------------------------------------
function XPMon:commandLEVEL(args)
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
        table.sort(totals, function(a, b)
            return a.total > b.total
        end)

        local xp = level == UnitLevel("player") and self.currentXP or data.max
        XPMonUtil.print("XPMon: stats for level " .. level, XPMon.COLOURS.SYSTEM)
        for i, item in pairs(totals) do
            XPMonUtil.print(XPMon.SOURCES[item.type] .. ": " .. item.total .. " (" .. string.format("%.1f", (item.total / xp * 100)) .. "%)", XPMon.COLOURS.DATA, 1)
        end
        if data.total < xp then
            XPMonUtil.print("Uncaptured: " .. (xp - data.total) .. " (" .. string.format("%.1f", ((xp - data.total) / xp * 100)) .. "%)", XPMon.COLOURS.KNOCKBACK, 1)
        end
        XPMonUtil.print("Total: " .. xp, XPMon.COLOURS.DATA, 1)
    else
        XPMonUtil.print("XPMon: no XP data found for level " .. level, XPMon.COLOURS.ERROR)
    end
end

function XPMon:commandTOTAL()
    XPMonUtil.print("XPMon: coming soon...", XPMon.COLOURS.ERROR)
end

function XPMon:commandSHOW()
    XPMonDetailsFrame:Show()
end

function XPMon:commandHIDE()
    XPMonDetailsFrame:Hide()
end

------------------------------------------------------
-- WOW Global Stuff
------------------------------------------------------

SlashCmdList = SlashCmdList or {}

-- Slash commands
SLASH_XPMON1 = "/xpmon"

-- XPMon saved data
XPMon_DATA = XPMon_DATA or {}
XPMon_USER_CONFIG = XPMon_USER_CONFIG or {}

-- Slash command handler
function SlashCmdList.XPMON(str, editBox)
    local command, args, s, e = str, nil
    if command:find(" ") then
        s, e, command, args = str:find("^([%a]+) ([%a%d%s]+)$")
    end
    if (command == "") then
        XPMonUtil.print("XPMon: usage", XPMon.COLOURS.SYSTEM)
        XPMonUtil.print("/xpmon level - print XP information for the given level", XPMon.COLOURS.SYSTEM, 1)
        XPMonUtil.print("/xpmon total - print total XP information for all levels", XPMon.COLOURS.SYSTEM, 1)
        XPMonUtil.print("/xpmon show - show XPMon UI", XPMon.COLOURS.SYSTEM, 1)
        XPMonUtil.print("/xpmon hide - hide XPMon UI", XPMon.COLOURS.SYSTEM, 1)
        return
    end
    if (type(XPMon["command" .. command:upper()]) == "function") then
        XPMon["command" .. command:upper()](XPMon, args)
    else
        XPMonUtil.print("XPMon: invalid command, " .. command, XPMon.COLOURS.ERROR)
    end
end