---------------------------------------------
-- rTooltip (optimized)
---------------------------------------------
local addon, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")
local RAID_CLASS_COLORS, FACTION_BAR_COLORS = RAID_CLASS_COLORS, FACTION_BAR_COLORS
local GameTooltip, GameTooltipStatusBar = GameTooltip, GameTooltipStatusBar
local format, ipairs, pairs = string.format, ipairs, pairs

---------------------------------------------
-- HELPERS
---------------------------------------------
local function AddSpellIdRow(tooltip, spellid)
  tooltip:AddDoubleLine("|cff0099ffSpell ID|r", tostring(spellid))
  tooltip:Show()      -- ensures frame is resized
end

local function AddItemIdRow(tooltip, itemid)
  tooltip:AddDoubleLine("|cff0099ffItem ID|r", tostring(itemid))
  tooltip:Show()
end

local function AddBossDebuffRow(tooltip)
  tooltip:AddDoubleLine("|cff0099ffBossDebuff|r", "Yes")
end

local function GetHexColor(color)
  return ("%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)
end

local function GetTarget(unit, classColors, reactionColors)
  if UnitIsUnit(unit, "player") then
    return "|cffff0000<YOU>|r"
  elseif UnitIsPlayer(unit) then
    local _, class = UnitClass(unit)
    return ("|cff%s%s|r"):format(classColors[class], UnitName(unit))
  elseif UnitReaction(unit, "player") then
    return ("|cff%s%s|r"):format(reactionColors[UnitReaction(unit, "player")], UnitName(unit))
  else
    return ("|cffffffff%s|r"):format(UnitName(unit))
  end
end

-- ---------------------------------------------
-- Tooltip spell school border coloring (TBCC+)
-- ---------------------------------------------

local SCHOOL_COLORS = {
  physical = { 0.85, 0.70, 0.15 }, -- grey
  holy     = { 1.00, 0.90, 0.50 },
  fire     = { 1.00, 0.35, 0.20 },
  nature   = { 0.20, 1.00, 0.20 },
  frost    = { 0.35, 0.80, 1.00 },
  shadow   = { 0.65, 0.35, 1.00 },
  arcane   = { 0.90, 0.35, 1.00 },
}

-- crude “is this a damage tooltip?” test
local function TooltipLooksDamaging(tooltip)
  local n = tooltip:NumLines() or 0
  for i = 2, n do
    local fs = _G[tooltip:GetName() .. "TextLeft" .. i]
    local s = fs and fs:GetText()
    if s then
      s = s:lower()
      if s:find(" damage") or s:find("deals ") or s:find("causes ") or s:find("inflicts ") then
        return true
      end
    end
  end
  return false
end

local function FindSchoolInTooltip(tooltip)
  local n = tooltip:NumLines() or 0
  local foundDamage = false

  for i = 2, n do
    local fs = _G[tooltip:GetName() .. "TextLeft" .. i]
    local s = fs and fs:GetText()
    if s and s ~= "" then
      -- 1) Explicit non-physical schools (capitalized + " damage")
      if s:find("Nature damage") then return "nature", true end
      if s:find("Fire damage")   then return "fire",   true end
      if s:find("Frost damage")  then return "frost",  true end
      if s:find("Shadow damage") then return "shadow", true end
      if s:find("Arcane damage") then return "arcane", true end
      if s:find("Holy damage")   then return "holy",   true end

      -- 2) Damage-ish phrases → later default to physical if no school found
      -- (keep this fairly broad, but avoid lowercase school words entirely)
      if s:find("damage") or s:find("Damage") then
        foundDamage = true
      elseif s:find("weapon damage") or s:find("Weapon damage") then
        foundDamage = true
      elseif s:find("melee damage") or s:find("Melee damage") then
        foundDamage = true
      elseif s:find("ranged damage") or s:find("Ranged damage") then
        foundDamage = true
      elseif s:find("attack that") or s:find("Attack that") then
        foundDamage = true
      elseif s:find("causes") and (s:find("damage") or s:find("Damage")) then
        foundDamage = true
      end
    end
  end

  -- 3) If it looks like it deals damage but no school was found: default to physical
  if foundDamage then
    return "physical", true
  end

  -- No damage implied
  return nil, false
end



local function ApplySchoolBorder(tooltip)
  if not tooltip or not tooltip.GetName then return end
  -- only apply on spell tooltips (actionbar/spellbook/links etc), not every item tooltip
  if not tooltip.__rt_isSpell then return end
  if not TooltipLooksDamaging(tooltip) then
    -- not a damage tooltip -> let your normal border logic win
    return
  end

  local school = FindSchoolInTooltip(tooltip) or "physical"
  local c = SCHOOL_COLORS[school] or SCHOOL_COLORS.physical
  tooltip:SetBackdropBorderColor(c[1], c[2], c[3], 1)
end


---------------------------------------------
-- INIT
---------------------------------------------
local function Init()
  local cfg = ns.cfg.embeds.rTooltip
  if not cfg.enabled then return end

    -- Fonts
  local headerFont = ns.Media.Font(ns.cfg.fonts.headerFont)
  local textFont   = ns.Media.Font(ns.cfg.fonts.textFont)
  GameTooltipHeaderText:SetFont(headerFont, 14, "THINOUTLINE")
  GameTooltipText:SetFont(textFont, 12, "THINOUTLINE")
  Tooltip_Small:SetFont(textFont, 11, "THINOUTLINE")

  -- Status bar
  GameTooltipStatusBar:ClearAllPoints()
  GameTooltipStatusBar:SetPoint("LEFT", 5, 0)
  GameTooltipStatusBar:SetPoint("RIGHT", -5, 0)
  GameTooltipStatusBar:SetPoint("BOTTOM", GameTooltipStatusBar:GetParent(), "TOP", 0, -6)
  GameTooltipStatusBar:SetHeight(3)

  GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  GameTooltipStatusBar.bg:SetAllPoints(GameTooltipStatusBar)
  GameTooltipStatusBar.bg:SetColorTexture(0,0,0,0.7)

  -- Color lookup tables
  local classColors, reactionColors = {}, {}
  for class, c in pairs(RAID_CLASS_COLORS) do
    classColors[class] = GetHexColor(c)
  end
  for i, c in ipairs(FACTION_BAR_COLORS) do
    reactionColors[i] = GetHexColor(c)
  end

  ---------------------------------------------
  -- HOOKS
  ---------------------------------------------

  -- Clear
  GameTooltip:HookScript("OnTooltipCleared", GameTooltip_ClearStatusBars)

  -- Position
  hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if cfg.cursorfocus then
      tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    else
      tooltip:SetOwner(parent, "ANCHOR_NONE")
      tooltip:ClearAllPoints()
      tooltip:SetPoint(cfg.pos.a1, cfg.x, cfg.y)
    end
  end)

  -- Shared aura hook

-- -------------------------------------------------------
-- Item ID rows
-- -------------------------------------------------------
local function ItemHandler(self)
  -- Only add once per tooltip refresh
  if self.__rt_addedItemID then return end

  local _, link = self:GetItem()
  if not link then return end

  local itemID = tonumber(link:match("item:(%d+)"))
  if not itemID then return end

  self.__rt_addedItemID = true
  AddItemIdRow(self, itemID)
end

GameTooltip:HookScript("OnTooltipSetItem", ItemHandler)
ItemRefTooltip:HookScript("OnTooltipSetItem", ItemHandler)

GameTooltip:HookScript("OnTooltipCleared", function(self)
  self.__rt_addedItemID = nil
end)
ItemRefTooltip:HookScript("OnTooltipCleared", function(self)
  self.__rt_addedItemID = nil
end)

local function SpellHandler(self, spellID, isBossAura)
    if not spellID then return end
    AddSpellIdRow(self, spellID)
    if isBossAura then
        AddBossDebuffRow(self)
    end
end
  
local function AuraHandler(self, ...)
  local data = C_UnitAuras.GetAuraDataByIndex(...)
  if data then
    SpellHandler(self, data.spellId, data.isBossAura)
  end
end
  
-- Mark spell tooltips
GameTooltip:HookScript("OnTooltipSetSpell", function(self)
  self.__rt_isSpell = true

  local name = self:GetSpell()
  if not name then return end

  local spellID = select(7, GetSpellInfo(name))
  if spellID then
    SpellHandler(self, spellID)
  end
end)

-- Apply school coloring once tooltip has real text
GameTooltip:HookScript("OnUpdate", function(self)
  if self.__rt_isSpell and not self.__rt_schoolDone then
    self.__rt_schoolDone = true
    ApplySchoolBorder(self)
  end
end)

-- Reset between tooltips
GameTooltip:HookScript("OnTooltipCleared", function(self)
  self.__rt_isSpell = nil
  self.__rt_schoolDone = nil
end)



-- Pet actions
hooksecurefunc(GameTooltip, "SetPetAction", function(self, index)
    local name, texture, isToken, isActive, autoCastAllowed, autoCastEnabled, spellID = GetPetActionInfo(index)
    if spellID then SpellHandler(self, spellID) end
end)

hooksecurefunc(GameTooltip, "SetUnitBuff", AuraHandler)
hooksecurefunc(GameTooltip, "SetUnitDebuff", AuraHandler)
hooksecurefunc(GameTooltip, "SetUnitAura", AuraHandler)

-- Chat-linked spells
hooksecurefunc("SetItemRef", function(link)
  if link:find("^spell:") then
    local spellID = tonumber(link:sub(7))
    SpellHandler(ItemRefTooltip, spellID)
  end
end)

if not Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Spell, function(tooltip, data)
        if data and data.id then
            SpellHandler(tooltip, data.id)
        end
    end)
end

local function AddTargetLine(self, classColors, reactionColors)
    local _, unit = self:GetUnit()
    if not unit or not UnitExists(unit) then return end

    -- Only add once per tooltip refresh
    if self.__addedTarget then return end
    self.__addedTarget = true

    if UnitExists(unit.."target") then
        self:AddDoubleLine("|cffff9999Target|r", GetTarget(unit.."target", classColors, reactionColors) or "Unknown")
        self:Show()
    end
end

-- When tooltip is shown, reset our flag
GameTooltip:HookScript("OnShow", function(self)
    self.__addedTarget = nil
end)

-- While tooltip is being updated, try to add our line
GameTooltip:HookScript("OnUpdate", function(self)
    AddTargetLine(self, classColors, reactionColors)
end)

-- Reset when tooltip is cleared
GameTooltip:HookScript("OnTooltipCleared", function(self)
    self.__addedTarget = nil
end)


  -- Menu scale
  for _, menu in ipairs({DropDownList1MenuBackdrop, DropDownList2MenuBackdrop}) do
    menu:SetScale(cfg.scale)
  end
  
  -- -------------------------------------------------------
  -- Crafting tooltip info (Known recipes, persistent per alt)
  -- Requires TOC: ## SavedVariables: RothUICraftDB
  -- -------------------------------------------------------
  
  -- SavedVariables root
  RothUICraftDB = RothUICraftDB or {}
  
  -- Session index for quick lookups on current login:
  -- craftIndex[itemID] = { [professionName] = requiredSkillOrTrue }
  ns.__craftIndex = ns.__craftIndex or {}
  local craftIndex = ns.__craftIndex
  
  local function GetRealmChar()
    local name = UnitName("player")
    local realm = GetRealmName()
    return realm, name
  end
  
  local function EnsureCraftDB()
    RothUICraftDB = RothUICraftDB or {}
    local realm, name = GetRealmChar()
  
    RothUICraftDB[realm] = RothUICraftDB[realm] or {}
    RothUICraftDB[realm][name] = RothUICraftDB[realm][name] or { crafts = {}, professions = {} }
  
    return RothUICraftDB[realm], RothUICraftDB[realm][name], realm, name
  end
  
  local function AddCraftIndex(itemID, professionName, reqSkill)
    if not itemID or not professionName then return end
    craftIndex[itemID] = craftIndex[itemID] or {}
    craftIndex[itemID][professionName] = reqSkill or true
  end
  
  local function PersistCraft(itemID, professionName, reqSkill)
    local _, charDB = EnsureCraftDB()
    charDB.professions[professionName] = true
    charDB.crafts[itemID] = charDB.crafts[itemID] or {}
    charDB.crafts[itemID][professionName] = reqSkill or true
  end
  
  local function ScanOpenTradeSkill()
    if not GetNumTradeSkills or not GetTradeSkillLine then return end
  
    local profName = GetTradeSkillLine()
    if not profName or profName == "" or profName == UNKNOWN then return end
  
    local n = GetNumTradeSkills()
    if not n or n < 1 then return end
  
    -- Ensure character exists in DB and mark profession seen
    local _, charDB = EnsureCraftDB()
    charDB.professions[profName] = true
  
    for i = 1, n do
      local name, skillType = GetTradeSkillInfo(i)
      if name and skillType ~= "header" and skillType ~= "subheader" then
        local link = GetTradeSkillItemLink(i)
        local itemID = link and tonumber(link:match("item:(%d+)"))
        if itemID then
          local reqSkill
          if GetTradeSkillSkillReq then
            reqSkill = GetTradeSkillSkillReq(i)
          end
  
          AddCraftIndex(itemID, profName, reqSkill)
          PersistCraft(itemID, profName, reqSkill)
        end
      end
    end
  end
  
  local function HookTradeSkillEvents()
    local f = CreateFrame("Frame")
    f:RegisterEvent("TRADE_SKILL_SHOW")
    f:RegisterEvent("TRADE_SKILL_UPDATE")
    f:RegisterEvent("SKILL_LINES_CHANGED")
    f:SetScript("OnEvent", function()
      if cfg and cfg.showCraftingInfo == false then return end
      -- Defer so the tradeskill list is fully populated
      ns.Scheduler.NextFrame(ScanOpenTradeSkill)
    end)
  end
  
  HookTradeSkillEvents()
  
  local function BuildProfessionListForCurrent(itemID)
    local profs = craftIndex[itemID]
    if not profs then return nil end
  
    local parts = {}
    for profName, req in pairs(profs) do
      if type(req) == "number" then
        parts[#parts + 1] = ("%s (%d)"):format(profName, req)
      else
        parts[#parts + 1] = profName
      end
    end
    table.sort(parts)
    return parts
  end
  
  local function BuildAltCrafterList(itemID)
    local realmDB, _, _, currentName = EnsureCraftDB()
    if not realmDB then return nil end
  
    local alts = {}
    for charName, charDB in pairs(realmDB) do
      if charName ~= currentName and charDB and charDB.crafts and charDB.crafts[itemID] then
        local profParts = {}
        for profName, req in pairs(charDB.crafts[itemID]) do
          if type(req) == "number" then
            profParts[#profParts + 1] = ("%s %d"):format(profName, req)
          else
            profParts[#profParts + 1] = profName
          end
        end
        table.sort(profParts)
  
        alts[#alts + 1] = {
          name = charName,
          text = ("%s (%s)"):format(charName, table.concat(profParts, ", ")),
        }
      end
    end
  
    if #alts == 0 then return nil end
    table.sort(alts, function(a,b) return a.name < b.name end)
  
    local lines = {}
    for i = 1, math.min(3, #alts) do
      lines[#lines + 1] = alts[i].text
    end
    if #alts > 3 then
      lines[#lines + 1] = ("(+%d more)"):format(#alts - 3)
    end
  
    return lines
  end
  
  local function AddCraftInfoToTooltip(tooltip)
    if cfg and cfg.showCraftingInfo == false then return end
  
    local _, link = tooltip:GetItem()
    if not link then return end
  
    local itemID = tonumber(link:match("item:(%d+)"))
    if not itemID then return end
  
    local parts = BuildProfessionListForCurrent(itemID)
    local altLines = BuildAltCrafterList(itemID)
  
    if not parts and not altLines then return end
  
    tooltip:AddLine(" ")
  
    if parts then
      tooltip:AddLine("|cff66ccffCraftable by (Known)|r")
      tooltip:AddLine("  " .. table.concat(parts, ", "), 1, 1, 1, true)
    end
  
    if altLines then
      tooltip:AddLine("|cff66ccffAlso craftable by alts|r")
      for _, line in ipairs(altLines) do
        tooltip:AddLine("  " .. line, 1, 1, 1, true)
      end
    end
  
    tooltip:Show()
  end
  
  GameTooltip:HookScript("OnTooltipSetItem", AddCraftInfoToTooltip)
  ItemRefTooltip:HookScript("OnTooltipSetItem", AddCraftInfoToTooltip)
end

ns:RegisterInit(Init)
Roth_UI:AddConfig("embeds.rTooltip", {}, "Tooltips", Init, true)
