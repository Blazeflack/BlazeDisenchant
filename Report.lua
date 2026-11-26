local _, ns = ...
local version = GetBuildInfo()
if ns.IsSecret(version) or type(version) ~= "string" or not version:match("^1%.60%.") then return end

-- After a successful Disenchant, read the loot window and print the
-- materials and their Goldwright value to the chat frame.

local DISENCHANT = 13262
local LOOT_WAIT = 5       -- seconds from cast success to the loot window
local TARGET_WAIT = 10    -- seconds from clicking the item to cast success

local pending, lastUse

local function isDisenchant(spellID)
    if ns.IsSecret(spellID) then return false end
    if spellID == DISENCHANT then return true end
    -- Fallback in case Forever uses its own spell ID for Disenchant.
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(DISENCHANT)
    local cast = spellID and C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
    return name ~= nil and cast == name and not ns.IsSecret(cast)
end

-- The disenchanted item is the bag item clicked while Disenchant was
-- targeting; it is gone by the time the loot window opens.
if C_Container and C_Container.UseContainerItem then
    hooksecurefunc(C_Container, "UseContainerItem", function(bag, slot)
        if ns.IsSecret(bag) or ns.IsSecret(slot) then return end
        local link = C_Container.GetContainerItemLink(bag, slot)
        if link and not ns.IsSecret(link) then lastUse = {link = link, time = GetTime()} end
    end)
end

local function estimate(link)
    local id = tonumber(link:match("item:(%d+)"))
    if not id then return nil end
    local _, _, quality, level, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(link)
    if ns.IsSecret(quality) or ns.IsSecret(level) or ns.IsSecret(classID) then return nil end
    if not quality or not level or not classID then return nil end
    local results = ns.Results(id, quality, level, classID)
    if not results then return nil end
    local _, average = ns.Values(results)
    return average
end

local function report(source)
    local itemType = (Enum.LootSlotType and Enum.LootSlotType.Item) or 1
    local parts, total, missing = {}, 0, false
    for i = 1, GetNumLootItems() do
        local slotType = GetLootSlotType(i)
        local link = GetLootSlotLink(i)
        if not ns.IsSecret(slotType) and slotType == itemType and link and not ns.IsSecret(link) then
            local _, _, quantity = GetLootSlotInfo(i)
            if ns.IsSecret(quantity) or type(quantity) ~= "number" or quantity < 1 then quantity = 1 end
            local id = tonumber(link:match("item:(%d+)"))
            local price = id and ns.Price(id)
            local text = "   " .. quantity .. "x " .. link
            if price then
                total = total + quantity * price
                text = text .. "  " .. ns.Money(quantity * price)
            else
                missing = true
            end
            parts[#parts + 1] = text
        end
    end
    if #parts == 0 then return end

    local chat = DEFAULT_CHAT_FRAME
    chat:AddMessage("|cff8fc7ffBlazeDisenchant|r: " .. (source or "Disenchant"))
    for _, text in ipairs(parts) do chat:AddMessage(text) end
    if total > 0 then
        local line = "   |cff8fc7ffTotal|r  " .. ns.Money(total) .. (missing and " (some unpriced)" or "")
        local average = source and estimate(source)
        if average then line = line .. "  |cff8fc7ff(est. " .. ns.Money(average) .. ")|r" end
        chat:AddMessage(line)
    end
end

local frame = CreateFrame("Frame")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterEvent("LOOT_READY")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellID = ...
        if not ns.db.reportDisenchant or not isDisenchant(spellID) then return end
        local now = GetTime()
        local source = lastUse and now - lastUse.time <= TARGET_WAIT and lastUse.link or nil
        lastUse = nil
        pending = {time = now, source = source}
    elseif event == "LOOT_READY" then
        -- LOOT_READY comes before auto-loot empties the window.
        local p = pending
        pending = nil
        if p and GetTime() - p.time <= LOOT_WAIT then report(p.source) end
    end
end)
