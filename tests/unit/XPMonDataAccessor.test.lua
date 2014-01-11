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
                source = "Quest",
                experience = 200,
                restedBonus = 0,
                details = {
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
                                    time = 100,
                                    experience = 200,
                                    restedBonus = 0,
                                    details = {
                                        quest = "A quest"
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                source = "Mob Kill",
                experience = 50,
                restedBonus = 25,
                details = {
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
                                    time = 100,
                                    experience = 200,
                                    restedBonus = 0,
                                    details = {
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
                                    time = 100,
                                    experience = 50,
                                    restedBonus = 25,
                                    details = {
                                        quest = "A mob"
                                    }
                                }
                            }
                        }
                    }
                }
            }, XPMon_DATA)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                source = "Mob Kill",
                experience = 100,
                restedBonus = 50,
                details = {
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
                                    time = 100,
                                    experience = 200,
                                    restedBonus = 0,
                                    details = {
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
                                    time = 100,
                                    experience = 50,
                                    restedBonus = 25,
                                    details = {
                                        quest = "A mob"
                                    }
                                },
                                {
                                    time = 100,
                                    experience = 100,
                                    restedBonus = 50,
                                    details = {
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

        it("Saves XP events under the key if provided", function()
            XPMon_DATA = {}
            UnitXPMax = spy.new(function()
                return 2500
            end)

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                source = "Quest",
                experience = 200,
                restedBonus = 0,
                details = {
                    anything = "here"
                }
            }))

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                source = "Dungeons",
                key = "rewards",
                experience = 200,
                restedBonus = 0,
                details = {
                    anything = "here"
                }
            }))

            XPMonDataAccessor:addXPEventForLevel(XPMon_DATA, 10, XPEvent:new({
                source = "Dungeons",
                key = "kills",
                experience = 100,
                restedBonus = 50,
                details = {
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
                                    time = 100,
                                    experience = 200,
                                    restedBonus = 0,
                                    details = {
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
                                        time = 100,
                                        experience = 200,
                                        restedBonus = 0,
                                        details = {
                                            anything = "here"
                                        }
                                    }
                                },
                                kills = {
                                    {
                                        time = 100,
                                        experience = 100,
                                        restedBonus = 50,
                                        details = {
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