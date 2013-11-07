XPMon = XPMon or {}

XPMon.SOURCE_KILL = "Mob Kills"
XPMon.SOURCE_QUEST = "Quests"
XPMon.SOURCE_DUNGEON = "Looking for Dungeon"
XPMon.SOURCE_PROFESSION = "Professions"
XPMon.SOURCE_PET_BATTLE = "Pet Battles"
XPMon.SOURCE_EXPLORATION = "Exploration"
XPMon.SOURCE_BATTLEGROUND = "Battlegrounds"

XPMon.filters = {

    XP_MOB_KILL = {
        state = {},
        events = { CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            local result
            local s, e, mob, exp = data:find("^(.+) dies, you gain ([%d]+) experience.")
            if mob and exp then
                local s, e, rested = data:find(" %(%+([%d]+) exp Rested bonus%)$")
                result = {
                    source = XPMon.SOURCE_KILL,
                    rested = tonumber(rested or 0),
                    details = {
                        mob = mob
                    }
                }
            end
            return result
        end
    },

    XP_QUEST = {
        state = {},
        events = { CHAT_MSG_SYSTEM = true },
        handler = function(event, data)
            local result
            local s, e, quest = data:find("^(.+) completed.")
            if quest then
                result = {
                    source = XPMon.SOURCE_QUEST,
                    rested = 0,
                    details = {
                        quest = quest
                    }
                }
            end
            return result
        end
    },

    XP_PROFESSION = {
        state = {},
        events = { CHAT_MSG_OPENING = true },
        handler = function(event, data)
            local result
            local s, e, profession, material = data:find("^You perform (.+) on (.+).$")
            if profession and material then
                result = {
                    source = XPMon.SOURCE_PROFESSION,
                    rested = 0,
                    details = {
                        profession = profession,
                        material = material
                    }
                }
            end
            return result
        end
    },

    XP_EXPLORATION = {
        state = {},
        events = { CHAT_MSG_SYSTEM = true },
        handler = function(event, data)
            local result
            local s, e, place, exp = data:find("^Discovered (.+): ([%d]+) experience gained$")
            if place and exp then
                result = {
                    source = XPMon.SOURCE_EXPLORATION,
                    rested = 0,
                    details = {
                        place = place
                    }
                }
            end
            return result
        end
    },

    XP_DUNGEON_FINDER = {
        state = {},
        events = { LFG_COMPLETION_REWARD = true },
        handler = function(event, data)
            return nil
        end
    },

    XP_BATTLEGROUND = {
        state = {},
        events = {},
        handler = function(event, data)
            return nil
        end
    },

    XP_PET_BATTLE = {
        state = {},
        events = {},
        handler = function(event, data)
            return nil
        end
    }
}