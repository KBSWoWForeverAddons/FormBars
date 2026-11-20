-- FormBars: Reliable Druid form, Prowl, and powershift action bar paging for WoW Forever (16001).
-- Works seamlessly with both Dominos and the default Blizzard MainActionBar.

local PREFIX = "|cff00ff00FormBars|r: "

local FORM_SPELLS = {
    [5487]  = "bear",    -- Bear Form
    [9634]  = "bear",    -- Dire Bear Form
    [768]   = "cat",     -- Cat Form
    [783]   = "travel",  -- Travel Form
    [1066]  = "aquatic", -- Aquatic Form
    [24858] = "moonkin", -- Moonkin Form
    [33891] = "tree",    -- Tree of Life
}

local NAME_MATCH = {
    { "bear",         "bear" },
    { "cat",          "cat" },
    { "moonkin",      "moonkin" },
    { "tree of life", "tree" },
    { "travel",       "travel" },
    { "aquatic",      "aquatic" },
}

local PAGES = {
    cat     = 7,  -- Slots 73-84
    prowl   = 8,  -- Slots 85-96 (Cat Form + Stealth)
    bear    = 9,  -- Slots 97-108
    moonkin = 10, -- Slots 109-120
    tree    = 10,
}

local requestedSpells = {}

local function GetSpellNameByID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellName then
        local name = C_Spell.GetSpellName(spellID)
        if not name and C_Spell.RequestLoadSpellData and not requestedSpells[spellID] then
            requestedSpells[spellID] = true
            C_Spell.RequestLoadSpellData(spellID)
        end
        return name
    elseif GetSpellInfo then
        return (GetSpellInfo(spellID))
    end
    return nil
end

local function GetSpellIconByID(spellID)
    if not spellID then return nil end
    if C_Spell and C_Spell.GetSpellTexture then
        local ok, tex = pcall(C_Spell.GetSpellTexture, spellID)
        return ok and tex or nil
    elseif GetSpellTexture then
        return GetSpellTexture(spellID)
    end
    return nil
end

local function ClassifyFormSlot(index)
    local icon, nameOrActive, _, spellID = GetShapeshiftFormInfo(index)
    local name
    if type(nameOrActive) == "string" then
        name, spellID = nameOrActive, nil
    elseif spellID then
        if FORM_SPELLS[spellID] then
            return FORM_SPELLS[spellID]
        end
        name = GetSpellNameByID(spellID)
    end

    local lower = name and name:lower()
    for id, key in pairs(FORM_SPELLS) do
        local knownName = GetSpellNameByID(id)
        if lower and knownName and knownName:lower() == lower then
            return key
        end
        local knownIcon = GetSpellIconByID(id)
        if icon and knownIcon and icon == knownIcon then
            return key
        end
    end

    if lower then
        for _, pair in ipairs(NAME_MATCH) do
            if lower:find(pair[1], 1, true) then
                return pair[2]
            end
        end
    end
    return nil
end

-- Returns a table mapping form key ("bear", "cat", "moonkin", "tree") -> shapeshift bar index
local function GetFormSlots()
    local slots = {}
    local numForms = GetNumShapeshiftForms and GetNumShapeshiftForms() or 0
    for i = 1, numForms do
        local key = ClassifyFormSlot(i)
        if key and not slots[key] then
            slots[key] = i
        end
    end

    -- Fallback if spell data is still loading on initial login frame
    if not slots.bear and numForms >= 1 then
        slots.bear = 1
    end
    if not slots.cat and numForms >= 2 then
        slots.cat = (numForms >= 3) and 3 or 2
    end
    return slots
end

---------------------------------------------------------------------------
-- 1. Dominos Integration (when Dominos is enabled)
---------------------------------------------------------------------------

local function ApplyDominosPaging()
    local Dominos = _G["Dominos"]
    local domBar1 = _G["DominosFrame1"]
    if not (Dominos and domBar1) then
        return false
    end

    -- Update Dominos's DRUID BarStates so Bear, Cat, and Prowl use [form:N]
    -- (which works reliably on powershift) with [bonusbar:N] as fallback.
    if Dominos.BarStates and Dominos.BarStates.GetAll then
        for _, state in Dominos.BarStates:GetAll("class") do
            if state.id == "bear" then
                state.value = function()
                    local slots = GetFormSlots()
                    if slots.bear then
                        return ("[form:%d][bonusbar:3]"):format(slots.bear)
                    end
                    return "[bonusbar:3]"
                end
            elseif state.id == "prowl" then
                state.value = function()
                    local slots = GetFormSlots()
                    if slots.cat then
                        return ("[form:%d,stealth][bonusbar:1,stealth]"):format(slots.cat)
                    end
                    return "[bonusbar:1,stealth]"
                end
            elseif state.id == "cat" then
                state.value = function()
                    local slots = GetFormSlots()
                    if slots.cat then
                        return ("[form:%d][bonusbar:1]"):format(slots.cat)
                    end
                    return "[bonusbar:1]"
                end
            end
        end
    end

    -- Ensure Dominos Bar 1 has paging offsets for Cat (Page 7), Prowl (Page 8), and Bear (Page 9).
    -- In Dominos's Camelot defaults, 'prowl' was omitted from getMainBarPages('DRUID').
    if type(domBar1.paging) == "table" and Dominos.AddressMap then
        local function pageOffset(page)
            return Dominos.AddressMap:GetAddress((page - 1) * 12 + 1) - 1
        end
        if not domBar1.paging.cat then
            domBar1.paging.cat = pageOffset(PAGES.cat)     -- 108 -> Slots 73-84 (Page 7)
        end
        if not domBar1.paging.prowl then
            domBar1.paging.prowl = pageOffset(PAGES.prowl) -- 120 -> Slots 85-96 (Page 8)
        end
        if not domBar1.paging.bear then
            domBar1.paging.bear = pageOffset(PAGES.bear)   -- 132 -> Slots 97-108 (Page 9)
        end
    end

    -- Refresh Dominos Bar 1 button actions and state driver
    if domBar1.ApplyPaging then
        UnregisterStateDriver(domBar1, "page")
        domBar1:ApplyPaging()
    end

    return true
end

---------------------------------------------------------------------------
-- 2. Default Blizzard MainActionBar Integration (when Dominos is disabled)
---------------------------------------------------------------------------

local header = CreateFrame("Frame", "FormBarsHeader", UIParent, "SecureHandlerStateTemplate")

header:SetAttribute("_onstate-formpage", [[
    local page = tonumber(newstate)
    if not page then
        -- Ignore "pending" set from insecure Lua; the C++ state driver's next
        -- secure tick applies the real page number without taint.
        return
    end
    if page <= 0 then
        page = nil -- Caster form: clear override so normal Blizzard paging works
    end
    for i = 1, 12 do
        local b = self:GetFrameRef("button" .. i)
        if b and b:GetAttribute("actionpage") ~= page then
            b:SetAttribute("actionpage", page)
        end
    end
]])

local function BuildBlizzardCondition()
    local slots = GetFormSlots()
    local parts = {}

    if slots.cat then
        parts[#parts + 1] = ("[form:%d,stealth]%d"):format(slots.cat, PAGES.prowl)
        parts[#parts + 1] = ("[form:%d]%d"):format(slots.cat, PAGES.cat)
    end
    if slots.bear then
        parts[#parts + 1] = ("[form:%d]%d"):format(slots.bear, PAGES.bear)
    end
    if slots.moonkin then
        parts[#parts + 1] = ("[form:%d]%d"):format(slots.moonkin, PAGES.moonkin)
    end
    if slots.tree then
        parts[#parts + 1] = ("[form:%d]%d"):format(slots.tree, PAGES.tree)
    end

    parts[#parts + 1] = "[bonusbar:1,stealth]" .. PAGES.prowl
    parts[#parts + 1] = "[bonusbar:1]" .. PAGES.cat
    parts[#parts + 1] = "[bonusbar:3]" .. PAGES.bear
    parts[#parts + 1] = "0"

    return table.concat(parts, ";")
end

local lastBlizzCondition = nil

local function ApplyBlizzardPaging()
    local attached = 0
    for i = 1, 12 do
        local b = _G["ActionButton" .. i]
        if b then
            header:SetFrameRef("button" .. i, b)
            attached = attached + 1
        end
    end

    local condition = BuildBlizzardCondition()
    local key = condition .. "#" .. attached
    if key == lastBlizzCondition then
        return
    end
    lastBlizzCondition = key

    UnregisterStateDriver(header, "formpage")
    RegisterStateDriver(header, "formpage", condition)
    -- Park on "pending" so the C++ state driver securely transitions to the real page
    header:SetAttribute("state-formpage", "pending")
end

---------------------------------------------------------------------------
-- Master Update & Helpful Prowl Page 8 Reminder
---------------------------------------------------------------------------

local pendingUpdate = false
local prowlReminded = false

local function ApplyFormBars()
    if InCombatLockdown() then
        pendingUpdate = true
        return
    end
    pendingUpdate = false

    if ApplyDominosPaging() then
        -- Dominos owns ActionButton1-12; make sure FormBarsHeader is unregistered
        if lastBlizzCondition then
            UnregisterStateDriver(header, "formpage")
            lastBlizzCondition = nil
        end
    else
        ApplyBlizzardPaging()
    end
end

local function CheckProwlSlotReminder()
    if prowlReminded then return end
    if not (IsStealthed and IsStealthed()) then return end
    -- Check if Slot 85 (Page 8, Button 1) still has the default Moonfire spell from level 1
    local actionType, id = GetActionInfo(85)
    if actionType == "spell" and id then
        local name = GetSpellNameByID(id)
        if name and name:lower():find("moonfire", 1, true) then
            prowlReminded = true
            DEFAULT_CHAT_FRAME:AddMessage(
                PREFIX .. "Your Prowl bar (Page 8, slots 85-96) is active, but still has |cffffd000Moonfire/Wrath|r copied from level 1! " ..
                "While prowling, drag your Prowl abilities (Pounce, Ravage, Shred, etc.) from your Spellbook/Macros onto Bar 1 to replace them."
            )
        end
    end
end

SLASH_FORMBARS1 = "/formbars"
SLASH_FORMBARS2 = "/fb"
SlashCmdList.FORMBARS = function()
    local slots = GetFormSlots()
    local domBar1 = _G["DominosFrame1"]
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. string.format(
        "Mode=%s | Bear=[form:%s]->P%d | Cat=[form:%s]->P%d | Prowl=[form:%s,stealth]->P%d",
        domBar1 and "Dominos" or "Blizzard",
        tostring(slots.bear), PAGES.bear,
        tostring(slots.cat), PAGES.cat,
        tostring(slots.cat), PAGES.prowl
    ))
    if domBar1 then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. string.format(
            "DominosFrame1 state-page=%s | Btn1 action=%s",
            tostring(domBar1:GetAttribute("state-page")),
            tostring(ActionButton1 and ActionButton1:GetAttribute("action"))
        ))
    elseif ActionButton1 then
        DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. string.format(
            "Header state=%s | Btn1 actionpage=%s, action=%s",
            tostring(header:GetAttribute("state-formpage")),
            tostring(ActionButton1:GetAttribute("actionpage")),
            tostring(ActionButton1.action)
        ))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("SPELL_DATA_LOAD_RESULT")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("UPDATE_STEALTH")
events:SetScript("OnEvent", function(self, event, arg1, arg2)
    if select(2, UnitClass("player")) ~= "DRUID" then
        self:UnregisterAllEvents()
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingUpdate then
            ApplyFormBars()
        end
    elseif event == "UPDATE_STEALTH" then
        C_Timer.After(0.1, CheckProwlSlotReminder)
    elseif event == "SPELL_DATA_LOAD_RESULT" then
        if requestedSpells[arg1] then
            requestedSpells[arg1] = nil
            if arg2 then
                C_Timer.After(0.1, ApplyFormBars)
            end
        end
    else
        ApplyFormBars()
        C_Timer.After(0.3, ApplyFormBars)
    end
end)
