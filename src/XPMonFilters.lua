XPMon = XPMon or {}

XPMon.SOURCE_UNKNOWN = 0
XPMon.SOURCE_KILL = 1
XPMon.SOURCE_QUEST = 2
XPMon.SOURCE_DUNGEON = 3
XPMon.SOURCE_PROFESSION = 4
XPMon.SOURCE_PET_BATTLE = 5
XPMon.SOURCE_EXPLORATION = 6
XPMon.SOURCE_PVP = 7
XPMon.SOURCE_CHEST = 8

XPMon.SOURCES = {
    [XPMon.SOURCE_UNKNOWN] = "Unknown",
    [XPMon.SOURCE_KILL] = "Mob Kill",
    [XPMon.SOURCE_QUEST] = "Quests",
    [XPMon.SOURCE_DUNGEON] = "Dungeons",
    [XPMon.SOURCE_PROFESSION] = "Professions",
    [XPMon.SOURCE_PET_BATTLE] = "Pet Battles",
    [XPMon.SOURCE_EXPLORATION] = "Exploration",
    [XPMon.SOURCE_PVP] = "PVP",
    [XPMon.SOURCE_CHEST] = "Chest"
}

function XPMon.combatXPGainInfo(msg)
    local s, e, mob, exp, rested, group
    s, e, mob, exp = msg:find("^(.+) dies, you gain ([%d]+) experience.")
    if mob and exp then
        s, e, rested = msg:find("%+([%d]+) exp Rested bonus")
        s, e, group = msg:find("%+([%d]+) exp Group bonus%)")
    end
    return {
        mob = mob,
        experience = exp,
        rested = rested,
        group = group
    }
end

XPMon.filters = {
    XP_MOB_KILL = {
        state = {},
        events = { CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            local result
            local inInstance, instanceType = IsInInstance()
            if instanceType ~= "party" then
                local combatXPGain = XPMon.combatXPGainInfo(data)
                if combatXPGain.mob then
                    result = XPEvent:new({
                        name = combatXPGain.mob,
                        src = XPMon.SOURCE_KILL,
                        rxp = tonumber(combatXPGain.rested or 0)
                    })
                end
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
                result = XPEvent:new({
                    name = quest,
                    src = XPMon.SOURCE_QUEST
                })
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
                result = XPEvent:new({
                    k = profession,
                    name = material,
                    src = XPMon.SOURCE_PROFESSION
                })
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
                result = XPEvent:new({
                    name = place,
                    src = XPMon.SOURCE_EXPLORATION
                })
            end
            return result
        end
    },
    XP_DUNGEON = {
        state = {},
        events = { LFG_COMPLETION_REWARD = true, CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            local result
            local inInstance, instanceType = IsInInstance()
            local name, infoInstanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()


            -- Track instance kills
            if event == "CHAT_MSG_COMBAT_XP_GAIN" then
                if instanceType == "party" then
                    local combatXPGain = XPMon.combatXPGainInfo(data)
                    if combatXPGain.mob then
                        result = XPEvent:new({
                            name = combatXPGain.mob,
                            src = XPMon.SOURCE_DUNGEON,
                            k = "kills",
                            rxp = tonumber(combatXPGain.rested or 0),
                            gxp = tonumber(combatXPGain.group or 0),
                            i = {
                                i = name or "Unknown",
                                t = instanceType or "Unknown",
                                d = difficultyName or "Unknown"
                            }
                        })
                    end
                end

            -- Track instance rewards
            elseif event == "LFG_COMPLETION_REWARD" then

                result = XPEvent:new({
                    name = name or "Unknown",
                    src = XPMon.SOURCE_DUNGEON,
                    k = "rewards",
                    i = {
                        t = instanceType or "Unknown",
                        d = difficultyName or "Unknown"
                    }
                })
            end

            return result
        end
    },
    XP_PVP = {
        state = {},
        events = { CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            local result
            local inInstance, instanceType = IsInInstance("player")
            local s, e, exp = data:find("^You gain ([%d]+) experience.$")
            local name, infoInstanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize = GetInstanceInfo()
            if exp and instanceType == "pvp" then
                result = XPEvent:new({
                    src = XPMon.SOURCE_PVP,
                    name = name or "Unknown"
                })
            end

            return result
        end
    },
    XP_CHEST = {
        state = {},
        events = { CHAT_MSG_COMBAT_XP_GAIN = true },
        handler = function(event, data)
            local result
            local inInstance, instanceType = IsInInstance("player")
            local s, e, exp = data:find("^You gain ([%d]+) experience.$")
            if exp and instanceType ~= "pvp" then
                result = XPEvent:new({
                    src = XPMon.SOURCE_CHEST
                })
            end

            return result
        end
    },
    XP_PET_BATTLE = {
        state = {},
        events = { PET_BATTLE_FINAL_ROUND = true },
        handler = function(event, data)
            local result
            if data == 1 then
                local opponentPetIndex = C_PetBattles.GetActivePet(2)
                result = XPEvent:new({
                    src = XPMon.SOURCE_PET_BATTLE,
                    name = C_PetBattles.GetName(2, opponentPetIndex),
                    i = {
                        o = { -- opponent
                            l = C_PetBattles.GetLevel(2, opponentPetIndex), -- level
                            w = C_PetBattles.IsWildBattle() -- wild
                        }
                    }
                })
            end
            return result
        end
    }
}