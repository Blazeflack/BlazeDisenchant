local _, ns = ...
local version = GetBuildInfo()
if ns.IsSecret(version) or type(version) ~= "string" or not version:match("^1%.60%.") then return end

local watched = setmetatable({}, {__mode = "k"})
local function clearColumns(tooltip)
    local state = watched[tooltip]
    for _, row in ipairs(state.rows) do
        row.chance:Hide()
        row.price:Hide()
        if row.native then row.native:SetAlpha(1); row.native = nil end
    end
    tooltip.blazeDisenchantAdded = nil
end

local function alignColumns(tooltip, entries)
    local state = watched[tooltip]
    local maxChance, maxPrice, widestChance, widestPrice = 0, 0, "", ""
    for i, entry in ipairs(entries) do
        local native = tooltip:GetRightLine(entry.line)
        local row = state.rows[i]
        if not row then
            row = {
                chance = tooltip:CreateFontString(nil, "OVERLAY"),
                price = tooltip:CreateFontString(nil, "OVERLAY"),
            }
            state.rows[i] = row
        end
        row.native = native
        for _, field in ipairs({"chance", "price"}) do
            local text = row[field]
            text:ClearAllPoints()
            text:SetWidth(0)
            text:SetFontObject(native:GetFontObject())
            text:SetJustifyH("RIGHT")
            text:SetText(entry[field])
        end
        local width = row.chance:GetStringWidth()
        if width > maxChance then maxChance, widestChance = width, entry.chance end
        width = row.price:GetStringWidth()
        if width > maxPrice then maxPrice, widestPrice = width, entry.price end
    end
    -- Identical hidden right-hand text reserves the same native layout width
    -- on every row. No tooltip-wide minimum width or other addon's anchors change.
    local gapText = "    "
    local measure = state.rows[1].price
    measure:SetText(gapText)
    local gap = measure:GetStringWidth()
    measure:SetText(entries[1].price)
    local priceSpace = maxPrice > 0 and (maxPrice + gap) or 0
    local reservation = widestChance .. (maxPrice > 0 and (gapText .. widestPrice) or "")
    for _, row in ipairs(state.rows) do
        if row.native then
            row.native:SetText(reservation)
            row.native:SetAlpha(0)
            row.chance:SetWidth(maxChance)
            row.chance:SetPoint("RIGHT", row.native, "RIGHT", -priceSpace, 0)
            row.chance:Show()
            row.price:SetWidth(math.max(1, maxPrice))
            row.price:SetPoint("RIGHT", row.native, "RIGHT", 0, 0)
            row.price:Show()
        end
    end
end

local function material(id)
    local name, _, quality, _, _, _, _, _, _, icon = C_Item.GetItemInfo(id)
    if ns.IsSecret(name) or ns.IsSecret(quality) or ns.IsSecret(icon) then return nil end
    if not name then
        -- Request without caching a negative result; the next hover can resolve it.
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        name = "Item #" .. id
    end
    if not icon then icon = C_Item.GetItemIconByID(id) end
    if ns.IsSecret(icon) then return nil end
    local color = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
    local text = color and color.hex and (color.hex .. name .. "|r") or name
    return "|T" .. (icon or 134400) .. ":14:14:0:0|t " .. text
end

local function enhance(tooltip, data, explicitRef)
    if tooltip ~= GameTooltip and tooltip ~= ItemRefTooltip
        and tooltip ~= ShoppingTooltip1 and tooltip ~= ShoppingTooltip2 then return end
    if not watched[tooltip] then
        watched[tooltip] = {rows = {}}
        tooltip:HookScript("OnTooltipCleared", clearColumns)
    end
    if tooltip.blazeDisenchantAdded then return end
    local ref = explicitRef
    if ns.IsSecret(ref) then return end
    if not ref and data then
        -- Prefer data.id: recipe tooltips can carry a crafted product's hyperlink.
        if ns.IsSecret(data.id) or ns.IsSecret(data.hyperlink) then return end
        ref = data.id or data.hyperlink
    end
    if ns.IsSecret(ref) then return end
    if not ref and tooltip.GetItem then
        local _, link = tooltip:GetItem()
        if ns.IsSecret(link) then return end
        ref = link
    end
    if type(ref) ~= "number" and type(ref) ~= "string" then return end
    local id = type(ref) == "number" and ref or tonumber(ref:match("item:(%d+)"))
    if not id then return end
    local _, _, quality, level, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(ref)
    if ns.IsSecret(quality) or ns.IsSecret(level) or ns.IsSecret(classID) then return end
    if not quality or not level or not classID then
        if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
        return
    end
    local results, unverified = ns.Results(id, quality, level, classID)
    if not results then return end
    local labels = {}
    for i, result in ipairs(results) do
        labels[i] = material(result.itemID)
        if not labels[i] then return end
    end
    local prices, average = ns.Values(results)
    tooltip.blazeDisenchantAdded = true
    tooltip:AddLine(" ")
    local title = "|cff8fc7ffDisenchant|r · "
    title = title .. (unverified and "|cffffbf69Unverified|r" or "|cff8fc7ffApproximate|r")
    tooltip:AddLine(title)
    local entries = {}
    for i, result in ipairs(results) do
        local low, high = result.minQuantity, result.maxQuantity
        local amount = low == high and tostring(low) or (low .. "–" .. high)
        local right = amount .. " × " .. result.chance .. "%"
        local value = ""
        if prices[i] then
            value = ns.Money(low * prices[i])
            if low ~= high then value = value .. " – " .. ns.Money(high * prices[i]) end
        end
        tooltip:AddDoubleLine(labels[i], right, 0.85, 0.85, 0.85, 0.85, 0.85, 0.85)
        entries[i] = {line = tooltip:NumLines(), chance = "|cffd9d9d9" .. right .. "|r", price = value}
    end
    if next(prices) then alignColumns(tooltip, entries) end
    if average then
        tooltip:AddDoubleLine("Estimated avg. value", ns.Money(average), 0.56, 0.78, 1, 1, 1, 1)
        tooltip:AddLine(" ")
    end
end

if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, enhance)
end
for _, tooltip in pairs({GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2}) do
    if tooltip.HasScript and tooltip:HasScript("OnTooltipSetItem") then
        tooltip:HookScript("OnTooltipSetItem", function(self) enhance(self) end)
    end
    -- Forever setter paths may bypass TooltipDataProcessor (Disenchantry 1.2.9).
    local function hook(method, resolve)
        if not hooksecurefunc or type(tooltip[method]) ~= "function" then return end
        hooksecurefunc(tooltip, method, function(self, ...)
            local ref = resolve(...)
            if ns.IsSecret(ref) then return end
            enhance(self, nil, ref)
            if self.blazeDisenchantAdded and self:IsShown() then self:Show() end
        end)
    end
    hook("SetHyperlink", function(link) return link end)
    hook("SetItemByID", function(id) return id end)
    hook("SetBagItem", function(bag, slot)
        if ns.IsSecret(bag) or ns.IsSecret(slot) then return end
        return C_Container.GetContainerItemLink(bag, slot)
    end)
    -- GetItem is used for equipment; no unverified inventory API signature needed.
    hook("SetInventoryItem", function() return nil end)
end
