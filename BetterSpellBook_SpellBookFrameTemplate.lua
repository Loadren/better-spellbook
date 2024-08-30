local addonName, BetterSpellBook = ...
local SpellTable = BetterSpellBook.SpellTable

-- Global declarations for keybinds
BINDING_HEADER_BETTER_SPELLBOOK = "Better Spellbook"
BINDING_NAME_BETTER_SPELLBOOK_SHOW_SPELLBOOK = "Show Spellbook"

-- Define the Mixin tables
BetterSpellBookFrameMixin = {}
BetterSpellBookPrevPageButtonMixin = {}
BetterSpellBookNextPageButtonMixin = {}
NonPassiveCheckMixin = {}

-- Define the events that should be registered
local SpellBookEvents = { "ADDON_LOADED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_SPECIALIZATION_CHANGED",
    "PET_BAR_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }

-- OnLoad script for the spellbook frame
function BetterSpellBookFrameMixin:OnLoad()
    self:SetTitle(SPELLBOOK)
    UIPanelWindows["BetterSpellBookFrameTemplate"] = {
        area = "right",
        pushable = 1,
        whileDead = 1,
    }

    -- Better access on other files
    BetterSpellBook.BetterSpellBookFrameMixin = self

    -- Register loaded event
    FrameUtil.RegisterFrameForEvents(self, SpellBookEvents);
    self:RegisterForDrag("LeftButton");

    -- Add the tab for player
    TabSystemOwnerMixin.OnLoad(self);
    self:SetTabSystem(self.CategoryTabSystem);
    self.playerTab = self:AddNamedTab(SPELLBOOK, self.PlayerSpellBook);

    -- Set the default tab
    self:SetTab(self.playerTab);

    -- Initialize the spell buttons for the first page when BetterSpellBook.UpdateSpells is triggered
    EventRegistry:RegisterCallback("BetterSpellBook.UpdateSpells", function()
        self:UpdateTabButtons()
    end)

    self:UpdatePortrait();
end

function BetterSpellBookFrameMixin:UpdatePortrait()
    local specID = self:GetSpecID();
    local specIcon = specID and PlayerUtil.GetSpecIconBySpecID(specID, "player") or nil;
    if specIcon then
        self:SetPortraitTexCoord(0, 1, 0, 1);
        self:SetPortraitToAsset(specIcon);
    else
        local classID = self:GetClassID();
        self:SetPortraitToClassIcon(C_CreatureInfo.GetClassInfo(classID).classFile);
    end
end

function BetterSpellBookFrameMixin:GetSpecID()
    return PlayerUtil.GetCurrentSpecID();
end

function BetterSpellBookFrameMixin:GetClassID()
    return PlayerUtil.GetClassID();
end

-- Add the player/pet tabs if player has pet
function BetterSpellBookFrameMixin:UpdateTabButtons()
    if #SpellTable.spells["Pet"] ~= 0 and not self.petTab then
        local _, petNameToken = C_SpellBook.HasPetSpells()
        self.petTab = self:AddNamedTab(_G["PET_TYPE_" .. petNameToken], self.PetSpellBook);
    elseif #SpellTable.spells["Pet"] == 0 and self.petTab then
        self:GetTabButton(2):Hide()
    elseif self.petTab then
        self:GetTabButton(2):Show()
    end
end

function BetterSpellBookFrameMixin:SetTab(tabID)
    TabSystemOwnerMixin.SetTab(self, tabID);
end

function BetterSpellBookFrameMixin:EnteringCombat()
    self.wasShown = self:IsShown();
    if self.wasShown then
        print("Entering combat, hiding spellbook.")
        self:Hide();
    end
end

function BetterSpellBookFrameMixin:LeavingCombat()
    if self.wasShown then
        self:Show();
    end
end

-- OnEvent script for the spellbook frame
function BetterSpellBookFrameMixin:OnEvent(event, addOnName)
    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PET_BAR_UPDATE" then
        SpellTable:HandlePopulatePlayerSpellsWithCooldown()
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePortrait();
    end
    -- If spellbook is open, open instead better spellbook
    if addOnName == "Blizzard_PlayerSpells" and event == "ADDON_LOADED" then
        PlayerSpellsFrame.SpellBookFrame:HookScript("OnShow", function()
            if not InCombatLockdown() then
                HideUIPanel(PlayerSpellsFrame)

                -- Show the better spellbook
                self:ToggleBetterSpellBook()
            end
        end)
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:EnteringCombat();
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:LeavingCombat();
    end
end

function BetterSpellBookFrameMixin:OnShow()
    EventRegistry:TriggerEvent("BetterSpellBookFrame.Show");
end

function BetterSpellBookFrameMixin:OnHide()
    EventRegistry:TriggerEvent("BetterSpellBookFrame.Hide");
end

-- ToggleBetterSpellBook function to show/hide the spellbook frame
function BetterSpellBookFrameMixin:ToggleBetterSpellBook()
    -- show all property names of BetterSpellBookFrameTemplate
    if self:IsShown() then
        HideUIPanel(self)
    else
        ShowUIPanel(self)
    end
end

-- Button mixin for BetterSpellBookPrevPageButton
function BetterSpellBookPrevPageButtonMixin:OnClick()
    local parentFrame = self:GetParent():GetParent() -- Get grandparent frame
    if parentFrame and parentFrame.PreviousPage then
        parentFrame:PreviousPage()
    end
end

-- Button mixin for BetterSpellBookNextPageButton
function BetterSpellBookNextPageButtonMixin:OnClick()
    local parentFrame = self:GetParent():GetParent() -- Get grandparent frame
    if parentFrame and parentFrame.NextPage then
        parentFrame:NextPage()
    end
end

_G["BetterSpellBookFrameMixin"] = BetterSpellBookFrameMixin
