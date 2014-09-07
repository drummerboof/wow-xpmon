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

            assert.are.equal(0, event:data().src)
            assert.are.equal(0, event:data().xp)
            assert.are.equal(0, event:data().rxp)
            assert.are.same({}, event:data().i)
            assert.are.same(100, event:data().t)
        end)

        it("Maintains seperate var scope per instance", function ()
            local args = { bar = "foo" }
            local event1 = XPEvent:new(args)
            local event2 = XPEvent:new()

            event1:data().i.foo = "bar"
            event1:set("bar", "something else")

            assert.are.same({ foo = "bar" }, event1:data().i)
            assert.are.same({}, event2:data().i)
            assert.are.same({ bar = "foo" }, args)
        end)

        it("Uses values passed in on construction over defaults", function ()
            local event = XPEvent:new({
                src = "Quests",
                xp = 100,
                i = {
                    quest = "A quest"
                }
            })
            assert.are.equal("Quests", event:data().src)
            assert.are.equal(100, event:data().xp)
            assert.are.equal(0, event:data().rxp)
            assert.are.same({ quest = "A quest" }, event:data().i)
            assert.are.same(100, event:data().t)
        end)

    end)

    describe("XPEvent:get", function ()

        it("Gets the value from the event", function ()
            local event = XPEvent:new({
                src = "Quests",
                xp = 100,
                i = {
                    quest = "A quest"
                }
            })
            assert.are.equal("Quests", event:get("src"))
            assert.are.equal(100, event:get("xp"))
            assert.are.same({ quest = "A quest" }, event:get("i"))
        end)
    end)

    describe("XPEvent:set", function ()

        it("Sets the value on the event", function ()
            local event = XPEvent:new()
            event:set("src", "Quests")
            event:set("xp", 120)
            event:set("i", { quest = "A quest" })

            assert.are.equal("Quests", event:get("src"))
            assert.are.equal(120, event:get("xp"))
            assert.are.same({ quest = "A quest" }, event:get("i"))
        end)
    end)

end)
