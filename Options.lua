local addonName, ns = ...

local defaults = {
    -- Quantity × chance and value range for each material.
    showDetails = true,
    -- With details off, holding Shift shows them anyway.
    shiftForDetails = true,
}

-- Defaults until SavedVariables load.
ns.db = CopyTable(defaults)

function ns.ShowDetails()
    if ns.db.showDetails then return true end
    return ns.db.shiftForDetails and IsShiftKeyDown() or false
end

local function registerSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
    local category = Settings.RegisterVerticalLayoutCategory("BlazeDisenchant")

    local function checkbox(key, name, tooltip)
        local setting = Settings.RegisterProxySetting(category, "BlazeDisenchant_" .. key,
            Settings.VarType.Boolean, name, defaults[key],
            function() return ns.db[key] end,
            function(value) ns.db[key] = value end)
        return Settings.CreateCheckbox(category, setting, tooltip)
    end

    local details = checkbox("showDetails", "Show material details",
        "Show quantities, chances and value ranges for each material. "
        .. "When off, the tooltip lists the materials and the Estimated avg. value only.")
    local shift = checkbox("shiftForDetails", "Hold Shift to show details",
        "While material details are off, hold Shift over an item to show them.")
    shift:SetParentInitializer(details, function() return not ns.db.showDetails end)

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    if type(BlazeDisenchantDB) ~= "table" then BlazeDisenchantDB = {} end
    for key, value in pairs(defaults) do
        if BlazeDisenchantDB[key] == nil then BlazeDisenchantDB[key] = value end
    end
    ns.db = BlazeDisenchantDB
    registerSettings()
end)

SLASH_BLAZEDISENCHANT1 = "/blazedisenchant"
SLASH_BLAZEDISENCHANT2 = "/bde"
SlashCmdList.BLAZEDISENCHANT = function()
    if ns.settingsCategory then Settings.OpenToCategory(ns.settingsCategory:GetID()) end
end
