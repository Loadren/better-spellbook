local addonName, BetterSpellBook = ...
local SpellTable = BetterSpellBook.SpellTable

BetterPlayerSpellBookMixin = {}

-- OnLoad script for the spellbook frame
function BetterPlayerSpellBookMixin:OnLoad()
    self.currentPage = 1      -- Default to page 1
    self.currentSkillLine = 1 -- Default to the first skill line
    self.spellsPerPage = 12   -- Number of spells per page

    -- Initialize the page text
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)

    -- And the page buttons
    self.Navigation.prevPageButton:Disable()

    -- Initialize the spell buttons for the first page when BetterSpellBook.UpdateSpells is triggered
    EventRegistry:RegisterCallback("BetterSpellBook.UpdateSpells", function()
        self:LoadSkillLineTabs()
        self:UpdateSpellButtons()
    end)

    -- Set the non passive button callback
    self.HidePassivesCheckButton:SetCallback(function()
        self:UpdateSpellButtons()
    end)

    -- Set the scroll events to move the page left and right
    self:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:PreviousPage()
        else
            self:NextPage()
        end
    end)

    print("BetterPlayerSpellBookMixin Loaded")
end

-- Get Spell List
function BetterPlayerSpellBookMixin:GetSpellList()
    if self.HidePassivesCheckButton:IsControlChecked() then
        return BetterSpellBook.Utils.FilterNonPassiveSpells(SpellTable.spells["Player"][self.currentSkillLine])
    else
        return SpellTable.spells["Player"][self.currentSkillLine]
    end
end

-- Set the disabled state for the page buttons based on the current page
function BetterPlayerSpellBookMixin:UpdatePageButtons()
    local maxPages = math.ceil(#self:GetSpellList() / self.spellsPerPage)

    if self.currentPage == 1 then
        self.Navigation.prevPageButton:Disable()
    else
        self.Navigation.prevPageButton:Enable()
    end

    if self.currentPage == maxPages then
        self.Navigation.nextPageButton:Disable()
    else
        self.Navigation.nextPageButton:Enable()
    end
end

function BetterPlayerSpellBookMixin:SwitchSkillLine(skillLine)
    if skillLine then
        self.currentSkillLine = skillLine
        self.currentPage = 1
        self:UpdateSpellButtons()
    end
end

-- Go to next page in the spellbook
function BetterPlayerSpellBookMixin:NextPage()
    local maxPages = math.ceil(#self:GetSpellList() / self.spellsPerPage)

    if self.currentPage < maxPages then
        self.currentPage = self.currentPage + 1
        self:UpdateSpellButtons()
    end
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
end

-- Go to previous page in the spellbook
function BetterPlayerSpellBookMixin:PreviousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:UpdateSpellButtons()
    end
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
end

-- SetPage doesn't need UpdateSpellButtons since it's called inside already, unless we force the reload
function BetterPlayerSpellBookMixin:SetPage(page, forceReload)
    self.currentPage = page
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
    if forceReload then
        self:UpdateSpellButtons()
    end
end

function BetterPlayerSpellBookMixin:UpdateSpellButtons()
    -- Get the spells for the current tab (Player or Pet)
    local spells = self:GetSpellList()

    if self.HidePassivesCheckButton:IsControlChecked() then
        spells = BetterSpellBook.Utils.FilterNonPassiveSpells(spells)
    end

    if #spells / 12 < self.currentPage then
        self:SetPage(ceil(#spells / 12))
    end

    -- Calculate the first spell index for the current page
    local firstSpellIndex = (self.currentPage - 1) * self.spellsPerPage + 1
    local lastSpellIndex = math.min(firstSpellIndex + self.spellsPerPage - 1, #spells)

    -- Loop over the spell buttons (assuming they are named BetterSpellButton1, BetterSpellButton2, etc.)
    for i = 1, self.spellsPerPage do
        local button = self.SpellButtons["BetterSpellButton" .. i]
        local spellIndex = firstSpellIndex + i - 1

        if spellIndex <= lastSpellIndex then
            local spellInfo = spells[spellIndex]

            if not InCombatLockdown() then
                button.spellID = spellInfo.spellID
                button:UpdateSpellInfo(spellInfo)
                button:Show()
            end
        else
            if not InCombatLockdown() then
                button:Hide() -- Hide buttons that don't have a corresponding spell on this page
            end
        end
    end

    self:UpdatePageButtons()
end

-- Load the skillLine tab buttons for the spellbook frame
-- Load button textures
function BetterPlayerSpellBookMixin:LoadSkillLineTabs()
    local numSkillLines = C_SpellBook.GetNumSpellBookSkillLines()
    local lastTab = nil

    -- Hide all tabs
    for i = 1, 8 do
        local tabButton = self.SkillLine["BetterSpellBookSkillLineTab" .. i]
        tabButton:Hide()
    end

    -- Loop over the tab buttons (assuming they are named BetterSpellBookSkillLineTab1, BetterSpellBookSkillLineTab2, etc.)
    for i = 1, numSkillLines do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        if skillLineInfo then
            local tabButton = self.SkillLine["BetterSpellBookSkillLineTab" .. i]
            tabButton:Setup(skillLineInfo, i)
        end
    end

    -- If parent variable Clique is true, we need to create a button for it
    if BetterSpellBook.isCliqueLoaded then
        local tabButton = self.SkillLine["BetterSpellBookSkillLineTab" .. (numSkillLines + 2)]
        tabButton:SetupExternal("Interface\\AddOns\\Clique\\images\\icon_square_64", "Clique", numSkillLines + 2, function()
            if _G.Clique then
                _G.Clique:ShowBindingConfig()
            end
        end)
    end
        
end

-- Update all tab buttons
function BetterPlayerSpellBookMixin:UpdateSkillLineButtons()
    for i = 1, 8 do
        local tabButton = self.SkillLine["BetterSpellBookSkillLineTab" .. i]
        tabButton:OnUpdate()
    end

    -- This is called when the skill line is switched so we can update the artwork
    self:UpdateSkillLineArtwork()
end

-- Update the spellbook artworks based on if the current skilline is offspec
function BetterPlayerSpellBookMixin:UpdateSkillLineArtwork()
    local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(self.currentSkillLine)
    if skillLineInfo then
        if skillLineInfo.offSpecID then
            self.BookBG:SetDesaturated(true)
            self.Bookmark:SetDesaturated(true)
        else
            self.BookBG:SetDesaturated(false)
            self.Bookmark:SetDesaturated(false)
        end
    end
end
