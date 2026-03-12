-- rNamePlates: core
-- Galaxy 2016

-----------------------------
-- Variables
-----------------------------

local addon, ns = ...
local EliteTag = "+"
local RareTag = "^"
local BossTag = "*"
local cfg
local LSM = LibStub("LibSharedMedia-3.0")
-----------------------------
-- SetCVar
-----------------------------

SetCVar("namePlateMinScale", 1)
SetCVar("namePlateMaxScale", 1)

-----------------------------
-- Options
-----------------------------
local groups = {
	"Enemy",
	"Friendly",
	}

local options = {
	useClassColors = true,
	displayNameWhenSelected = true,
	displayNameByPlayerNameRules = true,
	playLoseAggroHighlight = false,
	displayAggroHighlight = true,
	displaySelectionHighlight = true,
	considerSelectionInCombatAsHostile = true,
	colorNameWithExtendedColors = true,
	colorHealthWithExtendedColors = true,
	selectedBorderColor = CreateColor(0, 0, 0, 1),
	tankBorderColor = false,
	defaultBorderColor = CreateColor(0, 0, 0, 1),
	showClassificationClassificationIndicator = true,
	}

local function ApplyNameplateOptionsCrossClient()
  -- Retail: you can still use the options table (or the modern settings API),
  -- Classic/TBC: DO NOT touch DefaultCompactNamePlateEnemyFrameOptions (taints).
  local isClassic = Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)

  -- Things that are CVars on all/most clients:
  -- (Only set what exists; some CVars differ by client build.)
  local function SafeSetCVar(cvar, val)
    if GetCVar(cvar) ~= nil then
      SetCVar(cvar, tostring(val))
    end
  end

  -- 1) displayNameWhenSelected / displaySelectionHighlight / considerSelectionInCombatAsHostile
  -- These are generally CVar-driven, but names vary by client/version.
  -- Keep them "best effort" without breaking anything.
  SafeSetCVar("nameplateShowOnlyNames", 0)                    -- ensure healthbars can show
  SafeSetCVar("nameplateShowFriendlyNPCs", 1)                 -- optional; depends what you want
  SafeSetCVar("nameplateShowEnemies", 1)

  -- 2) class colors on nameplates (Retail/Classic both have versions of these)
  SafeSetCVar("ShowClassColorInNameplate", 1)                 -- common on classic-era
  SafeSetCVar("nameplateShowAll", 1)                          -- sometimes used

  -- If we're on Retail, you may optionally apply the table (safer there).
  if not isClassic and DefaultCompactNamePlateEnemyFrameOptions then
    for k,v in pairs(options) do
      DefaultCompactNamePlateEnemyFrameOptions[k] = v
    end
  end
end


-----------------------------
-- Functions
-----------------------------

local function GetHexColorFromRGB(r, g, b)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

--SetupNamePlate
local function Init()
cfg = ns.cfg.embeds.rNamePlates

if not cfg.enabled then return end
local font = ns.Media.Font(ns.cfg.fonts.textFont)
ApplyNameplateOptionsCrossClient()

--Name
hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
	if frame:IsForbidden() then return end
	if frame.unit == nil then return end
   --Set the tag based on UnitClassification, can return "worldboss", "rare", "rareelite", "elite", "normal", "minus"
	local tag 
	local level = UnitLevel(frame.unit)
	local name = UnitName(frame.unit)
	local hexColor = GetCreatureDifficultyColor(level)
	hexColor = ConvertRGBtoColorString(hexColor)   


	if UnitClassification(frame.unit) == "worldboss" or UnitLevel(frame.unit) == -1 then
		level = "??"
	elseif UnitClassification(frame.unit) == "rare" then
		name = RareTag..name..RareTag
	elseif UnitClassification(frame.unit) == "rareelite" then
		name = RareTag..name..RareTag
		level = EliteTag..level
	elseif UnitClassification(frame.unit) == "elite" then
		level = EliteTag..level
	end
	--Set the nameplate name to include tag(if any), name and level
	if (name and level) then
		frame.name:SetText("("..hexColor..""..level.."|r) "..name)
		frame.name:SetFont(font, 12)
	end
	
	if (frame.healthBar.re) then
		frame.healthBar.re:SetSize(64,64)
	end
	if (frame.healthBar.le) then
		frame.healthBar.le:SetSize(64,64)
	end
end)

hooksecurefunc("CompactUnitFrame_UpdateHealth", function(frame)
cfg = ns.cfg.embeds.rNamePlates

    if not frame or not frame.unit then return end
    
    if not cfg.showHealthValue then
        if frame.healthBar.text then
            frame.healthBar.text:SetText("")
        end
        return
    end
    
    if (frame.healthBar.text) then
        local health = UnitHealth(frame.unit)
        local maxHealth = UnitHealthMax(frame.unit)
        local percHealth = floor(health / maxHealth * 100)
        local text = health
        
        if cfg.healthValueAsPercent then
            text = percHealth.."%"
        else
            text = health.."/"..maxHealth
        end
        
        local color = GetHexColorFromRGB(0,1,0)
        if (percHealth < 75) then
            color = GetHexColorFromRGB(1,1,0)
        elseif (percHealth < 25) then
            color = GetHexColorFromRGB(1,0,0)
        end

        frame.healthBar.text:SetText("|cff"..color..text.."|r")
    end
end)

hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(frame, setupOptions, frameOptions)
    if frame:IsForbidden() or frame.__rnp_skinned then return end
    frame.__rnp_skinned = true

    -- Health Bar
    frame.healthBar:SetStatusBarTexture(ns.mediapath.."statusbar_fill")

    -- IMPORTANT: never scale the bar (scaling is what trips layout math)
    -- frame.healthBar:SetScale(1.35)  -- REMOVE this line

    frame.RaidTargetFrame.RaidTargetIcon:SetTexture(ns.mediapath.."raidicons")
    frame.RaidTargetFrame:ClearAllPoints()
    frame.RaidTargetFrame:SetPoint("RIGHT", frame.healthBar, "RIGHT", 35, 0)
    
    if frame.ClassificationFrame then
        frame.ClassificationFrame:Hide()
    end
    
    if frame.LevelFrame then
        frame.LevelFrame:Hide()
    end
    
    if frame.border then
        frame.border:Hide()
    end
    if frame.healthBar.border then
        frame.healthBar.border:Hide()
    end
    
    if frame.HealthBarsContainer.border then
        frame.HealthBarsContainer.border:Hide()
    end

    -- Left Edge artwork
    if not frame.healthBar.le then
        local t = frame.healthBar:CreateTexture(nil, "BACKGROUND", nil, -8)
        t:SetTexture(ns.mediapath.."edge_left")
        t:SetSize(64,64)
        t:SetPoint("RIGHT", frame.healthBar, "LEFT", 0, 0)
        t:SetScale(0.25)
        frame.healthBar.le = t
    end

    -- Health value text
    if not frame.healthBar.text then
        local fs = frame.healthBar:CreateFontString(nil, "OVERLAY")
        fs:SetFont(font, cfg.fontSize, "THICKOUTLINE")
        fs:SetPoint("CENTER", frame.healthBar, "CENTER", 0, 0)
        fs:SetScale(0.25)
        frame.healthBar.text = fs
    end

    -- Right Edge artwork
    if not frame.healthBar.re then
        local t = frame.healthBar:CreateTexture(nil, "BACKGROUND", nil, -8)
        t:SetTexture(ns.mediapath.."edge_right")
        t:SetSize(64,64)
        t:SetPoint("LEFT", frame.healthBar, "RIGHT", 0, 0)
        t:SetScale(0.25)
        frame.healthBar.re = t
    end

    -- Healthbar Background
    if not frame.healthBar.bg then
        local t = frame.healthBar:CreateTexture(nil, "BACKGROUND", nil, -8)
        t:SetTexture(ns.mediapath.."statusbar_bg")
        t:SetAllPoints()
        t:SetAlpha(0.5)
        t:SetScale(0.25)
        frame.healthBar.bg = t
    end

    -- Name shadow
    if not frame.healthBar.shadow then
        local t = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
        t:SetTexture("Interface\\Common\\NameShadow")
        t:SetPoint("BOTTOM", frame.healthBar, "TOP", 0, -20)
        t:SetSize(256,32)
        t:SetTexCoord(1,1,1,0,0,1,0,0)
        t:SetAlpha(0.5)
        t:SetScale(0.25)
        frame.healthBar.shadow = t
    end

    -- Highlight Frame
    if not frame.healthBar.hlf then
        local f = CreateFrame("Frame", nil, frame.healthBar)
        f:SetAllPoints(frame.healthBar)
        f:SetScale(0.25)
        frame.healthBar.hlf = f
    end

    -- Highlight
    if not frame.healthBar.hl then
        local t = frame.healthBar.hlf:CreateTexture(nil,"BACKGROUND",nil,-7)
        t:SetTexture(ns.mediapath.."statusbar_highlight")
        t:SetPoint("TOP", 50, 0)
        t:SetPoint("LEFT", -30, 0)
        t:SetPoint("RIGHT", 30, 0)
        t:SetPoint("BOTTOM", 40, 0)
        t:SetScale(0.25)
        frame.healthBar.hl = t
    end

    -- Cast Bar (size once; no scaling later)
    local castBar
    if Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then
        castBar = frame.CastBar
    else
        castBar = frame.castBar
    end
    if castBar then
        if GetCVar("namePlateVerticalScale") == "1" then
        castBar:SetStatusBarTexture(ns.mediapath.."statusbar_fill")
        if not frame.__rnp_castSized then
            castBar:SetHeight(11)
            castBar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
            castBar.Icon:SetSize(17,17)
            castBar.Icon:ClearAllPoints()
            castBar.Icon:SetPoint("BOTTOMRIGHT", frame.castBar, "BOTTOMLEFT", -2, 0)
            frame.__rnp_castSized = true
        end
        else
            frame.castBar:SetStatusBarTexture(ns.mediapath.."statusbar_fill")
        end
    end
end)
end

ns:RegisterInit(Init)

-------------------------------------------------
-- Event-driven scaling/visibility (no OnUpdate)
-------------------------------------------------

local tracked = {}  -- [unitToken] = true

local function GetUnitFrameForUnit(unit)
  local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
  if not plate then return nil end
  return plate.UnitFrame or plate
end

local MAX_PLATE_DEBUFFS = 8
local AURA_ICON_SIZE = 14
local AURA_ICON_SPACING = 2

local function EnsureAuraContainer(frame)
  if frame.__rnp_auras then return frame.__rnp_auras end

  local hb = frame.healthBar
  if not hb then return nil end

  local a = CreateFrame("Frame", nil, hb)
  a.__plate = frame
  a:SetPoint("TOP", hb, "BOTTOM", 0, -4)
  a:SetSize((AURA_ICON_SIZE + AURA_ICON_SPACING) * MAX_PLATE_DEBUFFS, AURA_ICON_SIZE)
  a.icons = {}

  for i = 1, MAX_PLATE_DEBUFFS do
    local b = CreateFrame("Frame", nil, a)
    b:EnableMouse(true)
    b:SetScript("OnEnter", function(self)
      local parent = self:GetParent()        -- container
      local plate = parent.__plate
      local unit = plate and (plate.displayedUnit or plate.unit)
      if not unit or not self.auraIndex then return end
    
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetUnitDebuff(unit, self.auraIndex)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function()
      GameTooltip:Hide()
    end)
    b:SetSize(AURA_ICON_SIZE, AURA_ICON_SIZE)

    if i == 1 then
      b:SetPoint("LEFT", a, "LEFT", 0, 0)
    else
      b:SetPoint("LEFT", a.icons[i-1], "RIGHT", AURA_ICON_SPACING, 0)
    end

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetDrawLayer("BACKGROUND", 0)
    b.icon:SetAllPoints()
    b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    b.count = b:CreateFontString(nil, "OVERLAY")
    b.count:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, -1)
    b.count:SetFontObject(NumberFontNormalSmall)

    b.cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
    b.cd:SetFrameLevel(b:GetFrameLevel() + 5)
    b.cd:SetDrawSwipe(true)          -- the darkening “pie wipe”
    b.cd:SetSwipeColor(0, 0, 0, 0.75) -- darkness/opacity
    b.cd:SetDrawEdge(true)           -- bright edge ring
    b.cd:SetHideCountdownNumbers(true) -- optional: hide numbers if you prefer clean icons
    b.cd:SetAllPoints()
    if b.cd.SetReverse then
      b.cd:SetReverse(true)
    else
      b.cd.reverse = true
    end

    b:Hide()
    a.icons[i] = b
  end

  frame.__rnp_auras = a
  return a
end

local function ClearAuraIcons(container)
  if not container or not container.icons then return end
  for i = 1, #container.icons do
    container.icons[i]:Hide()
    container.icons[i].auraIndex = nil
  end
end

local function UpdateNameplateDebuffs(frame)
  if not frame or frame:IsForbidden() then return end

  local unit = frame.displayedUnit or frame.unit
  if not unit or not unit:match("^nameplate") then return end

  local container = EnsureAuraContainer(frame)
  if not container then return end

  -- Optional: hide icons if you’re hiding the HB with Ctrl
  if frame.healthBar and not frame.healthBar:IsShown() then
    container:Hide()
    return
  else
    container:Show()
  end

  ClearAuraIcons(container)

  local shown = 0
  local i = 1

  while shown < MAX_PLATE_DEBUFFS do
    local name, icon, count, debuffType, duration, expirationTime, source, _, _, spellId = UnitDebuff(unit, i)
    if not name then break end

    -- Filter: only show my debuffs (easy + clean)
    if source == "player" then
      shown = shown + 1
      local btn = container.icons[shown]
      btn.auraIndex = i
      btn.icon:SetTexture(icon)

      if count and count > 1 then
        btn.count:SetText(count)
      else
        btn.count:SetText("")
      end

      if duration and duration > 0 and expirationTime then
        local start = expirationTime - duration
        btn.cd:SetCooldown(start, duration)
        btn.cd:Show()
      else
        btn.cd:Hide()
      end

      btn:Show()
    end

    i = i + 1
  end
end

local function IsCastingInterruptible(unit)
  local name, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
  if name then return not notInterruptible end
  local cname, _, _, _, _, _, _, cNotInterruptible = UnitChannelInfo(unit)
  if cname then return not cNotInterruptible end
  return false
end

local function ApplyPlateState(unit)
cfg = ns.cfg.embeds.rNamePlates

  local frame = GetUnitFrameForUnit(unit)
  if not frame or frame:IsForbidden() then return end

  local name = UnitName(unit)
  local ctrl = IsControlKeyDown()

  -- Base state from Ctrl: shrink & hide health when ctrl is held (except Explosives)
  local wantScale = (ctrl and name ~= "Explosives") and 0.1 or 1
  local wantHideHB = (ctrl and name ~= "Explosives")

  -- Casting bump: if interruptible, up to 1.5
  if IsCastingInterruptible(unit) then
    if wantScale < 1.5  and cfg.largeInterruptableCasts then wantScale = 1.5 end
    -- while casting, we still respect wantHideHB: if you prefer always show HB during casts, set wantHideHB=false here
  end

  -- Apply only if different to avoid churn/taint
  if math.abs((frame.__rnp_scale or 1) - wantScale) > 1e-3 then
    frame:SetScale(wantScale)
    frame.__rnp_scale = wantScale
  end

  local hb = frame.healthBar
  if hb then
    local shown = hb:IsShown()
    if wantHideHB and shown then hb:Hide()
    elseif not wantHideHB and not shown then hb:Show() end
  end
end

local function ApplyAllTracked()
  -- defer one frame to stay off Blizzard layout stack
  ns.Scheduler.NextFrame(function()
    for unit in pairs(tracked) do
      ApplyPlateState(unit)
    end
  end)
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("NAME_PLATE_UNIT_ADDED")
ev:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
ev:RegisterEvent("MODIFIER_STATE_CHANGED")
ev:RegisterEvent("UNIT_SPELLCAST_START")
ev:RegisterEvent("UNIT_SPELLCAST_STOP")
ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
ev:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
ev:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
ev:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")
ev:RegisterEvent("UNIT_AURA")

ev:SetScript("OnEvent", function(_, event, arg1, arg2)
  if event == "NAME_PLATE_UNIT_ADDED" then
    local unit = arg1
    tracked[unit] = true

    -- one-shot special cases
    local f = GetUnitFrameForUnit(unit)
    if f and not f:IsForbidden() and UnitName(unit) == "Swarm Training Dummy" then
      f:SetFrameStrata("TOOLTIP")
    end

    ApplyPlateState(unit)
    
    local unit = arg1
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        local frame = plate and (plate.UnitFrame or plate)
        if frame then
          EnsureAuraContainer(frame)
          UpdateNameplateDebuffs(frame)
        end

  elseif event == "UNIT_AURA" then
      local unit = arg1
      if unit and unit:match("^nameplate") then
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        local frame = plate and (plate.UnitFrame or plate)
        if frame then UpdateNameplateDebuffs(frame) end
      end
      
  elseif event == "NAME_PLATE_UNIT_REMOVED" then
    tracked[arg1] = nil

  elseif event == "MODIFIER_STATE_CHANGED" then
    -- ctrl/shift/alt toggled: recompute all
    ApplyAllTracked()

  else
    -- spellcast events: only care about nameplates we track
    local unit = arg1
    if tracked[unit] then
      ApplyPlateState(unit)
    end
  end
end)

local function Clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end

local function ApplyThreatTint(frame)
  if not frame or frame:IsForbidden() then return end

  local unit = frame.displayedUnit or frame.unit
  if not unit or not unit:match("^nameplate") then return end

  local hb = frame.healthBar
  if not hb then return end

  -- threatPct is what we want for a gradient (0-100).
  -- It can be nil if the game hasn't computed threat for this unit yet.
  local _, _, threatPct = UnitDetailedThreatSituation("player", unit)

  if not threatPct then
    -- No data: let Blizzard handle default (red for hostile, etc.)
    return
  end

  -- 0% -> red, 100% -> green
  local t = Clamp01(threatPct / 100)
  local r = 1 - t
  local g = t
  local b = 0

  hb:SetStatusBarColor(r, g, b, 1)

  -- Optional: if your client/build uses barTexture vertex colors visibly
  if hb.barTexture then
    hb.barTexture:SetVertexColor(r, g, b, 0.9)
  end

  -- Optional: border tint too (usually looks nice if you have one)
  if hb.border then
    hb.border:SetVertexColor(r, g, b, 0.8)
  end
end


hooksecurefunc("CompactUnitFrame_UpdateHealthBorder", ApplyThreatTint)

-- This is the key anti-flicker hook:
hooksecurefunc("CompactUnitFrame_UpdateHealth", ApplyThreatTint)

-- Some clients do color in this function instead (safe to hook both):
if CompactUnitFrame_UpdateHealthColor then
  hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ApplyThreatTint)
end

-- Optional: threat can change without health changing (esp. multi-mob)
local evThreat = CreateFrame("Frame")
evThreat:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
evThreat:RegisterEvent("UNIT_THREAT_LIST_UPDATE")

evThreat:SetScript("OnEvent", function(_, _, unit)
  if unit and unit:match("^nameplate") then
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and (plate.UnitFrame or plate)
    if frame then ApplyThreatTint(frame) end
  end
end)

local configs = {
    largeInterruptableCasts = {
        type = "toggle",
        name = "Enlarge Casting Bars",
        desc = "Will enlarge enemy castbars on the nameplates, as well as the nameplate as a whole, while the enemy is casting an interruptable spell.",
        get = function()
            return Roth_UI.db.profile.embeds.rNamePlates.largeInterruptableCasts
        end,
        set = function(_,v)
            Roth_UI.db.profile.embeds.rNamePlates.largeInterruptableCasts = v
        end,
    },
}

Roth_UI:AddConfig("embeds.rNamePlates", configs, "Nameplates", true)