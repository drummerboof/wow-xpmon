-- XPMon saved data
XPMon_DATA = {};

XPMon = {};
XPMon.debug = true;
XPMon.name = "XPMon";
XPMon.nextXPGain = nil;
XPMon.currentXP = nil;

XPMon.XPEvents = {
    ["CHAT_MSG_SYSTEM"] = true,
    ["CHAT_MSG_COMBAT_XP_GAIN"] = true,
    ["CHAT_MSG_OPENING"] = true,
    ["LFG_COMPLETION_REWARD"] = true
};

XPMon.otherEvents = {
    -- Listen to XP changes here and see if we have determined the cause
    ["PLAYER_XP_UPDATE"] = XPMon_onPlayerXPUpdate,
    -- Load saved player XP data
    ["ADDON_LOADED"] = XPMon_onAddonLoaded,
}

XPMon.filters = {
    ["XP_MOB_KILL"] = {
        ["state"] = {},
        ["events"] = { ["CHAT_MSG_COMBAT_XP_GAIN"] = true },
        ["handler"] = function(event, data)
            XPMon_log("Handler!", event, data);
            XPMon.nextXPGain = {};
        end
    },
    ["XP_QUEST"] = {
        ["state"] = {},
        ["events"] = {},
        ["handler"] = function(event, data)

        end
    },
    ["XP_PROFESSION"] = {
        ["state"] = {},
        ["events"] = {},
        ["handler"] = function(event, data)

        end
    },
    ["XP_EXPLORATION"] = {
        ["state"] = {},
        ["events"] = {},
        ["handler"] = function(event, data)

        end
    },
    ["XP_DUNGEON_FINDER"] = {
        ["state"] = {},
        ["events"] = {},
        ["handler"] = function(event, data)

        end
    },
    ["XP_BATTLEGROUND"] = {
        ["state"] = {},
        ["events"] = {},
        ["handler"] = function(event, data)

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

    XPMon_DATA = { ["foo"] = "barboof" }

    XPMon_log("XPMon_onLoad");
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
            value.handler(event, data);
        end
        if XPMon_nextXPGainSpokenFor() then
            break;
        end
    end
end

function XPMon_onPlayerXPUpdate(event, data)

end

function XPMon_onAddonLoaded(event, addon)
    XPMon_log(addon);
    if addon == XPMon.name then
        XPMon_log("XPMon_onAddonLoaded", addon);
    end
end

function XPMon_nextXPGainSpokenFor()
    return XPMon.nextXPGain ~= nil
end

function XPMon_log(...)
    if XPMon.debug == true then
        print("XPMon_log: ", ...);
    end
end