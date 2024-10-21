local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local secureSpellbookOpener = CreateFrame("Button", "SecureSpellbookOpener", UIParent,
            "SecureHandlerClickTemplate")
        -- Assume 'MyCustomSpellbookFrame' is your spellbook frame
        secureSpellbookOpener:SetFrameRef("BetterSpellBookFrameMixin", BetterSpellBookFrameTemplate)
        local ok = SetBindingClick("P", secureSpellbookOpener:GetName(), "LeftButton")
        secureSpellbookOpener:SetScript("OnClick", function(self, button, down)
            BetterSpellBookFrameMixin:ToggleBetterSpellBook()
        end)
        SetBindingClick("P", secureSpellbookOpener:GetName(), "LeftButton")
        print("Binding set: P")
    end
end)
