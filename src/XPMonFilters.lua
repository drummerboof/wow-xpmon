XPMon = XPMon or {}

XPMon.SOURCE_KILL = "Mob Kills"
XPMon.SOURCE_QUEST = "Quests"
XPMon.SOURCE_DUNGEON = "Dungeons"
XPMon.SOURCE_PROFESSION = "Professions"
XPMon.SOURCE_PET_BATTLE = "Pet Battles"
XPMon.SOURCE_EXPLORATION = "Exploration"
XPMon.SOURCE_PVP = "PVP"

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
                        source = XPMon.SOURCE_KILL,
                        restedBonus = tonumber(combatXPGain.rested or 0)
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
                    source = XPMon.SOURCE_QUEST
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
                    key = profession,
                    name = material,
                    source = XPMon.SOURCE_PROFESSION
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
                    source = XPMon.SOURCE_EXPLORATION
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
                            source = XPMon.SOURCE_DUNGEON,
                            key = "kills",
                            restedBonus = tonumber(combatXPGain.rested or 0),
                            group = tonumber(combatXPGain.group or 0),
                            details = {
                                instance = name or "Unknown",
                                type = instanceType or "Unknown",
                                difficulty = difficultyName or "Unknown"
                            }
                        })
                    end
                end

            -- Track instance rewards
            elseif event == "LFG_COMPLETION_REWARD" then

                result = XPEvent:new({
                    name = name or "Unknown",
                    source = XPMon.SOURCE_DUNGEON,
                    key = "rewards",
                    details = {
                        type = instanceType or "Unknown",
                        difficulty = difficultyName or "Unknown"
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
                    source = XPMon.SOURCE_PVP,
                    name = name or "Unknown"
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
                    source = XPMon.SOURCE_PET_BATTLE,
                    name = C_PetBattles.GetName(2, opponentPetIndex),
                    details = {
                        opponent = {
                            level = C_PetBattles.GetLevel(2, opponentPetIndex),
                            wild = C_PetBattles.IsWildBattle()
                        }
                    }
                })
            end
            return result
        end
    }
}