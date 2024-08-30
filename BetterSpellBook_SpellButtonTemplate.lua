local addonName, BetterSpellBook = ...

local SpellTable = BetterSpellBook.SpellTable

BetterSpellButtonMixin = {}

function BetterSpellButtonMixin:SpellBookTabFrame()
    return self:GetParent():GetParent()
end

function BetterSpellButtonMixin:GetBetterSpellBookFrameMixin()
    -- Try to GetParent until BetterSpellBookFrameMixin
    return self:GetParent():GetParent():GetParent()
end

function BetterSpellButtonMixin:OnLoad()
    -- Register events
    self:RegisterEvent("SPELL_UPDATE_COOLDOWN")

    -- Register the button for drag events
    self:RegisterForDrag("LeftButton")
end

function BetterSpellButtonMixin:OnEvent(event, ...)
    if event == "SPELL_UPDATE_COOLDOWN" then
        self:UpdateCooldown()
    end
end

function BetterSpellButtonMixin:OnEnter()
    -- Show tooltip or do something on hover
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
    GameTooltip:Show()

    -- Activate the shine texture
    self.SlotFrameShine:Show()
end

function BetterSpellButtonMixin:OnLeave()
    -- Hide tooltip
    GameTooltip:Hide()

    -- Deactivate the shine texture
    self.SlotFrameShine:Hide()
end



function BetterSpellButtonMixin:OnDrag()
    if self.isPetSpell then
        C_SpellBook.PickupSpellBookItem(self.spellInfo.newSpellBookIndex, Enum.SpellBookSpellBank.Pet)
    else
        C_SpellBook.PickupSpellBookItem(self.spellInfo.newSpellBookIndex, Enum.SpellBookSpellBank.Player)
    end
end

function BetterSpellButtonMixin:GetFunctionalSpellID(spellID)
    -- Perform a bitwise AND operation with the mask 0xFFFFFF to keep the lower 24 bits
    return bit.band(spellID, 0xFFFFFF)
end

function BetterSpellButtonMixin:UpdateSpellInfo(spellInfo, isPetSpell)
    if not spellInfo then
        return self:Hide()
    end

    -- Update the button's icon and name based on the spell info
    self.SpellName:SetText(spellInfo.name)
    self.IconTexture:SetTexture(spellInfo.icon)

    -- Set the spell ID on attribute so it can be accessed later
    if isPetSpell and not spellInfo.isPetAction then
        self.spellID = self:GetFunctionalSpellID(spellInfo.spellID)
    else
        self.spellID = spellInfo.spellID
    end
    self.spellInfo = spellInfo
    self.isPetSpell = isPetSpell

    -- Display the spell type (e.g., Passive or Flyout)
    if spellInfo.isPassive then
        self.SubSpellName:SetText(SPELL_PASSIVE)
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", spellInfo.spellID)
    elseif spellInfo.spellType == Enum.SpellBookItemType.Flyout then
        self.SubSpellName:SetText("")
        self:SetAttribute("type", "flyout")
        self:SetAttribute("spell", spellInfo.spellID)
    else
        self.SubSpellName:SetText("")
        self:SetAttribute("type", "spell")
        self:SetAttribute("spell", spellInfo.spellID)
    end

    -- Update the cooldown display for the spell button
    self:UpdateCooldown()

    -- Update all the spell button visuals
    self:UpdateSpellButtonVisuals(spellInfo)

    -- Show the button
    self:Show()
end

function BetterSpellButtonMixin:UpdateCooldown()
    if not self.spellID then
        return
    end
    -- Update the cooldown display for the spell button
    local spellCooldownInfo = C_Spell.GetSpellCooldown(self.spellID)
    if spellCooldownInfo then
        self.Cooldown:SetCooldown(spellCooldownInfo.startTime, spellCooldownInfo.duration);
    end
end

function BetterSpellButtonMixin:UpdateSpellButtonVisuals(spellInfo)
    -- Desaturate the icon if the spell is not known
    if spellInfo.isKnown then
        self.IconTexture:SetDesaturated(false)
        self.SlotFrame:Show()
        self.SlotFrameInactive:Hide()
        self.SpellName:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
        self.SubSpellName:SetTextColor(PARCHMENT_MATERIAL_TEXT_COLOR.r, PARCHMENT_MATERIAL_TEXT_COLOR.g,
            PARCHMENT_MATERIAL_TEXT_COLOR.b)
    else
        self.IconTexture:SetDesaturated(true)
        self.SlotFrame:Hide()
        self.SlotFrameInactive:Show()
        self.SpellName:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
        self.SubSpellName:SetTextColor(VERY_DARK_GRAY_COLOR.r, VERY_DARK_GRAY_COLOR.g, VERY_DARK_GRAY_COLOR.b)
    end

    -- Show or hide the flyout arrow
    if spellInfo.spellType == Enum.SpellBookItemType.Flyout then
        self.FlyoutArrow:Show()
    else
        self.FlyoutArrow:Hide()
    end
end