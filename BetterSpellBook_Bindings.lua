local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UPDATE_BINDINGS")
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")

local spellbookOpener;


-- Function to set the keybind for the spellbook opener button
function SetKeybindForSpellBook()
    --Do it after a timer because the keybinds are not loaded yet
    local keyBindForSpellBook = GetBindingKey("TOGGLESPELLBOOK")
    if keyBindForSpellBook then
        SetBindingClick(keyBindForSpellBook, spellbookOpener:GetName(), "LeftButton")
    end
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        spellbookOpener = CreateFrame("Button", "SpellbookOpener", UIParent,
            "SecureHandlerClickTemplate")

        -- Setting the onclick of that shortcut to open the BetterSpellBookFrame
        spellbookOpener:SetScript("OnClick", function(self, button, down)
            BetterSpellBookFrameMixin:ToggleBetterSpellBook()
        end)

        SetKeybindForSpellBook()
    elseif event == "UPDATE_BINDINGS" and spellbookOpener then
        SetKeybindForSpellBook()
    end
end)
