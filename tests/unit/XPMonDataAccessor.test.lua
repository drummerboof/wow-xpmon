package.path = package.path .. "../../?.lua"
require("XPEvent")
require("XPMonUtils")
require("XPMonDataAccessor")

describe("XPMonDataAccessor", function ()

    describe("XPMonDataAccessor:addXPEventForLevel", function()

        it("Correctly saves the XP event", function()
            XPMon_DATA = {}
            UnitXPMax = spy.new(function()
                return 2500
            end)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Quest",
                xp = 200,
                rxp = 0,
                i = {
                    quest = "A quest"
                }
            }))

            assert.are.same({
                [10] = {
                    total = 200,
                    max = 2500,
                    data = {
                        Quest = {
                            keys = {},
                            total = 200,
                            events = {
                                {
                                    t = 100,
                                    xp = 200,
                                    rxp = 0,
                                    i = {
                                        quest = "A quest"
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Mob Kill",
                xp = 50,
                rxp = 25,
                i = {
                    quest = "A mob"
                }
            }))

            assert.are.same({
                [10] = {
                    total = 250,
                    max = 2500,
                    data = {
                        ["Quest"] = {
                            keys = {},
                            total = 200,
                            events = {
                                {
                                    t = 100,
                                    xp = 200,
                                    rxp = 0,
                                    i = {
                                        quest = "A quest"
                                    }
                                }
                            }
                        },
                        ["Mob Kill"] = {
                            keys = {},
                            total = 50,
                            events = {
                                {
                                    t = 100,
                                    xp = 50,
                                    rxp = 25,
                                    i = {
                                        quest = "A mob"
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Mob Kill",
                xp = 100,
                rxp = 50,
                i = {
                    quest = "Another mob"
                }
            }))

            assert.are.same({
                [10] = {
                    total = 350,
                    max = 2500,
                    data = {
                        ["Quest"] = {
                            keys = {},
                            total = 200,
                            events = {
                                {
                                    t = 100,
                                    xp = 200,
                                    rxp = 0,
                                    i = {
                                        quest = "A quest"
                                    }
                                }
                            }
                        },
                        ["Mob Kill"] = {
                            keys = {},
                            total = 150,
                            events = {
                                {
                                    t = 100,
                                    xp = 50,
                                    rxp = 25,
                                    i = {
                                        quest = "A mob"
                                    }
                                },
                                {
                                    t = 100,
                                    xp = 100,
                                    rxp = 50,
                                    i = {
                                        quest = "Another mob"
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)

            UnitXPMax:revert()
        end)

        it("Correctly saves the XP event stripping i if empty", function()
            XPMon_DATA = {}
            UnitXPMax = spy.new(function()
                return 2500
            end)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Quest",
                xp = 200,
                rxp = 0,
                i = {}
            }))

            assert.are.same({
                [10] = {
                    total = 200,
                    max = 2500,
                    data = {
                        Quest = {
                            keys = {},
                            total = 200,
                            events = {
                                {
                                    t = 100,
                                    xp = 200,
                                    rxp = 0
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)
        end)

        it("Saves XP events under the key if provided", function()
            XPMon_DATA = {}
            UnitXPMax = spy.new(function()
                return 2500
            end)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Quest",
                xp = 200,
                rxp = 0,
                i = {
                    anything = "here"
                }
            }))

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Dungeons",
                k = "rewards",
                xp = 200,
                rxp = 0,
                i = {
                    anything = "here"
                }
            }))

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                src = "Dungeons",
                k = "kills",
                xp = 100,
                rxp = 50,
                i = {
                    anything = "here"
                }
            }))

            assert.are.same({
                [10] = {
                    total = 500,
                    max = 2500,
                    data = {
                        ["Quest"] = {
                            total = 200,
                            keys = {},
                            events = {
                                {
                                    t = 100,
                                    xp = 200,
                                    rxp = 0,
                                    i = {
                                        anything = "here"
                                    }
                                }
                            }
                        },
                        ["Dungeons"] = {
                            total = 300,
                            keys = { rewards = true, kills = true },
                            events = {
                                rewards = {
                                    {
                                        t = 100,
                                        xp = 200,
                                        rxp = 0,
                                        i = {
                                            anything = "here"
                                        }
                                    }
                                },
                                kills = {
                                    {
                                        t = 100,
                                        xp = 100,
                                        rxp = 50,
                                        i = {
                                            anything = "here"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)
        end)
    end)

end)