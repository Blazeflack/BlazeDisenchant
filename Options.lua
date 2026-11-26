local addonName, ns = ...

local defaults = {
    -- Quantity × chance and value range for each material.
    showDetails = true,
    -- With details off, holding this key shows them anyway: SHIFT, CTRL, ALT or NONE.
    detailsKey = "SHIFT",
    -- After each Disenchant, print the materials and their value to chat.
    reportDisenchant = true,
}

local KEY_DOWN = {
    SHIFT = IsShiftKeyDown,
    CTRL = IsControlKeyDown,
    ALT = IsAltKeyDown,
}

-- Defaults until SavedVariables load.
ns.db = CopyTable(defaults)

function ns.ShowDetails()
    if ns.db.showDetails then return true end
    local isDown = KEY_DOWN[ns.db.detailsKey]
    return isDown and isDown() or false
end

local function registerSettings()
    if not (Settings and Settings.RegisterVerticalLayoutCategory and Settings.RegisterProxySetting) then return end
    local category = Settings.RegisterVerticalLayoutCategory("BlazeDisenchant")

    local function proxy(key, varType, name)
        return Settings.RegisterProxySetting(category, "BlazeDisenchant_" .. key,
            varType, name, defaults[key],
            function() return ns.db[key] end,
            function(value) ns.db[key] = value end)
    end

    local function checkbox(key, name, tooltip)
        return Settings.CreateCheckbox(category, proxy(key, Settings.VarType.Boolean, name), tooltip)
    end

    local function dropdown(key, name, tooltip, choices)
        local function options()
            local container = Settings.CreateControlTextContainer()
            for _, choice in ipairs(choices) do container:Add(choice[1], choice[2]) end
            return container:GetData()
        end
        return Settings.CreateDropdown(category, proxy(key, Settings.VarType.String, name), options, tooltip)
    end

    local details = checkbox("showDetails", "Show material details",
        "Show quantities, chances and value ranges for each material. "
        .. "When off, the tooltip lists the materials and the Estimated avg. value only.")
    local key = dropdown("detailsKey", "Details key",
        "While material details are off, hold this key over an item to show them.",
        {{"SHIFT", "Shift"}, {"CTRL", "Ctrl"}, {"ALT", "Alt"}, {"NONE", "None"}})
    key:SetParentInitializer(details, function() return not ns.db.showDetails end)
    checkbox("reportDisenchant", "Report disenchant value in chat",
        "After each Disenchant, print the materials you received and their total value "
        .. "(with Goldwright prices) to your chat window, next to the tooltip estimate.")

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, _, name)
    if name ~= addonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    if type(BlazeDisenchantDB) ~= "table" then BlazeDisenchantDB = {} end
    -- Pre-release builds saved a Shift on/off box instead of a key.
    if BlazeDisenchantDB.shiftForDetails == false and BlazeDisenchantDB.detailsKey == nil then
        BlazeDisenchantDB.detailsKey = "NONE"
    end
    BlazeDisenchantDB.shiftForDetails = nil
    if not KEY_DOWN[BlazeDisenchantDB.detailsKey] and BlazeDisenchantDB.detailsKey ~= "NONE" then
        BlazeDisenchantDB.detailsKey = nil
    end
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
