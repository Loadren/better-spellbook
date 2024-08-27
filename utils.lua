local addonName, BetterSpellBook = ...
BetterSpellBook.Utils = {}

-- A mapping of accented/special characters to their base equivalents (lowercase and uppercase).
BetterSpellBook.Utils.accentsMap = {
    -- Lowercase Latin-based characters
    ["á"] = "a", ["à"] = "a", ["ä"] = "a", ["â"] = "a", ["ã"] = "a", ["å"] = "a", ["æ"] = "ae",
    ["ç"] = "c", ["ć"] = "c", ["č"] = "c",
    ["é"] = "e", ["è"] = "e", ["ë"] = "e", ["ê"] = "e", ["ė"] = "e", ["ę"] = "e",
    ["í"] = "i", ["ì"] = "i", ["ï"] = "i", ["î"] = "i",
    ["ñ"] = "n", ["ń"] = "n",
    ["ó"] = "o", ["ò"] = "o", ["ö"] = "o", ["ô"] = "o", ["õ"] = "o", ["ø"] = "o", ["œ"] = "oe",
    ["ú"] = "u", ["ù"] = "u", ["ü"] = "u", ["û"] = "u", ["ų"] = "u",
    ["ý"] = "y", ["ÿ"] = "y",
    ["š"] = "s", ["ś"] = "s",
    ["ž"] = "z", ["ź"] = "z", ["ż"] = "z",
    
    -- Uppercase Latin-based characters
    ["Á"] = "A", ["À"] = "A", ["Ä"] = "A", ["Â"] = "A", ["Ã"] = "A", ["Å"] = "A", ["Æ"] = "AE",
    ["Ç"] = "C", ["Ć"] = "C", ["Č"] = "C",
    ["É"] = "E", ["È"] = "E", ["Ë"] = "E", ["Ê"] = "E", ["Ė"] = "E", ["Ę"] = "E",
    ["Í"] = "I", ["Ì"] = "I", ["Ï"] = "I", ["Î"] = "I",
    ["Ñ"] = "N", ["Ń"] = "N",
    ["Ó"] = "O", ["Ò"] = "O", ["Ö"] = "O", ["Ô"] = "O", ["Õ"] = "O", ["Ø"] = "O", ["Œ"] = "OE",
    ["Ú"] = "U", ["Ù"] = "U", ["Ü"] = "U", ["Û"] = "U", ["Ų"] = "U",
    ["Ý"] = "Y", ["Ÿ"] = "Y",
    ["Š"] = "S", ["Ś"] = "S",
    ["Ž"] = "Z", ["Ź"] = "Z", ["Ż"] = "Z",

    -- Germanic ligatures
    ["ß"] = "ss", ["ẞ"] = "SS",

    -- Punctuation replacements
    ["‘"] = "'", ["’"] = "'", ["“"] = '"', ["”"] = '"', ["–"] = "-", ["—"] = "-",
    
    -- Other special characters or symbols that may appear
    ["©"] = "(c)", ["®"] = "(r)", ["™"] = "tm", ["€"] = "euro", ["£"] = "pound", ["¥"] = "yen",
}

-- Normalize accented characters by replacing them with their base form.
BetterSpellBook.Utils.NormalizeString = function(str)
    return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", BetterSpellBook.Utils.accentsMap))
end

-- Function to normalize and convert string to lowercase for safe comparison.
BetterSpellBook.Utils.NormalizeForComparison = function(str)
    return BetterSpellBook.Utils.NormalizeString(str):lower()
end

-- Sorting by name, ignoring case and accents.
BetterSpellBook.Utils.SortSpellsByName = function(spells)
    table.sort(spells, function(a, b)
        return BetterSpellBook.Utils.NormalizeForComparison(a.name) < BetterSpellBook.Utils.NormalizeForComparison(b.name)
    end)
end

BetterSpellBook.Utils.SortSpellsByKnownActivePassiveAndName = function(spells)
    table.sort(spells, function(a, b)
        -- First, sort by known status (true known spells first)
        if a.isKnown ~= b.isKnown then
            return a.isKnown
        end

        -- Then, sort by active/passive status (active spells before passive)
        if a.isPassive ~= b.isPassive then
            return not a.isPassive  -- Passive should be false for active spells to come first
        end

        -- Finally, sort alphabetically by name, ignoring case and accents
        return BetterSpellBook.Utils.NormalizeForComparison(a.name) < BetterSpellBook.Utils.NormalizeForComparison(b.name)
    end)
end

-- Function to filter passive spells
BetterSpellBook.Utils.FilterNonPassiveSpells = function(spellList)
    local filteredTable = {}

    if not spellList then
        return filteredTable
    end
    
    for i, spellData in ipairs(spellList) do
        if not spellData.isPassive then
            table.insert(filteredTable, spellData)  -- Only insert if not passive
        end
    end

    return filteredTable
end
