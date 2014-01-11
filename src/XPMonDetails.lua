XPMonDetails = {}

function XPMonDetails:onLoad(addon)

end

function XPMonDetails:onEvent(addon)

end

function XPMonDetails:onEvent(addon)

end

function XPMonDetails:showLevelInformation(level)
    XPMonFrameSelectLevel.selectedValue = level
    XPMonFrameSelectLevel.selectedName = "Level " .. level
    UIDropDownMenu_SetText(XPMonFrameSelectLevel, XPMonFrameSelectLevel.selectedName)
    XPMonTitleTextLevel:SetText(level)
end

function XPMonDetails:initLevelSelect(frame)
    local levels = {}
    for level, info in pairs(XPMon_DATA) do
        table.insert(levels, level)
    end
    table.sort(levels, function (a, b) return a > b end)
    for i, level in pairs(levels) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Level " .. level
        info.value = level
        info.func = function (...)
            self:onLevelSelect(...)
        end
        UIDropDownMenu_AddButton(info)
    end
end

function XPMonDetails:onLevelSelect(frame, arg1, arg2, checked)
    if (not checked) then
        UIDropDownMenu_SetSelectedValue(UIDROPDOWNMENU_OPEN_MENU, frame.value)
    end
    XPMonDetails:showLevelInformation(frame.value)
end

function XPMonDetails:onShow(frame)
    XPMon:log("Showing details frame")
    self:showLevelInformation(XPMon.currentLevel)
end

function XPMonDetails:onTabClick(frame, tab)
    if frame.selectedTab then
        _G["XPMonFrameTabContent" .. frame.selectedTab]:Hide()
    end
    _G["XPMonFrameTabContent" .. tab]:Show()
    PanelTemplates_SetTab(frame, tab)
end