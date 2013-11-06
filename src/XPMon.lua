XPMon = XPMon or {};
SlashCmdList = SlashCmdList or {};
SLASH_XPMON1 = '/xpmon';

XPMon.nextXPGain = nil;
XPMon.currentXP = nil;
XPMon.currentXPRemaining = nil;
XPMon.currentLevel = nil;
XPMon.XPEvents = {
    CHAT_MSG_SYSTEM = true,
    CHAT_MSG_COMBAT_XP_GAIN = true,
    CHAT_MSG_OPENING = true,
    LFG_COMPLETION_REWARD = true
};

XPMon.otherEvents = {
    -- Listen to XP changes here and see if we have determined the cause
    PLAYER_XP_UPDATE = XPMon_onPlayerXPUpdate,
    -- Load saved player XP data
    ADDON_LOADED = XPMon_onAddonLoaded,
    PLAYER_LOGIN = XPMon_onPlayerLogin
}

XPMon.commands = {
    level = function(args)
        local xp, level = XPMon.currentXP, args ~= "" and args or XPMon.currentLevel;
        local data = XPMon_DATA[level];

        if data then
            print("|cffa0e0faXPMon: stats for level " .. level);
            for type, stats in pairs(data.data) do
                print("|cffa0e0fa    ", type .. ":", stats.total, "(" .. string.format("%.1f", (stats.total / xp * 100)) .. "%)");
            end
            if data.total < xp then
                print("|cffc9d3d6    ", "Uncaptured XP:", xp - data.total, "(" .. string.format("%.1f", ((xp - data.total) / xp * 100)) .. "%)");
            end
        else
            print("|cffcc0000XPMon: no XP data found for level", level);
        end
    end,
    total = function()
        print("|cffcc0000XPMon: coming soon...|r");
    end,
}

function XPMon_onLoad(self)

    -- XP related events to listen to
    for key, value in pairs(XPMon.XPEvents) do
        XPMon_log("regestering", key)
        self:RegisterEvent(key);
    end

    -- Other events to listen to
    for key, value in pairs(XPMon.otherEvents) do
        XPMon_log("regestering", key)
        self:RegisterEvent(key);
    end

    XPMon_log("XPMon_onLoad");
end

function XPMon_onAddonLoaded(event, addon)
    if addon == XPMON_NAME then
        XPMon_log("XPMon_onAddonLoaded", addon);
    end
end

function XPMon_onPlayerLogin(event)
    XPMon_setCurrentPlayerInfo();
end

function XPMon_onEvent(self, event, ...)
    -- XP related event here
    if XPMon.XPEvents[event] ~= nil then
        XPMon_onXPEvent(event, ...);

        -- Other events
    else
        if XPMon.otherEvents[event] ~= nil then
            XPMon.otherEvents[event](event, ...)
        end
    end
end

function XPMon_onXPEvent(event, data)
    for key, value in pairs(XPMon.filters) do
        if value.events[event] ~= nil then
            XPMon.nextXPGain = value.handler(event, data);
        end
        if XPMon.nextXPGain ~= nil then
            break;
        end
    end
end

function XPMon_onPlayerXPUpdate()
    -- Maybe check that the xpEvent we have registered didn't happen too long ago,
    -- or alternatively, clear out the nextXPGain variable after a timeout

    XPMon_log("Player XP update!");

    local xpEventPrevLevel, xpEventCurrentLevel;

    xpEventCurrentLevel = XPMon_deepcopy(XPMon.nextXPGain or XPMON_XP_EVENT_DEFAULT);

    XPMon_log(" - remaining XP:", XPMon.currentXPRemaining);

    if UnitLevel("player") > XPMon.currentLevel then
        xpEventPrevLevel = XPMon_deepcopy(XPMon.nextXPGain or XPMON_XP_EVENT_DEFAULT);
        xpEventPrevLevel.experience = XPMon.currentXPRemaining;
        xpEventCurrentLevel.experience = UnitXP("player");

        if xpEventCurrentLevel.rested > 0 then
            xpEventPrevLevel.rested = math.max(0, xpEventPrevLevel.experience - xpEventPrevLevel.rested);
            xpEventCurrentLevel.rested = xpEventCurrentLevel.rested - xpEventPrevLevel.rested;
        end

        XPMon_log("Saving XP event for previous level: ", xpEventPrevLevel.source, xpEventPrevLevel.experience, xpEventPrevLevel.rested);
        XPMon_addXPEventforLevel(XPMon.currentLevel, xpEventPrevLevel);
    else
        xpEventCurrentLevel.experience = UnitXP("player") - XPMon.currentXP;
    end

    XPMon_log("Saving XP event for current level: ", xpEventCurrentLevel.source, xpEventCurrentLevel.experience, xpEventCurrentLevel.rested);
    XPMon_addXPEventforLevel(UnitLevel("player"), xpEventCurrentLevel);

    XPMon_setCurrentPlayerInfo();
end

function XPMon_addXPEventforLevel(level, event)
    local source = event.source;
    event.source = nil;
    if XPMon_DATA[level] == nil then
        XPMon_DATA[level] = {
            total = 0,
            data = {}
        };
    end
    if XPMon_DATA[level].data[source] == nil then
        XPMon_DATA[level].data[source] = {
            total = 0,
            events = {}
        };
    end
    table.insert(XPMon_DATA[level].data[source].events, event);
    XPMon_DATA[level].total = XPMon_DATA[level].total + event.experience;
    XPMon_DATA[level].data[source].total = XPMon_DATA[level].data[source].total + event.experience;
end

function XPMon_setCurrentPlayerInfo()
    XPMon.currentXP = UnitXP("player");
    XPMon.currentXPRemaining = UnitXPMax("player") - XPMon.currentXP;
    XPMon.currentLevel = UnitLevel("player");
    XPMon.nextXPGain = nil;
    XPMon_log("Setting player info", XPMon.currentXP, XPMon.currentXPRemaining);
end

function XPMon_log(...)
    if XPMON_DEBUG == true then
        print("XPMon_log: ", ...);
    end
end

function SlashCmdList.XPMON(str, editBox)
    local command, args, s, e = str, nil;
    if command:find(" ") then
        s, e, command, args = str:find("^([%a]+) ([%a%d%s]+)$");
    end
    if (command == "") then
        print("|cffffff00XPMon: usage|r")
        print("|cffffff00    /xpmon level - show XP information for the given level or the current level if none given|r");
        print("|cffffff00    /xpmon total - show total XP information for all levels|r");
        return;
    end
    if (XPMon.commands[command]) then
        XPMon.commands[command](args);
    else
        print("|cffcc0000XPMon: invalid command,", command);
    end
end