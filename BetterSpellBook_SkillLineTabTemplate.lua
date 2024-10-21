local addonName, BetterSpellBook = ...

BetterSpellBookSkillLineTabMixin = {}

function BetterSpellBookSkillLineTabMixin:OnLoad()
    -- Nothing
end

function BetterSpellBookSkillLineTabMixin:GetBetterSpellBookFrameMixin()
    -- Try to GetParent until BetterSpellBookFrameMixin
    return self:GetParent():GetParent():GetParent()
end

function BetterSpellBookSkillLineTabMixin:GetSpellBookTabFrame()
    -- Try to GetParent until BetterSpellBookFrameMixin
    return self:GetParent():GetParent()
end

function BetterSpellBookSkillLineTabMixin:OnUpdate()
    -- Highlight the tab if it's the currently selected skill line
    if self:GetSpellBookTabFrame().currentSkillLine == self.skillLine then
        self:SetChecked(true)
    else
        self:SetChecked(false)
    end

    -- Set the tab's desaturation based on whether the tab is offspec
    if self.isOffSpec then
        self:GetNormalTexture():SetDesaturated(true)
    else
        self:GetNormalTexture():SetDesaturated(false)
    end

    
    -- Hide the tab if it's not associated with a skill line
    if self.skillLine == nil then
        self:Hide()
    -- Show the tab if it's associated with a skill line    
    else
        self:Show()
    end
end

function BetterSpellBookSkillLineTabMixin:OnClick()
    if self.isCustomButton then
        self.onClick()
        self:SetChecked(false)
        return
    end

    -- Switch to the skill line associated with this tab
    self:GetSpellBookTabFrame():SwitchSkillLine(self.skillLine)

    -- Play the tab switch sound
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)

    -- Update all skillline buttons
    self:GetSpellBookTabFrame():UpdateSkillLineButtons()
end

function BetterSpellBookSkillLineTabMixin:OnEnter()
    -- Show the tooltip when hovering over the button
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltip or "Skill Line")
    GameTooltip:Show()
end

function BetterSpellBookSkillLineTabMixin:OnLeave()
    -- Hide the tooltip when leaving the button
    GameTooltip:Hide()
end

function BetterSpellBookSkillLineTabMixin:Setup(skillLineInfo, skillLineIndex)
    -- Set the texture and tooltip for the tab
    if(skillLineInfo.iconID == nil) then
        return
    end
    self:SetNormalTexture(skillLineInfo.iconID)
    self.tooltip = skillLineInfo.name
    self.skillLine = skillLineIndex
    self.isOffSpec = skillLineInfo.offSpecID ~= nil
    self:OnUpdate()
end

-- Setup fucntion but for external buttons
function BetterSpellBookSkillLineTabMixin:SetupExternal(iconID, name, skillLineIndex, onClick)
    self:SetNormalTexture(iconID)
    self.tooltip = name
    self.skillLine = skillLineIndex
    self.isOffSpec = false
    self.onClick = onClick
    self.isCustomButton = true
    self:OnUpdate()
end