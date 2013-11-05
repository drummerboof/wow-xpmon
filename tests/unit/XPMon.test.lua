package.path = package.path .. ";../../?.lua";
require("XPMon");

describe("XPMon Addon", function ()
    
    setup(function () 
        XPMon.DEBUG = false;    
    end);

    describe("XPMon_onLoad", function () 

        it("Registers all of the correct events for the addon", function () 
            local mockSelf = {
                RegisterEvent = spy.new(function () end)
            };
            
            XPMon.XPEvents = { XP_TEST_EVENT = true, XP_ANOTHER_TEST_EVENT = true };
            XPMon.otherEvents = { TEST_EVENT = true, ANOTHER_TEST_EVENT = true };
    
            XPMon_onLoad(mockSelf);
    
            assert.spy(mockSelf.RegisterEvent).was_called_with(mockSelf, "XP_TEST_EVENT");
            assert.spy(mockSelf.RegisterEvent).was_called_with(mockSelf, "TEST_EVENT");
            assert.spy(mockSelf.RegisterEvent).was_called_with(mockSelf, "XP_ANOTHER_TEST_EVENT");
            assert.spy(mockSelf.RegisterEvent).was_called_with(mockSelf, "ANOTHER_TEST_EVENT");
        end);

    end);

end);
