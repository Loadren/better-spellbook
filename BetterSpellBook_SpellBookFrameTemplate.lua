local addonName, BetterSpellBook = ...
local SpellTable = BetterSpellBook.SpellTable

-- Define the Mixin tables
BetterSpellBookFrameMixin = {}
BetterSpellBookPrevPageButtonMixin = {}
BetterSpellBookNextPageButtonMixin = {}
NonPassiveCheckMixin = {}

-- Define the events that should be registered
local SpellBookEvents = { "ADDON_LOADED", "SPELLS_CHANGED", "LEARNED_SPELL_IN_TAB", "PLAYER_SPECIALIZATION_CHANGED",
    "PET_BAR_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "USE_GLYPH", "CANCEL_GLYPH_CAST", "ACTIVATE_GLYPH" }

-- OnLoad script for the spellbook frame
function BetterSpellBookFrameMixin:OnLoad()
    self:SetTitle(SPELLBOOK)
    UIPanelWindows["BetterSpellBookFrameTemplate"] = {
        area = "right",
        pushable = 1,
        whileDead = 1,
    }

    -- Register loaded event
    FrameUtil.RegisterFrameForEvents(self, SpellBookEvents);
    self:RegisterForDrag("LeftButton");

    -- Add the tab for player
    TabSystemOwnerMixin.OnLoad(self);
    self:SetTabSystem(self.CategoryTabSystem);
    self.playerTab = self:AddNamedTab(SPELLBOOK, self.PlayerSpellBook);

    -- Set the default tab
    self:SetTab(self.playerTab);

    -- Add a table for glyphs
    self.spellsTargetedByGlyphs = {}

    -- Add a variable for custom onshow since Blizzard's OnShow is called twice sometimes
    self.OnShowBlizzardEventTriggered = false;

    -- And add a variable for when the Blizzard spellbook hides the frame, so we can differentiate player interaction and UI interaction
    self.wasShownPriorToBlizzardUIHide = false;

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
    self.wasShownPriorToCombat = self:IsShown();
    if self.wasShownPriorToCombat then
        print("Entering combat, hiding spellbook.")
        self:Hide();
    end
end

function BetterSpellBookFrameMixin:LeavingCombat()
    if self.wasShownPriorToCombat then
        self:Show();
    end
end

-- OnEvent script for the spellbook frame
function BetterSpellBookFrameMixin:OnEvent(event, arg1)
    if event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "PET_BAR_UPDATE" then
        SpellTable:HandlePopulatePlayerSpellsWithCooldown()
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        self:UpdatePortrait();
    end

    --If Clique is loaded, we need to register it in a global variable
    if event == "ADDON_LOADED" and arg1 == "Clique" then
        BetterSpellBook.isCliqueLoaded = true;
    end

    if event == "PLAYER_REGEN_DISABLED" then
        self:EnteringCombat();
    elseif event == "PLAYER_REGEN_ENABLED" then
        self:LeavingCombat();
    end

    -- If we are loaded, we need to check if Clique has been loaded before us
    if event == "ADDON_LOADED" and arg1 == addonName then
        BetterSpellBook.isCliqueLoaded = C_AddOns.IsAddOnLoaded("Clique");
    end

    if event == "USE_GLYPH" then
        self:UseGlyph(arg1)
    end

    if event == "CANCEL_GLYPH_CAST" or event == "ACTIVATE_GLYPH" then
        self:CancelGlyphCast()
    end
end

function BetterSpellBookFrameMixin:CancelGlyphCast()
    for spellID, spellInfo in pairs(self.spellsTargetedByGlyphs) do
        spellInfo.isGlyphActive = false;
    end
    self.spellsTargetedByGlyphs = {}
    self.PlayerSpellBook:UpdateSpellButtons()
    self.PetSpellBook:UpdateSpellButtons()
end

function BetterSpellBookFrameMixin:UseGlyph(spellID)
    local spellInfo = SpellTable:GetSpellData(spellID);
    local spellBookSpellBank, skillLineIndex, spellIndex = SpellTable:FindSpellPosition(spellID)

    if skillLineIndex and spellIndex then
        if not self:IsShown() then
            self:ToggleBetterSpellBook()
        end

        -- Calculate which page the spell is on
        local spellsPerPage = self.spellsPerPage or 12
        local page = math.ceil(spellIndex / spellsPerPage)
        local spellBook = spellBookSpellBank == Enum.SpellBookSpellBank.Player and self.PlayerSpellBook or
            self.PetSpellBook

        -- Switch to the correct tab
        if spellBookSpellBank == Enum.SpellBookSpellBank.Player then
            self:SetTab(self.playerTab);
            spellBook:SwitchSkillLine(skillLineIndex)
            spellBook:UpdateSkillLineButtons()
        else
            self:SetTab(self.petTab);
        end

        spellBook:SetPage(page, true)

        spellInfo.isGlyphActive = true;
        self.spellsTargetedByGlyphs[spellID] = spellInfo;
        spellBook:UpdateSpellButtons()
    end
end

function BetterSpellBookFrameMixin:CreateButton(name, parent)
    local button = CreateFrame("CheckButton", "$parent" .. name, parent, "SpellBookItemTemplate")
    button:SetParentKey(name)
    button:SetSize(180, 60)

    return button
end

-- Function to create the custom spell buttons using SpellBookItemTemplate
function BetterSpellBookFrameMixin:CreateCustomSpellButtons(book)
    -- Button 1
    local button1 = self:CreateButton("BetterSpellButton1", book.SpellButtons)
    button1:SetID(1)
    button1:SetPoint("TOPLEFT", book.SpellButtons, "TOPLEFT", 100, -75)

    -- Button 2
    local button2 = self:CreateButton("BetterSpellButton2", book.SpellButtons)
    button2:SetID(7)
    button2:SetPoint("TOPLEFT", button1, "TOPLEFT", 200, 0)

    -- Button 3
    local button3 = self:CreateButton("BetterSpellButton3", book.SpellButtons)
    button3:SetID(2)
    button3:SetPoint("TOPLEFT", button1, "TOPLEFT", 0, -65)

    -- Button 4
    local button4 = self:CreateButton("BetterSpellButton4", book.SpellButtons)
    button4:SetID(8)
    button4:SetPoint("TOPLEFT", button3, "TOPLEFT", 200, 0)

    -- Button 5
    local button5 = self:CreateButton("BetterSpellButton5", book.SpellButtons)
    button5:SetID(3)
    button5:SetPoint("TOPLEFT", button3, "TOPLEFT", 0, -65)

    -- Button 6
    local button6 = self:CreateButton("BetterSpellButton6", book.SpellButtons)
    button6:SetID(9)
    button6:SetPoint("TOPLEFT", button5, "TOPLEFT", 200, 0)

    -- Button 7
    local button7 = self:CreateButton("BetterSpellButton7", book.SpellButtons)
    button7:SetID(4)
    button7:SetPoint("TOPLEFT", button5, "TOPLEFT", 0, -65)

    -- Button 8
    local button8 = self:CreateButton("BetterSpellButton8", book.SpellButtons)
    button8:SetID(10)
    button8:SetPoint("TOPLEFT", button7, "TOPLEFT", 200, 0)

    -- Button 9
    local button9 = self:CreateButton("BetterSpellButton9", book.SpellButtons)
    button9:SetID(5)
    button9:SetPoint("TOPLEFT", button7, "TOPLEFT", 0, -65)

    -- Button 10
    local button10 = self:CreateButton("BetterSpellButton10", book.SpellButtons)
    button10:SetID(11)
    button10:SetPoint("TOPLEFT", button9, "TOPLEFT", 200, 0)

    -- Button 11
    local button11 = self:CreateButton("BetterSpellButton11", book.SpellButtons)
    button11:SetID(6)
    button11:SetPoint("TOPLEFT", button9, "TOPLEFT", 0, -65)

    -- Button 12
    local button12 = self:CreateButton("BetterSpellButton12", book.SpellButtons)
    button12:SetID(12)
    button12:SetPoint("TOPLEFT", button11, "TOPLEFT", 200, 0)
end

function BetterSpellBookFrameMixin:OnShow()
    EventRegistry:TriggerEvent("BetterSpellBookFrame.Show");
end

function BetterSpellBookFrameMixin:OnHide()
    EventRegistry:TriggerEvent("BetterSpellBookFrame.Hide");
    self.wasShownPriorToBlizzardUIHide = true;

    C_Timer.After(0.1, function()
        self.wasShownPriorToBlizzardUIHide = false;
    end)
end

-- ToggleBetterSpellBook function to show/hide the spellbook frame
function BetterSpellBookFrameMixin:ToggleBetterSpellBook()
    if InCombatLockdown() then
        return;
    end
    if BetterSpellBookFrameTemplate:IsShown() then
        HideUIPanel(BetterSpellBookFrameTemplate)
        PlaySound(SOUNDKIT.IG_SPELLBOOK_CLOSE)
    else
        ShowUIPanel(BetterSpellBookFrameTemplate)
        PlaySound(SOUNDKIT.IG_SPELLBOOK_OPEN)
    end
end

function BetterSpellBookFrameMixin:OnBlizzardSpellBookShow()
    if InCombatLockdown() then
        return;
    end
    if PlayerSpellsFrame:IsShown() then
        HideUIPanel(PlayerSpellsFrame)

        if not self.OnShowBlizzardEventTriggered then
            self.OnShowBlizzardEventTriggered = true;
            self:ToggleBetterSpellBook()

            -- Start a 100ms cooldown timer, meaning we can't show the spellbook twice during this time frame
            -- This is done to prevent the spellbook from showing twice when the player opens the spellbook because of Blizzard's events
            C_Timer.After(0.1, function()
                self.OnShowBlizzardEventTriggered = false;
            end)
        end
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
