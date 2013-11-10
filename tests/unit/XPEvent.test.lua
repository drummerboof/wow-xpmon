package.path = package.path .. "../../?.lua"
require("XPEvent")
require("XPMonUtils")

describe("XPEvent", function ()

    setup(function ()
        time = spy.new(function () return 100 end)
    end)

    describe("XPEvent:new", function ()

        it("Creates a new XP event using defaults when no data given", function ()
            local event = XPEvent:new()

            assert.are.equal("Unknown", event:data().source)
            assert.are.equal(0, event:data().experience)
            assert.are.equal(0, event:data().rested)
            assert.are.same({}, event:data().details)
            assert.are.same(100, event:data().time)
        end)

        it("Maintains seperate var scope per instance", function ()
            local args = { bar = "foo" }
            local event1 = XPEvent:new(args)
            local event2 = XPEvent:new()

            event1:data().details.foo = "bar"
            event1:set("bar", "something else")

            assert.are.same({ foo = "bar" }, event1:data().details)
            assert.are.same({}, event2:data().details)
            assert.are.same({ bar = "foo" }, args)
        end)

        it("Uses values passed in on construction over defaults", function ()
            local event = XPEvent:new({
                source = "Quests",
                experience = 100,
                details = {
                    quest = "A quest"
                }
            })
            assert.are.equal("Quests", event:data().source)
            assert.are.equal(100, event:data().experience)
            assert.are.equal(0, event:data().rested)
            assert.are.same({ quest = "A quest" }, event:data().details)
            assert.are.same(100, event:data().time)
        end)

    end)

    describe("XPEvent:get", function ()

        it("Gets the value from the event", function ()
            local event = XPEvent:new({
                source = "Quests",
                experience = 100,
                details = {
                    quest = "A quest"
                }
            })
            assert.are.equal("Quests", event:get("source"))
            assert.are.equal(100, event:get("experience"))
            assert.are.same({ quest = "A quest" }, event:get("details"))
        end)
    end)

    describe("XPEvent:set", function ()

        it("Sets the value on the event", function ()
            local event = XPEvent:new()
            event:set("source", "Quests")
            event:set("experience", 120)
            event:set("details", { quest = "A quest" })

            assert.are.equal("Quests", event:get("source"))
            assert.are.equal(120, event:get("experience"))
            assert.are.same({ quest = "A quest" }, event:get("details"))
        end)
    end)

end)
