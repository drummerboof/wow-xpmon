package.path = package.path .. "../../?.lua"
require("XPMonUtils")
require("XPMonFilters")
require("XPMon")


describe("XPMon Addon", function()

    setup(function()
        XPMON_DEBUG = false
    end)

    describe("XPMon:onLoad", function()

        it("Registers all of the correct events for the addon", function()
            local mockAddon = {
                RegisterEvent = spy.new(function() end)
            }

            XPMon.XPEvents = { XP_TEST_EVENT = true, XP_ANOTHER_TEST_EVENT = true }
            XPMon.otherEvents = { TEST_EVENT = true, ANOTHER_TEST_EVENT = true }

            XPMon:onLoad(mockAddon)

            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "XP_TEST_EVENT")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "TEST_EVENT")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "XP_ANOTHER_TEST_EVENT")
            assert.spy(mockAddon.RegisterEvent).was_called_with(mockAddon, "ANOTHER_TEST_EVENT")
        end)
    end)

    describe("XPMon:onEvent", function()

        it("Calls the appropirate event handlers for the events", function()

        end)
    end)
end)
