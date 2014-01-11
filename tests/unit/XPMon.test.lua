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
    end)

    describe("XPMon:onEvent", function()

        before_each(function()
            XPMon.nextXPGain = nil
            for name, filter in pairs(XPMon.filters) do
                filter.handler:revert()
                spy.on(filter, "handler")
            end
        end)

        it("Overwrites an existing nextXPGain if there is one", function()
            XPMon.nextXPGain = "bob"
            XPMon:onEvent(nil, "CHAT_MSG_SYSTEM", "args")
            assert.are.same("gain", XPMon.nextXPGain)
        end)

        it("Calls the appropirate event filter handlers for XP events CHAT_MSG_SYSTEM", function()
            XPMon:onEvent(nil, "CHAT_MSG_SYSTEM", "args")

            assert.are.same(XPMon.nextXPGain, "gain")
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
            XPMon.nextXPGain = nil
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
            XPMon.nextXPGain = XPEvent:new({
                source = "Quest",
                details = {
                    quest = "A Quest"
                }
            })
            XPMon.nextXPGain:set("time", 90)

            UnitXP = spy.new(function()
                return 120
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(1)
            assert.are.same({
                source = "Unknown",
                experience = 20,
                rested = true,
                restedBonus = 0,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {}
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
                source = "Unknown",
                experience = 20,
                rested = true,
                restedBonus = 0,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Sets one known XP event if nextXPGain is set and we have not levelled up", function()
            XPMon.currentXPRested = 0
            XPMon.nextXPGain = XPEvent:new({
                source = "Quest",
                details = {
                    quest = "A Quest"
                }
            })

            UnitXP = spy.new(function()
                return 150
            end)
            UnitLevel = spy.new(function()
                return 10
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(1)
            assert.are.same({
                source = "Quest",
                experience = 50,
                restedBonus = 0,
                rested = false,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {
                    quest = "A Quest"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
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
                source = "Unknown",
                experience = 10,
                rested = true,
                restedBonus = 0,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                source = "Unknown",
                experience = 40,
                rested = true,
                restedBonus = 0,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {}
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[2][3], 11)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Splits rested XP correctly when we level up", function()
            XPMon.currentXP = 190
            XPMon.currentXPRemaining = 10
            XPMon.nextXPGain = XPEvent:new({
                source = "Mob Kill",
                restedBonus = 25,
                details = {
                    mob = "A Mob"
                }
            })

            UnitXP = spy.new(function()
                return 40
            end)
            UnitLevel = spy.new(function()
                return 11
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                source = "Mob Kill",
                experience = 10,
                rested = true,
                restedBonus = 0,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                source = "Mob Kill",
                experience = 40,
                restedBonus = 25,
                rested = true,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[2][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[2][3], 11)
            assert.stub(XPMon.setCurrentPlayerInfo).was_called()
            assert.stub(UnitXP).was_called_with("player")
            assert.stub(UnitLevel).was_called_with("player")
        end)

        it("Splits rested XP correctly when we level up", function()
            XPMon.currentXP = 165
            XPMon.currentXPRemaining = 35
            XPMon.nextXPGain = XPEvent:new({
                source = "Mob Kill",
                rested = true,
                restedBonus = 25,
                details = {
                    mob = "A Mob"
                }
            })

            UnitXP = spy.new(function()
                return 25
            end)
            UnitLevel = spy.new(function()
                return 11
            end)

            XPMon:onPlayerXPUpdate()

            assert.stub(XPMonDataAccessor.addXPEventForLevel).was_called(2)
            assert.are.same({
                source = "Mob Kill",
                experience = 35,
                restedBonus = 10,
                rested = true,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {
                    mob = "A Mob"
                }
            }, XPMonDataAccessor.addXPEventForLevel.calls[1][4]:data())
            assert.are.equal(XPMonDataAccessor.addXPEventForLevel.calls[1][3], 10)
            assert.are.same({
                source = "Mob Kill",
                experience = 25,
                restedBonus = 15,
                rested = true,
                zone = "Goldshire",
                position = { x = 54.54, y = 65.65 },
                time = 100,
                details = {
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
            assert.are.equal(XPMon.nextXPGain, nil)

            UnitXP:revert()
            UnitXPMax:revert()
            UnitLevel:revert()
        end)
    end)

end)
