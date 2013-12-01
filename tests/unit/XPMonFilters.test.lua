package.path = package.path .. "../../?.lua"
require("XPMonUtils")
require("XPMonFilters")

describe("XPMon Filters", function ()

    local originalCombatXPGainInfo

    setup(function ()
        XPMon.DEBUG = false
    end)

    before_each(function ()
        originalCombatXPGainInfo = XPMon.combatXPGainInfo
    end)

    after_each(function ()
        XPMon.combatXPGainInfo = originalCombatXPGainInfo
    end)

    describe("XPMon.combatXPGainInfo", function ()

        it("Correctly extracts combat XP gain details", function ()
            local result1 = XPMon.combatXPGainInfo("Boof dies, you gain 100 experience.")
            local result2 = XPMon.combatXPGainInfo("Boof dies, you gain 100 experience. (+50 exp Rested bonus)")
            local result3 = XPMon.combatXPGainInfo("Boof dies, you gain 100 experience. (+30 exp Group bonus)")
            local result4 = XPMon.combatXPGainInfo("Boof dies, you gain 100 experience. (+50 exp Rested bonus, +30 exp Group bonus)")

            assert.are.same({
                mob = "Boof",
                experience = "100",
                rested = nil,
                group = nil
            }, result1)

            assert.are.same({
                mob = "Boof",
                experience  = "100",
                rested = "50",
                group = nil
            }, result2)

            assert.are.same({
                mob = "Boof",
                experience  = "100",
                rested = nil,
                group = "30"
            }, result3)

            assert.are.same({
                mob = "Boof",
                experience  = "100",
                rested = "50",
                group = "30"
            }, result4)
        end)
    end)

    describe("XP_MOB_KILL", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_MOB_KILL.events, {
                CHAT_MSG_COMBAT_XP_GAIN = true
            })
        end)

        it("Captures mob kill info for non rested kills", function ()
            IsInInstance = spy.new(function () return nil, "none" end)
            XPMon.combatXPGainInfo = spy.new(function ()
                return {
                    mob = "Boof",
                    experience = "100",
                    rested = "50"
                }
            end)

            local result = XPMon.filters.XP_MOB_KILL.handler("CHAT_MSG_COMBAT_XP_GAIN", "message")

            assert.spy(XPMon.combatXPGainInfo).was.called_with("message")
            assert.are.equal(XPMon.SOURCE_KILL, result:get("source"))
            assert.are.equal(50, result:get("restedBonus"))
            assert.are.equal("Boof", result:get("name"))
        end)

        it("Ignores mob kill when in a 5 man instance", function ()
            IsInInstance = spy.new(function () return 1, "party" end)
            XPMon.combatXPGainInfo = spy.new(function () end)

            local result = XPMon.filters.XP_MOB_KILL.handler("CHAT_MSG_COMBAT_XP_GAIN", "Boof dies, you gain 100 experience. (+50 exp Rested bonus)")

            assert.spy(XPMon.combatXPGainInfo).was_not_called()
            assert.are.equal(result, nil)
        end)

        it("Ignores irrelevant messages", function ()
            IsInInstance = spy.new(function () return nil, "none" end)

            local result = XPMon.filters.XP_MOB_KILL.handler("CHAT_MSG_COMBAT_XP_GAIN", "Some other message")

            assert.are.equal(result, nil)
        end)

    end)

    describe("XP_QUEST", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_QUEST.events, {
                CHAT_MSG_SYSTEM = true
            })
        end)

        it("Captures quest completions", function ()
            local result = XPMon.filters.XP_QUEST.handler("CHAT_MSG_SYSTEM", "Awesome Super Quest completed.")
            assert.are.equal(XPMon.SOURCE_QUEST, result:get("source"))
            assert.are.equal("Awesome Super Quest", result:get("name"))
        end)

        it("Ignores irrelevant messages", function ()
            local result = XPMon.filters.XP_QUEST.handler("CHAT_MSG_SYSTEM", "Some other message")
            assert.are.equal(result, nil)
        end)

    end)

    describe("XP_PROFESSION", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_PROFESSION.events, {
                CHAT_MSG_OPENING = true
            })
        end)

        it("Captures gathering actions", function ()
            local result = XPMon.filters.XP_PROFESSION.handler("CHAT_MSG_OPENING", "You perform Herb Gathering on Super Herb.")
            assert.are.equal(XPMon.SOURCE_PROFESSION, result:get("source"))
            assert.are.equal("Herb Gathering", result:get("key"))
            assert.are.equal("Super Herb", result:get("name"))

            result = XPMon.filters.XP_PROFESSION.handler("CHAT_MSG_OPENING", "You perform Another Profession on Another Herb.")
            assert.are.equal(XPMon.SOURCE_PROFESSION, result:get("source"))
            assert.are.equal("Another Profession", result:get("key"))
            assert.are.equal("Another Herb", result:get("name"))
        end)

        it("Ignores irrelevant messages", function ()
            local result = XPMon.filters.XP_PROFESSION.handler("CHAT_MSG_OPENING", "Some other message")
            assert.are.equal(result, nil)
        end)

    end)

    describe("XP_EXPLORATION", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_EXPLORATION.events, {
                CHAT_MSG_SYSTEM = true
            })
        end)

        it("Captures exploration events", function ()
            local result = XPMon.filters.XP_EXPLORATION.handler("CHAT_MSG_SYSTEM", "Discovered The Ruins of Some Trolls: 100 experience gained")
            assert.are.equal(XPMon.SOURCE_EXPLORATION, result:get("source"))
            assert.are.equal("The Ruins of Some Trolls", result:get("name"))
        end)

        it("Ignores irrelevant messages", function ()
            local result = XPMon.filters.XP_EXPLORATION.handler("CHAT_MSG_SYSTEM", "Some other message")
            assert.are.equal(result, nil)
        end)

    end)

    describe("XP_DUNGEONS", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_DUNGEON.events, {
                LFG_COMPLETION_REWARD = true, CHAT_MSG_COMBAT_XP_GAIN = true
            })
        end)

        it("Captures dungeon reward XP events", function ()
            GetInstanceInfo = spy.new(function ()
                return "instanceName", "instanceType", "difficultyID", "difficultyName", "maxPlayers", "dynamicDifficulty", "isDynamic", "instanceMapID", "instanceGroupSize"
            end)
            IsInInstance = spy.new(function () return 1, "party" end)

            local result = XPMon.filters.XP_DUNGEON.handler("LFG_COMPLETION_REWARD")
            assert.are.equal(XPMon.SOURCE_DUNGEON, result:get("source"))
            assert.are.equal("rewards", result:get("key"))
            assert.are.equal("instanceName", result:get("name"))
            assert.are.same({
                type = "party",
                difficulty = "difficultyName"
            }, result:get("details"))

            IsInInstance = spy.new(function () return false, "none" end)
            GetInstanceInfo = spy.new(function () return nil end)

            local result = XPMon.filters.XP_DUNGEON.handler("LFG_COMPLETION_REWARD")
            assert.are.equal(XPMon.SOURCE_DUNGEON, result:get("source"))
            assert.are.equal("rewards", result:get("key"))
            assert.are.equal("Unknown", result:get("name"))
            assert.are.same({
                type = "none",
                difficulty = "Unknown"
            }, result:get("details"))
        end)

        it("Captures dungeon kill XP events", function ()
            GetInstanceInfo = spy.new(function ()
                return "instanceName", "instanceType", "difficultyID", "difficultyName", "maxPlayers", "dynamicDifficulty", "isDynamic", "instanceMapID", "instanceGroupSize"
            end)
            IsInInstance = spy.new(function () return 1, "party" end)
            XPMon.combatXPGainInfo = spy.new(function ()
                return {
                    mob = "Boof",
                    experience = "130",
                    rested = "50",
                    group = "30"
                }
            end)

            local result = XPMon.filters.XP_DUNGEON.handler("CHAT_MSG_COMBAT_XP_GAIN", "message")

            assert.are.equal(XPMon.SOURCE_DUNGEON, result:get("source"))
            assert.are.equal("kills", result:get("key"))
            assert.are.equal("Boof", result:get("name"))
            assert.are.equal(50, result:get("restedBonus"))
            assert.are.equal(30, result:get("group"))
            assert.are.same({
                instance = "instanceName",
                type = "party",
                difficulty = "difficultyName"
            }, result:get("details"))
        end)

        it("Ignores kill XP events when not in a dungeon", function ()
            IsInInstance = spy.new(function () return nil, "none" end)
            local result = XPMon.filters.XP_DUNGEON.handler("CHAT_MSG_COMBAT_XP_GAIN", "message")
            assert.are.equal(nil, result)
        end)

    end)

    describe("XP_PVP", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_PVP.events, {
                CHAT_MSG_COMBAT_XP_GAIN = true
            })
        end)

        it("Captures XP events while in a PVP instance", function ()
            GetInstanceInfo = spy.new(function ()
                return "instanceName", "instanceType", "difficultyID", "difficultyName", "maxPlayers", "dynamicDifficulty", "isDynamic", "instanceMapID", "instanceGroupSize"
            end)
            IsInInstance = spy.new(function () return 1, "pvp" end)

            local result = XPMon.filters.XP_PVP.handler("CHAT_MSG_COMBAT_XP_GAIN", "You gain 2020 experience.")

            assert.are.equal(XPMon.SOURCE_PVP, result:get("source"))
            assert.are.equal("instanceName", result:get("name"))
        end)

        it("Ignores XP events while NOT in a PVP instance", function ()
            GetInstanceInfo = spy.new(function ()
                return "instanceName", "instanceType", "difficultyID", "difficultyName", "maxPlayers", "dynamicDifficulty", "isDynamic", "instanceMapID", "instanceGroupSize"
            end)
            IsInInstance = spy.new(function () return 1, "party" end)

            local result = XPMon.filters.XP_PVP.handler("CHAT_MSG_COMBAT_XP_GAIN", "You gain 2020 experience.")

            assert.are.equal(nil, result)

            IsInInstance = spy.new(function () return nil end)
            result = XPMon.filters.XP_PVP.handler("CHAT_MSG_COMBAT_XP_GAIN", "You gain 2020 experience.")
            assert.are.equal(nil, result)
        end)

    end)

    describe("XP_PET_BATTLE", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_PET_BATTLE.events, {
                PET_BATTLE_FINAL_ROUND = true
            })
        end)

        it("Captures pet battle over events", function ()
            C_PetBattles = {
                GetActivePet = spy.new(function (owner)
                    return 123
                end),
                GetName = spy.new(function (owner, index)
                    return "Opponent Pet"
                end),
                GetLevel = spy.new(function (owner, index)
                    return 6
                end),
                IsWildBattle = spy.new(function (owner, index)
                    return true
                end)
            }

            local result = XPMon.filters.XP_PET_BATTLE.handler("PET_BATTLE_FINAL_ROUND", 1)

            assert.spy(C_PetBattles.GetActivePet).was.called_with(2)
            assert.spy(C_PetBattles.GetName).was.called_with(2, 123)
            assert.spy(C_PetBattles.GetLevel).was.called_with(2, 123)
            assert.are.equal(XPMon.SOURCE_PET_BATTLE, result:get("source"))
            assert.are.equal("Opponent Pet", result:get("name"))
            assert.are.same({
                opponent = {
                    level = 6,
                    wild = true
                }
            }, result:get("details"))
        end)

    end)

end)
