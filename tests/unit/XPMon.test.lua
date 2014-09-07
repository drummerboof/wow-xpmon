package.path = package.path .. "../../?.lua"
require("XPMonFilters")
require("XPEvent")
require("XPMonDataAccessor")
require("XPMon")
require("XPMonUtils")

XPMonFrameSelectLevel = {}
UIDropDownMenu_SetText = spy.new(function() end)
XPMonTitleTextLevel = {
    SetText = spy.new(function() end)
}

describe("XPMon Addon", function()

    local filters

    setup(function()
        time = spy.new(function() return 100 end)
        GetPlayerMapPosition = spy.new(function() return 0.5454, 0.6565 end)
        GetMaxPlayerLevel = spy.new(function() return 90 end)
        UnitLevel = spy.new(function() return 10 end)
        assert:set_parameter("TableFormatLevel", 10)
        GetXPExhaustion = spy.new(function () return 100 end)

        XPMon.currentLevel = 10
        filters = XPMon.filters
        XPMon.DEBUG = false
        XPMon.filters = {
            FILTER_1 = {
                events = { CHAT_MSG_SYSTEM = true, CHAT_MSG_COMBAT_XP_GAIN = true },
                handler = spy.new(function()
                    return nil
                end)
            },
            FILTER_2 = {
                events = { CHAT_MSG_SYSTEM = true },
                handler = spy.new(function()
                    return "gain"
                end)
            },
            FILTER_3 = {
                events = { CHAT_MSG_SYSTEM = true, CHAT_MSG_OPENING = true },
                handler = spy.new(function()
                    return nil
                end)
            }
        }
    end)

    teardown(function()
        XPMon.filters = filters
    end)

    describe("XPMon:onLoad", function()

        it("Registers all of the correct events for the addon", function()
            local mockAddon = {
                RegisterEvent = spy.new(function() end)
            }

            XPMon:onLoad(mockAddon)

            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "CHAT_MSG_SYSTEM")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "CHAT_MSG_COMBAT_XP_GAIN")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "CHAT_MSG_OPENING")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "LFG_COMPLETION_REWARD")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "PET_BATTLE_FINAL_ROUND")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "PLAYER_XP_UPDATE")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "ADDON_LOADED")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "PLAYER_LOGIN")
        end)

        it("Doesn't register if the player is max level", function()
            local mockAddon = {
                RegisterEvent = spy.new(function() end)
            }

            UnitLevel = spy.new(function()
                return 90
            end)

            XPMon:onLoad(mockAddon)

            assert.spy(mockAddon.RegisterEvent).was_not_called()
        end)
    end)

    describe("XPMon:onEvent", function()

        before_each(function()
            XPMon.nextXPGains = {}
            for name, filter in pairs(XPMon.filters) do
                filter.handler:revert()
                spy.on(filter, "handler")
            end
        end)

        it("Overwrites an existing nextXPGain if there is one", function()
            XPMon.nextXPGains = {}
            XPMon:onEvent(nil, "CHAT_MSG_SYSTEM", "args")
            assert.are.same({"gain"}, XPMon.nextXPGains)
        end)

        it("Calls the appropirate event filter handlers for XP events CHAT_MSG_SYSTEM", function()
            XPMon:onEvent(nil, "CHAT_MSG_SYSTEM", "args")

            assert.are.same(XPMon.nextXPGains, {"gain"})
            assert.spy(XPMon.filters.FILTER_1.handler).was.called_with("CHAT_MSG_SYSTEM", "args")
            assert.spy(XPMon.filters.FILTER_2.handler).was.called_with("CHAT_MSG_SYSTEM", "args")
            assert.spy(XPMon.filters.FILTER_3.handler).was_not_called()
        end)

        it("Calls the appropirate event filter handlers for XP events CHAT_MSG_OPENING", function()
            XPMon:onEvent(nil, "CHAT_MSG_OPENING", "args")

            assert.are.same(XPMon.nextXPGain, nil)
            assert.spy(XPMon.filters.FILTER_1.handler).was_not_called()
            assert.spy(XPMon.filters.FILTER_2.handler).was_not_called()
            assert.spy(XPMon.filters.FILTER_3.handler).was.called_with("CHAT_MSG_OPENING", "args")
        end)

        it("Calls the appropirate event filter handlers for XP events CHAT_MSG_COMBAT_XP_GAIN", function()
            XPMon:onEvent(nil, "CHAT_MSG_COMBAT_XP_GAIN", "args")

            assert.are.same(XPMon.nextXPGain, nil)
            assert.spy(XPMon.filters.FILTER_1.handler).was.called_with("CHAT_MSG_COMBAT_XP_GAIN", "args")
            assert.spy(XPMon.filters.FILTER_2.handler).was_not_called()
            assert.spy(XPMon.filters.FILTER_3.handler).was_not_called()
        end)

        it("Returns if the player is max level", function()
            XPMon.currentLevel = 90
            XPMon:onEvent(nil, "CHAT_MSG_COMBAT_XP_GAIN", "args")
            XPMon:onEvent(nil, "CHAT_MSG_SYSTEM", "args")
            XPMon:onEvent(nil, "CHAT_MSG_OPENING", "args")
            assert.spy(XPMon.filters.FILTER_1.handler).was_not_called()
            assert.spy(XPMon.filters.FILTER_2.handler).was_not_called()
            assert.spy(XPMon.filters.FILTER_3.handler).was_not_called()

        end)
    end)

    describe("XPMon:onPlayerLogin", function()

        it("Calls setCurrentPlayerInfo", function()
            stub(XPMon, "setCurrentPlayerInfo")
            XPMon:onPlayerLogin()
            assert.spy(XPMon.setCurrentPlayerInfo).was_called()
            XPMon.setCurrentPlayerInfo:revert()
        end)
    end)

    describe("XPMon:onPlayerXPUpdate", function()

        before_each(function()
            XPMon.nextXPGains = {}
            XPMon.currentXP = 100
            XPMon.currentXPRemaining = 200
            XPMon.currentLevel = 10
            XPMon.currentXPRested = 100
            stub(XPMonDataAccessor, "addXPEventForLevel")
            stub(XPMon, "setCurrentPlayerInfo")
            GetRealZoneText = spy.new(function()
                return "Goldshire"
            end)
        end)

        after_each(function()
            UnitXP:revert()
            UnitLevel:revert()
            XPMon.setCurrentPlayerInfo:revert()
            XPMonDataAccessor.addXPEventForLevel:revert()
        end)

        it("Unsets the current XP event if it occured more that XP_GAIN_TIMEOUT seconds ago", function()
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Quest",
                i = {
                    quest = "A Quest"
                }
            }))
            XPMon.nextXPGains[1]:set("t", 90)

            UnitXP = spy.new(function()
                return 120
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(1)
            assert.are.same({
                src = 0,
                xp = 20,
                r = true,
                rxp = 0,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
        end)

        it("Sets one unknown XP event if nextXPGain is nil and we have not levelled up", function()

            UnitXP = spy.new(function()
                return 120
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(1)
            assert.are.same({
                src = 0,
                xp = 20,
                r = true,
                rxp = 0,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Sets one known XP event if nextXPGain is set and we have not levelled up", function()
            XPMon.currentXPRested = 0
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Quest",
                i = {
                    quest = "A Quest"
                }
            }))

            UnitXP = spy.new(function()
                return 150
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(1)
            assert.are.same({
                src = "Quest",
                xp = 50,
                rxp = 0,
                r = false,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    quest = "A Quest"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Sets two known XP events if nextXPGains has 2 gains", function()
            XPMon.currentXPRested = 0
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Quest",
                i = {
                    quest = "A Quest"
                }
            }))
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Mob Kills",
                name = "Some Mob"
            }))

            UnitXP = spy.new(function()
                return 150
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                src = "Quest",
                xp = 50,
                rxp = 0,
                r = false,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    quest = "A Quest"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.same({
                name = "Some Mob",
                src = "Mob Kills",
                xp = 50,
                rxp = 0,
                r = false,
                i = {},
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Sets two unknown XP events if nextXPGain is not set and we have levelled up", function()
            XPMon.currentXPRested = 100
            XPMon.currentXP = 190
            XPMon.currentXPRemaining = 10

            UnitXP = spy.new(function()
                return 40
            end)
            UnitLevel = spy.new(function()
                return 11
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                src = 0,
                xp = 10,
                r = true,
                rxp = 0,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                src = 0,
                xp = 40,
                r = true,
                rxp = 0,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[2][3], 11)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Splits rested XP correctly when we level up", function()
            XPMon.currentXP = 190
            XPMon.currentXPRemaining = 10
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Mob Kill",
                rxp = 25,
                i = {
                    mob = "A Mob"
                }
            }))

            UnitXP = spy.new(function()
                return 40
            end)
            UnitLevel = spy.new(function()
                return 11
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                src = "Mob Kill",
                xp = 10,
                r = true,
                rxp = 0,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                src = "Mob Kill",
                xp = 40,
                rxp = 25,
                r = true,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[2][3], 11)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Splits rested XP correctly when we level up with rested split across levels", function()
            XPMon.currentXP = 165
            XPMon.currentXPRemaining = 35
            table.insert(XPMon.nextXPGains, XPEvent:new({
                src = "Mob Kill",
                r = true,
                rxp = 25,
                i = {
                    mob = "A Mob"
                }
            }))

            UnitXP = spy.new(function()
                return 25
            end)
            UnitLevel = spy.new(function()
                return 11
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                src = "Mob Kill",
                xp = 35,
                rxp = 10,
                r = true,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                src = "Mob Kill",
                xp = 25,
                rxp = 15,
                r = true,
                z = "Goldshire",
                p = { x = 54.54, y = 65.65 },
                t = 100,
                i = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[2][3], 11)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)
    end)

    describe("XPMon:setCurrentPlayerInfo", function()

        it("Sets the XP, remaining XP, level, rested XP and nextXPGain correctly", function()
            UnitXP = spy.new(function()
                return 100
            end)
            UnitXPMax = spy.new(function()
                return 250
            end)
            GetXPExhaustion = spy.new(function()
                return 500
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon.nextXPGain = {}
            XPMon.currentXP = 0
            XPMon.currentXPRested = 0
            XPMon.currentLevel = 0
            XPMon.currentXPRemaining = 0
            XPMon:setCurrentPlayerInfo()

            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitXPMax).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
            assert.stub(GetXPExhaustion).was_called_with("player")

            assert.are.equal(XPMon.currentXP, 100)
            assert.are.equal(XPMon.currentXPRemaining, 150)
            assert.are.equal(XPMon.currentLevel, 10)
            assert.are.equal(XPMon.currentXPRested, 500)
            assert.are.same(XPMon.nextXPGains, {})

            UnitXP:revert()
            UnitXPMax:revert()
            UnitLevel:revert()
        end)
    end)

end)
