package.path = package.path .. "../../?.lua"
require("XPMonUtils")
require("XPMonFilters")

describe("XPMon Filters", function ()

    setup(function ()
        XPMon.DEBUG = false
    end)

    describe("XP_MOB_KILL", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_MOB_KILL.events, {
                CHAT_MSG_COMBAT_XP_GAIN = true
            })
        end)

        it("Captures mob kill info for non rested kills", function ()
            local result = XPMon.filters.XP_MOB_KILL.handler("CHAT_MSG_COMBAT_XP_GAIN", "Boof dies, you gain 100 experience.")
            assert.are.equal(result.source, XPMon.SOURCE_KILL)
            assert.are.equal(result.rested, 0)
            assert.are.equal(result.details.mob, "Boof")
        end)

        it("Captures mob kill info for rested kills", function ()
            local result = XPMon.filters.XP_MOB_KILL.handler("CHAT_MSG_COMBAT_XP_GAIN", "Boof dies, you gain 100 experience. (+50 exp Rested bonus)")
            assert.are.equal(result.source, XPMon.SOURCE_KILL)
            assert.are.equal(result.rested, 50)
            assert.are.equal(result.details.mob, "Boof")
        end)

        it("Ignores irrelevant messages", function ()
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
            assert.are.equal(result.source, XPMon.SOURCE_QUEST)
            assert.are.equal(result.details.quest, "Awesome Super Quest")
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
            assert.are.equal(result.source, XPMon.SOURCE_PROFESSION)
            assert.are.equal(result.details.profession, "Herb Gathering")
            assert.are.equal(result.details.material, "Super Herb")

            result = XPMon.filters.XP_PROFESSION.handler("CHAT_MSG_OPENING", "You perform Another Profession on Another Herb.")
            assert.are.equal(result.source, XPMon.SOURCE_PROFESSION)
            assert.are.equal(result.details.profession, "Another Profession")
            assert.are.equal(result.details.material, "Another Herb")
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
            assert.are.equal(result.source, XPMon.SOURCE_EXPLORATION)
            assert.are.equal(result.details.place, "The Ruins of Some Trolls")
        end)

        it("Ignores irrelevant messages", function ()
            local result = XPMon.filters.XP_EXPLORATION.handler("CHAT_MSG_SYSTEM", "Some other message")
            assert.are.equal(result, nil)
        end)

    end)

    describe("XP_DUNGEON_FINDER", function ()

        it("Listens for the correct events", function ()
            assert.are.same(XPMon.filters.XP_DUNGEON_FINDER.events, {
                LFG_COMPLETION_REWARD = true
            })
        end)

        it("Captures dungeon completion events", function ()
            GetInstanceInfo = spy.new(function ()
                return "instanceName", "instanceType", "difficultyID", "difficultyName", "maxPlayers", "dynamicDifficulty", "isDynamic", "instanceMapID", "instanceGroupSize"
            end)

            local result = XPMon.filters.XP_DUNGEON_FINDER.handler("LFG_COMPLETION_REWARD")
            assert.are.equal(result.source, XPMon.SOURCE_DUNGEON)
            assert.are.equal(result.details.instance, "instanceName")
            assert.are.equal(result.details.type, "instanceType")
            assert.are.equal(result.details.difficulty, "difficultyName")
        end)

    end)

end)
