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

XPMon.nextXPGain = nil
XPMon.currentXP = nil
XPMon.currentXPRested = 100
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
    self:UI_ShowLevelInformation(self.currentLevel)
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
                self.nextXPGain = xpGain
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
    -- Check that the xpEvent we have registered didn't happen too long ago to
    -- avoid logging XP data against the wrong event, better it is logged as Unknown
    if self.nextXPGain and self.nextXPGain:get("time") > 0 then
        if time() - self.nextXPGain:get("time") > self.XP_GAIN_TIMEOUT then
            self:log("XPEvent too old, ignoring")
            self.nextXPGain = nil
        end
    end

    self:log("Player XP update!")

    local x, y = GetPlayerMapPosition("player")
    local xpEventPrevLevel, xpEventCurrentLevel

    xpEventCurrentLevel = self.nextXPGain or XPEvent:new()
    xpEventCurrentLevel:set("zone", GetRealZoneText())
    xpEventCurrentLevel:set("rested", self.currentXPRested > 0)
    xpEventCurrentLevel:set("position", {
        x = XPMonUtil.round(x * 100, 2),
        y = XPMonUtil.round(y * 100, 2)
    })

    self:log(" - remaining XP:", self.currentXPRemaining)

    if UnitLevel("player") > self.currentLevel then
        xpEventPrevLevel = XPEvent:new(xpEventCurrentLevel:data())
        xpEventPrevLevel:set("experience", self.currentXPRemaining)

        xpEventCurrentLevel:set("experience", UnitXP("player"))

        if xpEventCurrentLevel:get("restedBonus") > 0 then
            xpEventPrevLevel:set("restedBonus", math.max(0, xpEventPrevLevel:get("experience") - xpEventPrevLevel:get("restedBonus")))
            xpEventCurrentLevel:set("restedBonus", xpEventCurrentLevel:get("restedBonus") - xpEventPrevLevel:get("restedBonus"))
        end

        XPMon:log("Saving XP event for previous level: ", xpEventPrevLevel:get("source"), xpEventPrevLevel:get("experience"), xpEventPrevLevel:get("restedBonus"))
        XPMon:addXPEventForLevel(self.currentLevel, xpEventPrevLevel)
    else
        xpEventCurrentLevel:set("experience", UnitXP("player") - self.currentXP)
    end

    XPMon:log("Saving XP event for current level: ", xpEventCurrentLevel:get("source"), xpEventCurrentLevel:get("experience"), xpEventCurrentLevel:get("restedBonus"))
    XPMon:addXPEventForLevel(UnitLevel("player"), xpEventCurrentLevel)

    XPMon:setCurrentPlayerInfo()
end

function XPMon:addXPEventForLevel(level, event)
    local insert
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
            keys = {},
            total = 0,
            events = {}
        }
    end
    insert = XPMon_DATA[level].data[source].events
    if event:get("key") then
        if XPMon_DATA[level].data[source].keys[event:get("key")] == nil then
            XPMon_DATA[level].data[source].keys[event:get("key")] = true
            XPMon_DATA[level].data[source].events[event:get("key")] = {}
        end
        insert = XPMon_DATA[level].data[source].events[event:get("key")]
        event:unset("key")
    end
    table.insert(insert, event:data())
    XPMon_DATA[level].total = XPMon_DATA[level].total + event:get("experience")
    XPMon_DATA[level].data[source].total = XPMon_DATA[level].data[source].total + event:get("experience")
end

function XPMon:setCurrentPlayerInfo()
    self.currentXP = UnitXP("player")
    self.currentXPRested = GetXPExhaustion("player")
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

------------------------------------------------------
-- UI Stuff
------------------------------------------------------
function XPMon:UI_ShowLevelInformation(level)
    XPMonFrameSelectLevel.selectedValue = level
    XPMonFrameSelectLevel.selectedName = "Level " .. level
    UIDropDownMenu_SetText(XPMonFrameSelectLevel, XPMonFrameSelectLevel.selectedName)
    XPMonTitleTextLevel:SetText(level)
end

function XPMon:UI_InitLevelSelect(frame)
    local levels = {}
    for level, info in pairs(XPMon_DATA) do
        table.insert(levels, level)
    end
    table.sort(levels, function (a, b) return a > b end)
    for i, level in pairs(levels) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Level " .. level
        info.value = level
        info.func = function (...)
            self:UI_OnLevelSelect(...)
        end
        UIDropDownMenu_AddButton(info)
    end
end

function XPMon:UI_OnLevelSelect(frame, arg1, arg2, checked)
    if (not checked) then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, frame.value)
    end
    XPMon:UI_ShowLevelInformation(frame.value)
end

function XPMon:UI_OnShow(frame)
    XPMon:log("Showing frame", frame)
end

function XPMon:UI_OnTabClick(frame, tab)
    if frame.selectedTab then
        _G["XPMonFrameTabContent" .. frame.selectedTab]:Hide()
    end
    _G["XPMonFrameTabContent" .. tab]:Show()
    PanelTemplates_SetTab(frame, tab)
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
            XPMonUtil.print(item.type .. ": " .. item.total .. " (" .. string.format("%.1f", (item.total / xp * 100)) .. "%)", XPMon.COLOURS.DATA, 1)
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
    XPMonFrame:Show()
end

function XPMon:commandHIDE()
    XPMonFrame:Hide()
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