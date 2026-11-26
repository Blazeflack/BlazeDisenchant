local _, ns = ...

function ns.IsSecret(value)
    return issecretvalue and issecretvalue(value)
end

local function quote(itemID)
    local gw = Goldwright
    if type(gw) ~= "table" or type(gw.ItemData) ~= "function" or type(gw.House) ~= "function" then
        return nil
    end
    local house = gw.House()
    local data = gw.ItemData(itemID)
    local side = house and house.side
    local entry = side and data and data[side]
    return entry and entry.mv
end

function ns.Price(itemID)
    -- Goldwright owns cache invalidation and market selection. Never write its data.
    local ok, value = pcall(quote, itemID)
    if not ok or ns.IsSecret(value) then return nil end
    if type(value) == "number" and value > 0 and value < math.huge then return value end
end

function ns.Values(results)
    local prices, total, complete = {}, 0, true
    for i, result in ipairs(results) do
        local price = ns.Price(result.itemID)
        prices[i] = price
        if price then
            total = total + result.chance / 100 * (result.minQuantity + result.maxQuantity) / 2 * price
        else
            complete = false
        end
    end
    return prices, complete and total or nil
end

function ns.Money(value)
    value = math.floor(value + 0.5)
    -- Coin icons like the default UI (letters in colorblind mode).
    if GetMoneyString then
        local ok, text = pcall(GetMoneyString, value, true)
        if ok and type(text) == "string" and text ~= "" then return text end
    end
    local parts = {}
    local quantities = {math.floor(value / 10000), math.floor(value / 100) % 100, value % 100}
    local units = {"|cffffd700g|r", "|cffc7c7cfs|r", "|cffd99559c|r"}
    for i, amount in ipairs(quantities) do
        if amount > 0 or (i == 3 and #parts == 0) then
            parts[#parts + 1] = "|cffffffff" .. amount .. "|r" .. units[i]
        end
    end
    return table.concat(parts, " ")
end
