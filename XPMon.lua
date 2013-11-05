-- XPMon saved data
XPMon_DATA = {};
XPMon_USER_CONFIG = {};

XPMon = {};
XPMon.DEBUG = true;
XPMon.NAME = "XPMon";
XPMon.XP_EVENT = {
    source = "Unknown",
    amount = 0,
    rested = 0,
    details = {}
}

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
}

XPMon.filters = {
    XP_MOB_KILL = {
        state = {},
        events = { CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            return nil;
        end
    },
    XP_QUEST = {
        state = {},
        events = { CHAT_MSG_SYSTEM = true },
        handler = function(event, data)
            return nil;
        end
    },
    XP_PROFESSION = {
        state = {},
        events = { CHAT_MSG_OPENING = true },
        handler = function(event, data)
            return nil;
        end
    },
    XP_EXPLORATION = {
        state = {},
        events = { CHAT_MSG_SYSTEM = true },
        handler = function(event, data)
            return nil;
        end
    },
    XP_DUNGEON_FINDER = {
        state = {},
        events = { LFG_COMPLETION_REWARD = true },
        handler = function(event, data)
            return nil;
        end
    },
    XP_BATTLEGROUND = {
        state = {},
        events = {},
        handler = function(event, data)
            return nil;
        end
    },
};


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

    XPMon_DATA = { foo = "barboof" }

    XPMon_log("XPMon_onLoad");
end

function XPMon_onAddonLoaded(event, addon)
    if addon == XPMon.NAME then
        XPMon_log("XPMon_onAddonLoaded", addon);
        XPMon_setCurrentPlayerInfo();
    end
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
        if XPMon_nextXPGainSpokenFor() then
            break;
        end
    end
end

function XPMon_onPlayerXPUpdate(event, data)
    XPMon_log("Player XP update!");

    local xpEventPrevLevel, xpEventCurrentLevel;

    xpEventCurrentLevel = XPMon_deepcopy(XPMon.nextXPGain or XPMon.XP_EVENT);

    XPMon_log(" - remaining XP:", XPMon.currentXPRemaining);

    if UnitLevel("player") > XPMon.currentLevel then
        xpEventPrevLevel = XPMon_deepcopy(XPMon.nextXPGain or XPMon.XP_EVENT);
        xpEventPrevLevel.amount = XPMon.currentXPRemaining;
        xpEventCurrentLevel.amount = UnitXP("player");

        if xpEventCurrentLevel.rested > 0 then
            xpEventPrevLevel.rested = math.max(0, xpEventPrevLevel.amount - xpEventPrevLevel.rested);
            xpEventCurrentLevel.rested = xpEventCurrentLevel.rested - xpEventPrevLevel.rested;
        end

        XPMon_log("Saving XP event for previous level: ", xpEventPrevLevel.source, xpEventPrevLevel.amount, xpEventPrevLevel.rested);
        XPMon_addXPEventforLevel(XPMon.currentLevel, xpEventPrevLevel);
    else
        xpEventCurrentLevel.amount = UnitXP("player") - XPMon.currentXP;
    end

    XPMon_log("Saving XP event for current level: ", xpEventCurrentLevel.source, xpEventCurrentLevel.amount, xpEventCurrentLevel.rested);
    XPMon_addXPEventforLevel(UnitLevel("player"), xpEventCurrentLevel);

    XPMon_setCurrentPlayerInfo();
    XPMon.nextXPGain = nil;
end

function XPMon_nextXPGainSpokenFor()
    return XPMon.nextXPGain ~= nil
end

function XPMon_addXPEventforLevel(level, event)
    local source = event.source;
    event.source = nil;
    if XPMon_DATA[level] == nil then
        XPMon_DATA[level] = {
            total = 0,
            events = {}
        };
    end
    if XPMon_DATA[level].events[source] == nil then
        XPMon_DATA[level].events[source] = {};
    end
    table.insert(XPMon_DATA[level].events[source], event);
    XPMon_DATA[level].total = XPMon_DATA[level].total + event.amount;
end

function XPMon_setCurrentPlayerInfo()
    XPMon.currentXP = UnitXP("player");
    XPMon.currentXPRemaining = UnitXPMax("player") - XPMon.currentXP;
    XPMon.currentLevel = UnitLevel("player");
    XPMon_log(XPMon.currentXP, XPMon.currentXPRemaining);
end

function XPMon_log(...)
    if XPMon.DEBUG == true then
        print("XPMon_log: ", ...);
    end
end


-- Utility functions

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