XPMonBar = XPMonBar or {}

function XPMonBar:onLoad(addon)
    print('bar')
    addon:RegisterEvent("PLAYER_XP_UPDATE")
end

function XPMonBar:onEvent(addon, event, ...)
    print('event!');
end

function XPMonBar:onShow(addon)
    print('showing...');
    self:render(addon)
end

function XPMonBar:onHide(addon)
    print('hiding...');
end

function XPMonBar:render(addon)
    print('rendering...');
end