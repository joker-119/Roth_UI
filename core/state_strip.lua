-- Roth_UI/core/state_strip.lua
-- Minimal "important-now" State Strip
-- - User-defined tracked buffs/debuffs with per-aura threshold + showFull
-- - Missing tracked buff alerts (per-aura toggle, desaturated icon, tooltip uses name)
-- - Debuff type alerts (Magic/Curse/Poison/Disease)
-- - Durability low
-- - Weapon enchant missing
-- - Max resource warning (non-mana; disabled; threshold 80-100)
-- - Test harness (/roth ss test ...) with auto-clear
-- - Priority ordering via db.priority (string->number, lower = higher priority)
-- - Subtle "new icon" attention pulse
-- - IMPORTANT: runs a lightweight periodic refresh ONLY when time-sensitive signals exist
--   (fixes per-aura threshold “never shows” due to UNIT_AURA not ticking as time passes)

local addon, ns = ...
ns.StateStrip = ns.StateStrip or {}
local StateStrip = ns.StateStrip

local Scheduler = ns.Scheduler

local f
local buttons = {}

local testMode = nil -- string key, or nil
local testClearToken = 0

local lastKeys = {}
local enteringWorldAt = 0

-- periodic refresh handle
local cancelTicker = nil

local ICON_LOW_HEALTH   = "Interface\\Icons\\Spell_Holy_SealOfSacrifice"
local ICON_LOW_MANA     = "Interface\\Icons\\Spell_Nature_ManaRegenTotem"
local ICON_DURABILITY   = "Interface\\Icons\\INV_Hammer_20"
local ICON_WEAPON       = "Interface\\Icons\\INV_Sword_04"
local ICON_RESOURCE     = "Interface\\Icons\\INV_Misc_QuestionMark"
local ICON_TEST         = "Interface\\Icons\\INV_Misc_QuestionMark"

local DEBUFF_TYPE_ICON = {
  Magic   = "Interface\\Icons\\Spell_Nature_EnchantArmor",
  Curse   = "Interface\\Icons\\Spell_Shadow_AntiShadow",
  Poison  = "Interface\\Icons\\Ability_Rogue_DualWeild",
  Disease = "Interface\\Icons\\Spell_Nature_NullifyDisease",
}

local unlockSizeW, unlockSizeH

-- ------------------------------------------------------------
-- Roth D3 Minimal icon skin (State Strip local version)
-- Uses existing Roth_UI textures:
--  - simplesquare_roth
--  - simplesquare_glow
-- -----------------------------------------------------------

local function GetDB()
  local p = ns.db and ns.db.profile
  if not p then return nil end
  return p.stateStrip or (p.embeds and p.embeds.stateStrip)
end

local function GetUnlockFootprint()
  local db = GetDB()
  if not db then return 260, 20 end -- safe fallback
  local size = tonumber(db.iconSize) or 20
  local spacing = tonumber(db.spacing) or 4
  local maxIcons = tonumber(db.maxIcons) or 8
  local w = (maxIcons * size) + ((maxIcons - 1) * spacing)
  return w, size
end

local function NormalizeKey(v)
  if v == nil then return nil end
  if type(v) == "number" then return tostring(v) end
  v = tostring(v)
  v = v:gsub("^%s+", ""):gsub("%s+$", "")
  if v == "" then return nil end
  local n = tonumber(v)
  if n and n > 0 then return tostring(math.floor(n)) end
  return v:lower()
end

local function Trim(s)
  if not s then return nil end
  s = tostring(s)
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s ~= "" and s or nil
end

local function ResolveSpellNameFromKey(key)
  local n = tonumber(key)
  if n and GetSpellInfo then
    local name = GetSpellInfo(n)
    if name then return name end
  end
  return nil
end

local function GetTrackedDisplayName(key, entry)
  if entry and entry.displayName and entry.displayName ~= "" then
    return entry.displayName
  end
  return ResolveSpellNameFromKey(key) or tostring(key)
end

local function EnsureTables(db)
  db.track = db.track or {}
  db.track.buffs = db.track.buffs or {}
  db.track.debuffs = db.track.debuffs or {}

  db.signals = db.signals or {}
  if db.signals.trackedBuffs == nil then db.signals.trackedBuffs = true end
  if db.signals.trackedDebuffs == nil then db.signals.trackedDebuffs = true end
  if db.signals.lowHealth == nil then db.signals.lowHealth = true end
  if db.signals.lowMana == nil then db.signals.lowMana = true end

  -- New signals
  if db.signals.missingBuffs == nil then db.signals.missingBuffs = true end
  if db.signals.debuffTypes == nil then db.signals.debuffTypes = true end
  if db.signals.durabilityLow == nil then db.signals.durabilityLow = true end
  if db.signals.weaponEnchant == nil then db.signals.weaponEnchant = false end
  if db.signals.weaponEnchantOOCOnly == nil then db.signals.weaponEnchantOOCOnly = true end

  if db.signals.maxResource == nil then db.signals.maxResource = false end
  if db.maxResourcePct == nil then db.maxResourcePct = 90 end -- 80-100 in config

  -- Debuff type toggles
  db.debuffType = db.debuffType or {}
  if db.debuffType.magic == nil then db.debuffType.magic = true end
  if db.debuffType.curse == nil then db.debuffType.curse = true end
  if db.debuffType.poison == nil then db.debuffType.poison = true end
  if db.debuffType.disease == nil then db.debuffType.disease = true end

  -- Missing buff grace
  if db.missingGraceSeconds == nil then db.missingGraceSeconds = 5 end

  -- Priority map: lower number = higher priority (string keys only)
  db.priority = db.priority or {
    cc             = 10, -- future
    debuffTypes    = 15,
    trackedDebuffs = 20,
    expiringBuffs  = 30,
    missingBuffs   = 40,
    durabilityLow  = 45,
    lowHealth      = 50,
    lowMana        = 60,
    weaponEnchant  = 70,
    maxResource    = 80,
  }

  if db.testAutoClear == nil then db.testAutoClear = true end
  if db.testAutoClearSeconds == nil then db.testAutoClearSeconds = 10 end

  if db.iconSize == nil then db.iconSize = 20 end
  if db.spacing == nil then db.spacing = 4 end
  if db.maxIcons == nil then db.maxIcons = 8 end
  if db.expiringThreshold == nil then db.expiringThreshold = 12 end
  if db.lowHealthPct == nil then db.lowHealthPct = 35 end
  if db.lowManaPct == nil then db.lowManaPct = 15 end
  if db.durabilityPct == nil then db.durabilityPct = 20 end

  if db.hideWhenEmpty == nil then db.hideWhenEmpty = true end
  if db.activeAlpha == nil then db.activeAlpha = 1 end
  if db.inactiveAlpha == nil then db.inactiveAlpha = 0 end
end

-- Returns entryTable, keyUsed
local function GetTrackEntry(db, bucket, name, spellId)
  local t = db.track and db.track[bucket]
  if not t then return nil end

  if spellId then
    local k = NormalizeKey(spellId)
    local e = k and t[k]
    if e then return e, k end
  end

  if name then
    local k = NormalizeKey(name)
    local e = k and t[k]
    if e then return e, k end
  end

  return nil
end

local function GetTrackedBuffIcon(key)
  local n = tonumber(key)
  if n and GetSpellInfo then
    local _, _, icon = GetSpellInfo(n)
    if icon then return icon end
  end
  return ICON_TEST
end

-- Cross-client “remaining” helper
local function AuraRemaining(duration, expires)
  duration = tonumber(duration) or 0
  expires  = tonumber(expires) or 0
  if expires <= 0 then return 0 end

  local now = GetTime and GetTime() or 0
  if duration > 0 and expires <= (duration + 0.25) then
    return expires -- looks like “time left”
  end
  return expires - now -- looks like expirationTime
end

local function InMissingGrace(db)
  local g = tonumber(db.missingGraceSeconds) or 0
  if g <= 0 then return false end
  if enteringWorldAt <= 0 then return false end
  return (GetTime() - enteringWorldAt) < g
end

local function GetLowestDurabilityPct()
  if not GetInventoryItemDurability then return nil end
  local lowest
  for slot = 1, 18 do
    local cur, max = GetInventoryItemDurability(slot)
    if cur and max and max > 0 then
      local pct = (cur / max) * 100
      if not lowest or pct < lowest then
        lowest = pct
      end
    end
  end
  return lowest
end

local function WeaponEnchantStatus()
  if not GetWeaponEnchantInfo then return nil end
  local hasMH, _, _, hasOH = GetWeaponEnchantInfo()
  return hasMH, hasOH
end

local function StopTicker()
  if not cancelTicker then return end
  local t = cancelTicker
  cancelTicker = nil
  -- Scheduler.Every likely returns a cancel func, but support ticker objects too
  if type(t) == "function" then
    t()
  elseif type(t) == "table" and t.Cancel then
    t:Cancel()
  elseif type(t) == "table" and t.cancel then
    t:cancel()
  end
end

local function HasTimeSensitiveTracking(db)
  -- Any expiring-buff logic needs time-based updates to catch narrow windows.
  local tb = db.track and db.track.buffs
  if tb then
    for _, e in pairs(tb) do
      if type(e) == "table" and e.enabled ~= false and e.showFull ~= true then
        return true
      end
    end
  end

  -- Debuff type alerts show cooldown spirals and should tick.
  if db.signals and db.signals.debuffTypes then
    return true
  end

  -- Tracked debuffs can be threshold-based if threshold > 0.
  local td = db.track and db.track.debuffs
  if td then
    for _, e in pairs(td) do
      if type(e) == "table" and e.enabled ~= false and e.showFull ~= true then
        local th = tonumber(e.threshold) or 0
        if th > 0 then
          return true
        end
      end
    end
  end

  -- Tests should also tick.
  if type(testMode) == "string" and testMode ~= "clear" then
    return true
  end

  return false
end

local function UpdateTicker(db)
  local need = HasTimeSensitiveTracking(db)
  if need and not cancelTicker then
    if Scheduler and type(Scheduler.Every) == "function" then
      cancelTicker = Scheduler.Every(0.2, function()
        StateStrip.RequestUpdate()
      end)
    elseif C_Timer and C_Timer.NewTicker then
      local ticker = C_Timer.NewTicker(0.2, function()
        StateStrip.RequestUpdate()
      end)
      cancelTicker = ticker
    end
  elseif (not need) and cancelTicker then
    StopTicker()
  end
end

local function AcquireButton(i)
  local b = buttons[i]
  if b then return b end

  b = CreateFrame("Button", nil, f)
  b:SetSize(20, 20)

  b.icon = b:CreateTexture(nil, "ARTWORK")
  -- Don't SetAllPoints here; skin function will inset + crop
  ns.SkinIconMinimal(b, b.icon, { inset = 2, bgAlpha = 0.55, crop = 0.07 })

  b.count = b:CreateFontString(nil, "OVERLAY")
  b.count:SetPoint("BOTTOMRIGHT", 1, 0)
  b.count:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
  b.count:SetJustifyH("RIGHT")

  local cd = CreateFrame("Cooldown", nil, b, "CooldownFrameTemplate")
  cd:SetAllPoints()
  b.cd = cd
  if cd.SetReverse then
    cd:SetReverse(true) -- darken spiral
  end

  -- Attention cue: reuse Roth minimal glow layer created by SkinIconMinimal
  b.glow = b._rothGlow

  b.anim = b:CreateAnimationGroup()

  local s1 = b.anim:CreateAnimation("Scale")
  s1:SetOrder(1)
  s1:SetDuration(0.12)
  s1:SetScale(1.25, 1.25)

  local s2 = b.anim:CreateAnimation("Scale")
  s2:SetOrder(2)
  s2:SetDuration(0.18)
  s2:SetScale(0.8, 0.8)

  local a1 = b.anim:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetDuration(0.10)
  a1:SetFromAlpha(0)
  a1:SetToAlpha(0.6)
  a1:SetTarget(b.glow)

  local a2 = b.anim:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetDuration(0.20)
  a2:SetFromAlpha(0.6)
  a2:SetToAlpha(0)
  a2:SetTarget(b.glow)

  b.anim:SetScript("OnFinished", function()
    b.glow:SetAlpha(0)
    b:SetScale(1)
  end)

  b:SetFrameLevel((f:GetFrameLevel() or 0) + 10)

  b:SetScript("OnEnter", function(self)
    if self.tooltipUnit and self.tooltipIndex and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetUnitAura(self.tooltipUnit, self.tooltipIndex, self.tooltipFilter)
      GameTooltip:Show()
    elseif self.tooltipText and GameTooltip then
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:AddLine(self.tooltipText, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function()
    if GameTooltip then GameTooltip:Hide() end
  end)

  buttons[i] = b
  return b
end

local function ReleaseUnused(from)
  for i = from, #buttons do
    local b = buttons[i]
    if b then
      b:Hide()
      b.tooltipUnit, b.tooltipIndex, b.tooltipFilter, b.tooltipText = nil, nil, nil, nil
      b.cd:Clear()
      if b.glow then b.glow:SetAlpha(0) end
      b:SetScale(1)
      if b.icon.SetDesaturated then b.icon:SetDesaturated(false) end
    end
  end
end

local function Layout(count)
  local db = GetDB()
  if not db then return end

  local size = tonumber(db.iconSize) or 20
  local spacing = tonumber(db.spacing) or 4

  local width = 0
  if count > 0 then
    width = (count * size) + ((count - 1) * spacing)
  end

  if f.dragframe and f.dragframe:IsShown() then
    local w, h = GetUnlockFootprint()
    f:SetSize(w, h)
  else
    f:SetSize(math.max(1, width), size)
  end

  for i = 1, count do
    local b = AcquireButton(i)
    b:SetSize(size, size)
    b:ClearAllPoints()

    if i == 1 then
      b:SetPoint("LEFT", f, "LEFT", 0, 0)
    else
      b:SetPoint("LEFT", buttons[i - 1], "RIGHT", spacing, 0)
    end
  end
end

local function AddEntry(list, e)
  list[#list + 1] = e
end

local entries = {}

local function BuildEntries(entriesOut)
  local db = GetDB()
  if not db then return end
  EnsureTables(db)

  wipe(entriesOut)

  -- Test mode
  if type(testMode) == "string" then
    if testMode == "clear" then
      testMode = nil
      return
    end

    local now = GetTime()
    if testMode == "all" or testMode == "buff" then
      AddEntry(entriesOut, { kind="expiringBuffs", spellId=0, icon=ICON_TEST, count=0, duration=30, expires=now+18, tooltipText="[Test] Expiring Buff" })
      AddEntry(entriesOut, { kind="missingBuffs", spellId=0, icon=ICON_TEST, desaturate=true, count=0, duration=0, expires=0, tooltipText="[Test] Missing Tracked Buff" })
    end
    if testMode == "all" or testMode == "debuff" then
      AddEntry(entriesOut, { kind="trackedDebuffs", spellId=0, icon=ICON_TEST, count=2, duration=12, expires=now+7, tooltipText="[Test] Tracked Debuff" })
      AddEntry(entriesOut, { kind="debuffTypes", spellId=0, icon=DEBUFF_TYPE_ICON.Magic, count=0, duration=10, expires=now+6, tooltipText="[Test] Magic Debuff" })
    end
    if testMode == "all" or testMode == "lowhp" then
      AddEntry(entriesOut, { kind="lowHealth", spellId=0, icon=ICON_LOW_HEALTH, count=0, duration=0, expires=0, tooltipText="[Test] Low Health" })
    end
    if testMode == "all" or testMode == "lowmana" then
      AddEntry(entriesOut, { kind="lowMana", spellId=0, icon=ICON_LOW_MANA, count=0, duration=0, expires=0, tooltipText="[Test] Low Mana" })
    end
    if testMode == "all" then
      AddEntry(entriesOut, { kind="durabilityLow", spellId=0, icon=ICON_DURABILITY, count=0, duration=0, expires=0, tooltipText="[Test] Low Durability" })
      AddEntry(entriesOut, { kind="weaponEnchant", spellId=0, icon=ICON_WEAPON, count=0, duration=0, expires=0, tooltipText="[Test] Missing Weapon Enchant" })
      AddEntry(entriesOut, { kind="maxResource", spellId=0, icon=ICON_RESOURCE, count=0, duration=0, expires=0, tooltipText="[Test] High Resource" })
    end
    return
  end

  local maxIcons = tonumber(db.maxIcons) or 8

  -- Low health
  if db.signals.lowHealth and UnitHealthMax and UnitHealth then
    local hpMax = UnitHealthMax("player") or 0
    if hpMax > 0 then
      local pct = (UnitHealth("player") or 0) / hpMax * 100
      if pct <= (tonumber(db.lowHealthPct) or 35) then
        AddEntry(entriesOut, { kind="lowHealth", spellId=0, icon=ICON_LOW_HEALTH, count=0, duration=0, expires=0, tooltipText=("Low Health: %d%%"):format(pct) })
      end
    end
  end

  -- Low mana (mana users)
  if db.signals.lowMana and UnitPowerType and UnitPowerMax and UnitPower then
    if UnitPowerType("player") == 0 then
      local pMax = UnitPowerMax("player") or 0
      if pMax > 0 then
        local pct = (UnitPower("player") or 0) / pMax * 100
        if pct <= (tonumber(db.lowManaPct) or 15) then
          AddEntry(entriesOut, { kind="lowMana", spellId=0, icon=ICON_LOW_MANA, count=0, duration=0, expires=0, tooltipText=("Low Mana: %d%%"):format(pct) })
        end
      end
    end
  end

  -- Max resource warning (non-mana)
  if db.signals.maxResource and UnitPowerType and UnitPowerMax and UnitPower then
    local pType, token = UnitPowerType("player")
    if pType and pType ~= 0 then
      local pMax = UnitPowerMax("player") or 0
      if pMax > 0 then
        local pct = (UnitPower("player") or 0) / pMax * 100
        local th = tonumber(db.maxResourcePct) or 90
        if th < 80 then th = 80 end
        if th > 100 then th = 100 end
        if pct >= th then
          AddEntry(entriesOut, {
            kind="maxResource",
            spellId=0,
            icon=ICON_RESOURCE,
            count=0,
            duration=0,
            expires=0,
            tooltipText=("High %s: %d%%"):format(tostring(token or "Resource"), pct),
          })
        end
      end
    end
  end

  -- Durability low
  if db.signals.durabilityLow then
    local lowest = GetLowestDurabilityPct()
    if lowest and lowest <= (tonumber(db.durabilityPct) or 20) then
      AddEntry(entriesOut, {
        kind="durabilityLow",
        spellId=0,
        icon=ICON_DURABILITY,
        count=0,
        duration=0,
        expires=0,
        tooltipText=("Low Durability: %d%%"):format(lowest),
      })
    end
  end

  -- Weapon enchant missing
  if db.signals.weaponEnchant then
    if not (db.signals.weaponEnchantOOCOnly and InCombatLockdown and InCombatLockdown()) then
      local hasMH, hasOH = WeaponEnchantStatus()
      if hasMH ~= nil then
        local missMH = not hasMH
        local missOH = (GetInventoryItemID and GetInventoryItemID("player", 17)) and (not hasOH) or false
        if missMH or missOH then
          local which = missMH and missOH and "Mainhand & Offhand" or (missMH and "Mainhand" or "Offhand")
          AddEntry(entriesOut, {
            kind="weaponEnchant",
            spellId=0,
            icon=ICON_WEAPON,
            count=0,
            duration=0,
            expires=0,
            tooltipText=("Missing Weapon Enchant: %s"):format(which),
          })
        end
      end
    end
  end

  ----------------------------------------------------------------
  -- Aura scan pass
  ----------------------------------------------------------------
  local foundTrackedBuff = {} -- key -> true

  -- Tracked buffs (expiring/showFull)
  if db.signals.trackedBuffs and UnitAura then
    local i = 1
    while true do
      local name, icon, count, _, duration, expires, _, _, _, spellId = UnitAura("player", i, "HELPFUL")
      if not name then break end

      local entry, key = GetTrackEntry(db, "buffs", name, spellId)
      if entry and entry.enabled ~= false then
        foundTrackedBuff[key] = true

        local showFull = entry.showFull == true
        local remaining = AuraRemaining(duration, expires)

        if showFull then
          AddEntry(entriesOut, {
            kind="expiringBuffs",
            spellId=spellId,
            icon=icon,
            count=count or 0,
            duration=duration or 0,
            expires=expires or 0,
            unit="player",
            index=i,
            filter="HELPFUL",
          })
        else
          local th = tonumber(entry.threshold) or 0
          if th <= 0 then th = tonumber(db.expiringThreshold) or 12 end
          if remaining <= th then
            AddEntry(entriesOut, {
              kind="expiringBuffs",
              spellId=spellId,
              icon=icon,
              count=count or 0,
              duration=duration or 0,
              expires=expires or 0,
              unit="player",
              index=i,
              filter="HELPFUL",
            })
          end
        end
      end

      i = i + 1
      if #entriesOut >= maxIcons then break end
    end
  end

  -- Missing tracked buffs (per-buff toggle)
  if db.signals.missingBuffs and not InMissingGrace(db) then
    local t = db.track and db.track.buffs
    if t then
      for key, entry in pairs(t) do
        if type(entry) == "table" and entry.enabled ~= false and entry.alertMissing == true then
          if not foundTrackedBuff[key] then
            AddEntry(entriesOut, {
              kind="missingBuffs",
              spellId=0,
              icon=GetTrackedBuffIcon(key),
              desaturate=true,
              count=0,
              duration=0,
              expires=0,
              tooltipText=("Missing Buff: %s"):format(GetTrackedDisplayName(key, entry)),
            })
            if #entriesOut >= maxIcons then break end
          end
        end
      end
    end
  end

  -- Debuff type alerts + tracked debuffs
  if UnitAura and (#entriesOut < maxIcons) and (db.signals.debuffTypes or db.signals.trackedDebuffs) then
    local i = 1
    local typeAdded = {} -- only 1 per type

    while true do
      local name, icon, count, debuffType, duration, expires, _, _, _, spellId = UnitAura("player", i, "HARMFUL")
      if not name then break end

      -- Debuff type alerts
      if db.signals.debuffTypes and debuffType then
        local want =
          (debuffType == "Magic" and db.debuffType.magic) or
          (debuffType == "Curse" and db.debuffType.curse) or
          (debuffType == "Poison" and db.debuffType.poison) or
          (debuffType == "Disease" and db.debuffType.disease)

        if want and not typeAdded[debuffType] then
          typeAdded[debuffType] = true
          AddEntry(entriesOut, {
            kind="debuffTypes",
            spellId=spellId,
            icon=DEBUFF_TYPE_ICON[debuffType] or icon,
            count=count or 0,
            duration=duration or 0,
            expires=expires or 0,
            unit="player",
            index=i,
            filter="HARMFUL",
            tooltipText=("Debuff (%s): %s"):format(debuffType, name),
          })
          if #entriesOut >= maxIcons then break end
        end
      end

      -- Tracked debuffs
      if db.signals.trackedDebuffs and #entriesOut < maxIcons then
        local entry = GetTrackEntry(db, "debuffs", name, spellId)
        if entry and entry.enabled ~= false then
          local remaining = AuraRemaining(duration, expires)
          local showAlways = entry.showFull == true

          if showAlways then
            AddEntry(entriesOut, {
              kind="trackedDebuffs",
              spellId=spellId,
              icon=icon,
              count=count or 0,
              duration=duration or 0,
              expires=expires or 0,
              unit="player",
              index=i,
              filter="HARMFUL",
            })
          else
            local th = tonumber(entry.threshold) or 0
            if th <= 0 then
              AddEntry(entriesOut, {
                kind="trackedDebuffs",
                spellId=spellId,
                icon=icon,
                count=count or 0,
                duration=duration or 0,
                expires=expires or 0,
                unit="player",
                index=i,
                filter="HARMFUL",
              })
            else
              if remaining <= th then
                AddEntry(entriesOut, {
                  kind="trackedDebuffs",
                  spellId=spellId,
                  icon=icon,
                  count=count or 0,
                  duration=duration or 0,
                  expires=expires or 0,
                  unit="player",
                  index=i,
                  filter="HARMFUL",
                })
              end
            end
          end

          if #entriesOut >= maxIcons then break end
        end
      end

      i = i + 1
      if #entriesOut >= maxIcons then break end
    end
  end
end

local function Apply()
  local db = GetDB()
  if not db or db.enabled == false or not f then
    StopTicker()
    return
  end
  EnsureTables(db)

  -- IMPORTANT: keep ticker running only when needed (fixes per-aura threshold windows)
  UpdateTicker(db)

  BuildEntries(entries)

  table.sort(entries, function(a, b)
    local pa = (db.priority and db.priority[a.kind]) or 999
    local pb = (db.priority and db.priority[b.kind]) or 999
    if pa ~= pb then return pa < pb end

    local ea = (a.expires and a.expires > 0) and a.expires or 1e9
    local eb = (b.expires and b.expires > 0) and b.expires or 1e9
    if ea ~= eb then return ea < eb end

    return tostring(a.spellId or 0) < tostring(b.spellId or 0)
  end)

  local count = math.min(#entries, tonumber(db.maxIcons) or 8)
  f._lastCount = count

  for i = 1, count do
    AcquireButton(i)
  end

  Layout(count)

  local currentKeys = {}
  for i = 1, count do
    local e = entries[i]
    local b = buttons[i]

    b:Show()
    b.icon:SetTexture(e.icon or ICON_TEST)
    if b.icon.SetDesaturated then
      b.icon:SetDesaturated(e.desaturate == true)
    end

    b.count:SetText((e.count and e.count > 1) and tostring(e.count) or "")

    if e.duration and e.duration > 0 and e.expires and e.expires > 0 then
      b.cd:SetCooldown(e.expires - e.duration, e.duration)
    else
      b.cd:Clear()
    end

    b.tooltipText = e.tooltipText
    b.tooltipUnit = e.unit
    b.tooltipIndex = e.index
    b.tooltipFilter = e.filter

    local key = ("%s:%s:%s:%s"):format(
      tostring(e.kind or "?"),
      tostring(e.spellId or 0),
      tostring(e.filter or ""),
      tostring(e.tooltipText or "")
    )

    currentKeys[key] = true
    if not lastKeys[key] then
      if b.anim then
        b.anim:Stop()
        b.anim:Play()
      end
    end
  end

  ReleaseUnused(count + 1)

  wipe(lastKeys)
  for k in pairs(currentKeys) do
    lastKeys[k] = true
  end

  local active = (count > 0)
  if db.hideWhenEmpty then
    f:SetShown(active)
  end

  local a = active and (tonumber(db.activeAlpha) or 1) or (tonumber(db.inactiveAlpha) or 0)
  f:SetAlpha(a)

  -- If nothing is time-sensitive and we’re empty, ticker can stop.
  if not HasTimeSensitiveTracking(db) and count == 0 then
    StopTicker()
  end
end

function StateStrip.RequestUpdate()
  if Scheduler and type(Scheduler.Throttle) == "function" then
    Scheduler.Throttle("state_strip_update", 0.05, Apply)
  else
    Apply()
  end
end

function StateStrip.SetTestMode(a, b)
  local mode = (type(a) == "table") and b or a
  testMode = mode
  StateStrip.RequestUpdate()

  local db = GetDB()
  if not db then return end
  EnsureTables(db)
  UpdateTicker(db)

  if type(testMode) == "string" and testMode ~= "clear"
     and db.testAutoClear and C_Timer and C_Timer.After then
    testClearToken = testClearToken + 1
    local token = testClearToken
    local seconds = tonumber(db.testAutoClearSeconds) or 10
    C_Timer.After(seconds, function()
      if token == testClearToken and testMode == mode then
        testMode = nil
        StateStrip.RequestUpdate()
      end
    end)
  end
end

-- Track entries are tables
-- buffs: { enabled=true, threshold=0, showFull=false, alertMissing=false, displayName="..." }
-- debuffs: { enabled=true, threshold=0, showFull=false }
function StateStrip.AddTracked(a, b, c)
  local bucket, value = (type(a) == "table") and b or a, (type(a) == "table") and c or b
  local db = GetDB()
  if not db then return false, "DB not ready" end
  EnsureTables(db)

  local k = NormalizeKey(value)
  if not k then return false, "Invalid" end

  db.track[bucket] = db.track[bucket] or {}

  if type(db.track[bucket][k]) ~= "table" then
    if bucket == "buffs" then
      local disp = ResolveSpellNameFromKey(k) or Trim(value) or tostring(k)
      db.track[bucket][k] = {
        enabled = true,
        threshold = 0,
        showFull = false,
        alertMissing = false,
        displayName = disp,
      }
    else
      db.track[bucket][k] = { enabled = true, threshold = 0, showFull = false }
    end
  else
    db.track[bucket][k].enabled = true
    if bucket == "buffs" then
      local e = db.track[bucket][k]
      if e.alertMissing == nil then e.alertMissing = false end
      if not e.displayName or e.displayName == "" then
        e.displayName = ResolveSpellNameFromKey(k) or Trim(value) or tostring(k)
      end
    end
  end

  StateStrip.RequestUpdate()
  return true
end

function StateStrip.RemoveTracked(a, b, c)
  local bucket, value = (type(a) == "table") and b or a, (type(a) == "table") and c or b
  local db = GetDB()
  if not db then return false, "DB not ready" end
  EnsureTables(db)

  local k = NormalizeKey(value)
  if not k then return false, "Invalid" end
  if db.track[bucket] then
    db.track[bucket][k] = nil
  end
  StateStrip.RequestUpdate()
  return true
end

function StateStrip.ClearTracked(a, b)
  local bucket = (type(a) == "table") and b or a
  local db = GetDB()
  if not db then return false, "DB not ready" end
  EnsureTables(db)
  db.track[bucket] = {}
  StateStrip.RequestUpdate()
  return true
end

function StateStrip.ListTracked(a, b)
  local bucket = (type(a) == "table") and b or a
  local db = GetDB()
  if not db then return {} end
  EnsureTables(db)
  local out = {}
  local t = db.track[bucket] or {}
  for k in pairs(t) do out[#out + 1] = k end
  table.sort(out)
  return out
end

local function ApplyPosition()
  local db = GetDB()
  if not db or not f then return end
  local p = db.pos or {}
  f:ClearAllPoints()
  if p.af and p.a2 then
    f:SetPoint(p.a1 or "BOTTOM", p.af, p.a2, p.x or 0, p.y or 0)
  elseif p.af then
    f:SetPoint(p.a1 or "BOTTOM", p.af, p.x or 0, p.y or 0)
  else
    f:SetPoint(p.a1 or "BOTTOM", p.x or 0, p.y or 0)
  end
end

local function SavePosition()
    local db = GetDB()
    if not db or not f or not f.GetPoint then return end
    
    local a1, af, a2, x, y = f:GetPoint(1)
    local afName = (type(af) == "table" and af.GetName and af:GetName()) or af or "UIParent"
    
    db.pos = db.pos or {}
    db.pos.a1 = a1 or "BOTTOM"
    db.pos.af = afName or "UIParent"
    db.pos.a2 = a2 or "BOTTOM"
    db.pos.x = x or 0
    db.pos.y = y or 0
end

local function Init()
  local db = GetDB()
  if not db then return end
  EnsureTables(db)

  f = CreateFrame("Frame", "Roth_UIStateStrip", UIParent)
  f:SetFrameStrata("MEDIUM")
  f:SetFrameLevel(10)
  f:SetClampedToScreen(true)
  f:SetMovable(false)
  f:SetSize(1, 1)
  ApplyPosition()
  
  ns.func.applyDragFunctionality(f)
  -- Ensure draggable footprint is visible when unlocked (even if empty)
  if f.dragframe then
    f.dragframe:HookScript("OnShow", function()
      -- alpha fix (you already noticed this)
      f._unlockPrevAlpha = f:GetAlpha()
      f:SetAlpha(1)
      f:Show()
  
      -- size fix (prevents 1px sliver)
      f._unlockPrevW, f._unlockPrevH = f:GetSize()
      unlockSizeW, unlockSizeH = GetUnlockFootprint()
      f:SetSize(unlockSizeW, unlockSizeH)
    end)
  
    f.dragframe:HookScript("OnHide", function()
      -- restore size/alpha; let normal Apply() logic take over
      if f._unlockPrevW and f._unlockPrevH then
        f:SetSize(f._unlockPrevW, f._unlockPrevH)
      end
      if f._unlockPrevAlpha then
        f:SetAlpha(f._unlockPrevAlpha)
      end
      f._unlockPrevAlpha, f._unlockPrevW, f._unlockPrevH = nil, nil, nil
      StateStrip.RequestUpdate()
    end)
  end

  if ns.Visibility and ns.Visibility.Register then
    ns.Visibility.Register("stateStrip", f, {
      name = "State Strip",
      group = "Awareness",
      props = { "shown", "alpha", "scale" },
    })
  end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("UNIT_AURA")
  ev:RegisterEvent("UNIT_HEALTH")
  ev:RegisterEvent("UNIT_MAXHEALTH")
  ev:RegisterEvent("UNIT_POWER_UPDATE")
  ev:RegisterEvent("UNIT_MAXPOWER")
  ev:RegisterEvent("UNIT_DISPLAYPOWER")
  ev:RegisterEvent("UPDATE_INVENTORY_DURABILITY")
  ev:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  ev:RegisterEvent("PLAYER_REGEN_ENABLED")
  ev:RegisterEvent("PLAYER_REGEN_DISABLED")

  ev:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
      enteringWorldAt = GetTime()
    end
    if unit and unit ~= "player" then return end
    StateStrip.RequestUpdate()
  end)

  enteringWorldAt = GetTime()
  StateStrip.RequestUpdate()
end

ns:RegisterInit(Init)