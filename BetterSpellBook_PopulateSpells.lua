local addonName, BetterSpellBook = ...

BetterSpellBook.SpellTable = {}

local SpellTable = BetterSpellBook.SpellTable
local Utils = BetterSpellBook.Utils

-- Variables for managing cooldown and pending calls
SpellTable.isOnCooldown = false
SpellTable.callWhenCooldownEnds = false

-- Function to find the position of a spell in the spellbook
function SpellTable:FindSpellPosition(spellID)
    -- Iterate through all skill lines (Player's spellbook)
    for skillLineIndex, skillLineSpells in pairs(SpellTable.spells["Player"]) do
        -- Iterate over each spell in the skill line
        for spellIndex, spellData in ipairs(skillLineSpells) do
            -- Compare the spellID to find the correct spell
            if spellData.spellID == spellID then
                -- Return the position in terms of skill line, tab, and index
                return Enum.SpellBookSpellBank.Player, skillLineIndex, spellIndex
            end
        end
    end

    -- Iterate through pet spells if needed
    if SpellTable.spells["Pet"] then
        for skillLineIndex, petSpells in pairs(SpellTable.spells["Pet"]) do
            for spellIndex, spellData in ipairs(petSpells) do
                if spellData.spellID == spellID then
                    return Enum.SpellBookSpellBank.Pet, skillLineIndex, spellIndex
                end
            end
        end
    end

    -- Return nil if the spell is not found
    return nil, nil
end

function SpellTable:GetSpellData(spellID)
    for _, skillLine in pairs(SpellTable.spells["Player"]) do
        for _, spell in pairs(skillLine) do
            if spell.spellID == spellID then
                return spell
            end
        end
    end

    for _, spell in pairs(SpellTable.spells["Pet"][1]) do
        if spell.spellID == spellID then
            return spell
        end
    end

    return nil
end

-- Function to populate the player's spell table and sort spells by type and name
function SpellTable:PopulateSpells()
    -- Clear the table before populating
    if SpellTable.spells then
        table.wipe(SpellTable.spells)
    end

    SpellTable.spells = {
        Player = {},
        Pet = {}
    }

    -- Iterate through all skill lines
    for i = 1, C_SpellBook.GetNumSpellBookSkillLines() do
        local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(i)

        -- Combined table for both active and passive spells
        local combinedSpells = {}

        local offset, numSlots = skillLineInfo.itemIndexOffset, skillLineInfo.numSpellBookItems

        -- Iterate over each spell in the skill line
        for j = offset + 1, offset + numSlots do
            -- Get the spell name and info
            local name = C_SpellBook.GetSpellBookItemName(j, Enum.SpellBookSpellBank.Player)
            local spellInfo = C_SpellBook.GetSpellBookItemInfo(j, Enum.SpellBookSpellBank.Player)
            local _, flyoutID = C_SpellBook.GetSpellBookItemType(j, Enum.SpellBookSpellBank.Player)
            local flyoutInfo = {};
            if spellInfo.itemType == Enum.SpellBookItemType.Flyout then
                flyoutInfo.name, flyoutInfo.description, flyoutInfo.numSlots, flyoutInfo.isKnown = GetFlyoutInfo(
                    flyoutID)
            end

            -- Only store the spell if it has a valid action ID (i.e., it's not empty)
            if name and spellInfo and spellInfo.actionID then
                local spellID = flyoutID or spellInfo.spellID or spellInfo
                    .actionID -- Because sometimes it's on actionID

                local isKnown = IsSpellKnownOrOverridesKnown(spellID, false) or flyoutInfo.isKnown

                local spellData = {
                    newSpellBookIndex = j,
                    spellID = spellID,
                    name = name,
                    isPassive = spellInfo.isPassive,
                    isKnown = (not spellInfo.isOffSpec) and isKnown,
                    isOffSpec = spellInfo.isOffSpec,
                    icon = spellInfo.iconID,
                    spellType = spellInfo.itemType,
                    hasAttachedGlyph = HasAttachedGlyph(spellID),
                }

                -- Add to the combined spell table (both active and passive)
                table.insert(combinedSpells, spellData)
            end
        end

        -- Sort the combined spells by known status, active/passive status, and name
        Utils.SortSpellsByKnownActivePassiveAndName(combinedSpells)

        -- Store the sorted spells in the Player's spell table
        SpellTable.spells["Player"][i] = combinedSpells
    end

    -- Pet Spells
    if (not C_SpellBook.HasPetSpells()) then
        return EventRegistry:TriggerEvent("BetterSpellBook.UpdateSpells")
    end

    -- Combined table for both active and passive pet spells
    local combinedSpells = {}

    local numSpells, petToken = C_SpellBook.HasPetSpells() -- nil if pet does not have spellbook, 'petToken' will usually be "PET"
    for i = 1, numSpells do
        local petSpellName, petSubType = C_SpellBook.GetSpellBookItemName(i, Enum.SpellBookSpellBank.Pet)
        local spellInfo = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Pet)
        local _, petActionID = C_SpellBook.GetSpellBookItemType(i, Enum.SpellBookSpellBank.Pet)

        -- Get Autocast State  for Pet Spells with Bit 1073741824
        local autoCastState = bit.band(petActionID, 1073741824) == 1073741824

        -- Only store the spell if it has a valid action ID (i.e., it's not empty)
        if petSpellName and spellInfo and spellInfo.actionID then
            local spellID = petActionID or spellInfo.spellID or spellInfo.actionID -- Because sometimes it's on actionID

            -- Perform a bitwise AND operation with the mask 0xFFFFFF (16,777,215 in decimal) if spell is known
            spellID = bit.band(spellID, 0xFFFFFF)

            local spellData = {
                newSpellBookIndex = i,
                spellID = spellID,
                name = petSpellName,
                isPassive = spellInfo.isPassive,
                isKnown = true,
                isOffSpec = spellInfo.isOffSpec,
                icon = spellInfo.iconID,
                spellType = spellInfo.itemType,
                isPetAction = not not petActionID,
                autoCastState = autoCastState
            }

            -- Add to the combined spell table (both active and passive)
            table.insert(combinedSpells, spellData)
        end
    end

    -- Sort the combined pet spells by known status, active/passive status, and name
    Utils.SortSpellsByKnownActivePassiveAndName(combinedSpells)

    -- Store the sorted pet spells in the Pet's spell table
    SpellTable.spells["Pet"][1] = combinedSpells


    EventRegistry:TriggerEvent("BetterSpellBook.UpdateSpells")
end

-- Helper function to handle PopulatePlayerSpells with cooldown
function SpellTable:HandlePopulatePlayerSpellsWithCooldown()
    if SpellTable.isOnCooldown then
        -- If the function is on cooldown, set a flag to call it after cooldown
        SpellTable.callWhenCooldownEnds = true
    else
        -- Call PopulatePlayerSpells and start the cooldown timer
        SpellTable:PopulateSpells()
        SpellTable.isOnCooldown = true

        -- Start a 5-second cooldown timer
        C_Timer.After(5, function()
            SpellTable.isOnCooldown = false
            -- Check if a call was requested during the cooldown
            if SpellTable.callWhenCooldownEnds then
                SpellTable.callWhenCooldownEnds = false
                SpellTable:PopulateSpells()
            end
        end)
    end
end

_G["SpellTable"] = SpellTable
