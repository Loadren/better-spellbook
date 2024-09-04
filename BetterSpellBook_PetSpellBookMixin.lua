local addonName, BetterSpellBook = ...
local SpellTable = BetterSpellBook.SpellTable

BetterPetSpellBookMixin = {}

-- OnLoad script for the spellbook frame
function BetterPetSpellBookMixin:OnLoad()
    self.currentPage = 1      -- Default to page 1
    self.currentSkillLine = 1 -- Default to the first skill line
    self.spellsPerPage = 12   -- Number of spells per page

    -- Initialize the page text
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)

    -- And the page buttons
    self.Navigation.prevPageButton:Disable()

    -- Initialize the spell buttons for the first page when BetterSpellBook.UpdateSpells is triggered
    EventRegistry:RegisterCallback("BetterSpellBook.UpdateSpells", function()
        if #SpellTable.spells["Pet"] == 0 then
            return self:GetParent():SetTab(self:GetParent().playerTab);
        end
        self:UpdateSpellButtons()
    end)

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
end

-- Get Spell List
function BetterPetSpellBookMixin:GetSpellList()
    if #SpellTable.spells["Pet"] == 0 then
        return nil
    end
    if self.HidePassivesCheckButton:IsControlChecked() then
        return BetterSpellBook.Utils.FilterNonPassiveSpells(SpellTable.spells["Pet"][self.currentSkillLine])
    else
        return SpellTable.spells["Pet"][self.currentSkillLine]
    end
end

-- Set the disabled state for the page buttons based on the current page
function BetterPetSpellBookMixin:UpdatePageButtons()
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

-- Go to next page in the spellbook
function BetterPetSpellBookMixin:NextPage()
    local maxPages = math.ceil(#self:GetSpellList() / self.spellsPerPage)

    if self.currentPage < maxPages then
        self.currentPage = self.currentPage + 1
        self:UpdateSpellButtons()
    end
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
end

-- Go to previous page in the spellbook
function BetterPetSpellBookMixin:PreviousPage()
    if self.currentPage > 1 then
        self.currentPage = self.currentPage - 1
        self:UpdateSpellButtons()
    end
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
end

-- SetPage doesn't need UpdateSpellButtons since it's called inside already
function BetterPetSpellBookMixin:SetPage(page)
    self.currentPage = page
    self.Navigation.pageText:SetFormattedText(PAGE_NUMBER, self.currentPage)
end

function BetterPetSpellBookMixin:UpdateSpellButtons()
    -- Get the spells for the current tab (Player or Pet)
    local spells = self:GetSpellList()

    if not spells then
        return
    end

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

            button.spellID = spellInfo.spellID
            button:UpdateSpellInfo(spellInfo, true)
            button:Show()
        else
            button:Hide() -- Hide buttons that don't have a corresponding spell on this page
        end
    end

    self:UpdatePageButtons()
end
