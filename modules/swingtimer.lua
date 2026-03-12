-- modules/swingtimer.lua
-- Roth UI: Dual wield swing timer (MH + OH) with:
--  1) Paladin tick marker at 0.4s before swing
--  2) Dual wield delta readout (ms) showing MH ahead/behind OH
--  3) Paladin "last SoC cast point" marker at 1.6s before swing (GCD+buffer)
--  4) GCD ticker bar (thin) above MH bar showing current GCD progress
--
-- Roth_UI RegisterInit signature in your branch:
--   ns:RegisterInit(func)

local addonName, ns = ...

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function isBoolean(v) return type(v) == "boolean" end

local function clamp01(x)
  if x < 0 then return 0 end
  if x > 1 then return 1 end
  return x
end

local function msAbs(v)
  if not v then return 0 end
  if v < 0 then v = -v end
  return math.floor(v * 1000 + 0.5)
end

-- Many clients append a boolean isOffHand at the end of SWING_* payload.
-- Branches differ; treat last arg as isOffHand if it's boolean.
local function getOffhandFlagFromCLEU(...)
  local n = select("#", ...)
  if n <= 0 then return false end
  local last = select(n, ...)
  if isBoolean(last) then return last end
  return false
end

------------------------------------------------------------
-- Media helpers (Roth style)
------------------------------------------------------------
local function RothTex(name)
  if ns and ns.mediapath then
    return ns.mediapath .. name
  end
  return nil
end

------------------------------------------------------------
-- UI creation
------------------------------------------------------------
local function CreateSwingBar(parent, name, w, h, texturePath, bgAlpha)
  local bar = CreateFrame("StatusBar", name, parent)
  bar:SetSize(w, h)
  bar:SetMinMaxValues(0, 1)
  bar:SetValue(0)

  -- Roth bar textures (nameplate style)
  local fillTex = RothTex("statusbar_fill") or texturePath
  local bgTex   = RothTex("statusbar_bg") or texturePath
  local hlTex   = RothTex("statusbar_highlight")
  local leTex   = RothTex("edge_left")
  local reTex   = RothTex("edge_right")
  local pxTex   = RothTex("Solid") or "Interface\\Buttons\\WHITE8X8"

  bar:SetStatusBarTexture(fillTex)

  -- Warm gold (kept; you can later make this configurable again)
  bar:SetStatusBarColor(0.85, 0.75, 0.30, 1)
  bar:SetStatusBarDesaturated(false)

  -- Background
  local bg = bar:CreateTexture(nil, "BACKGROUND", nil, -8)
  bg:SetAllPoints(bar)
  bg:SetTexture(bgTex)
  bg:SetAlpha(bgAlpha or 0.55)
  bar.bg = bg

  -- Left/Right edge “metal”
  if leTex and not bar.le then
    local t = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
    t:SetTexture(leTex)
    t:SetSize(64, 64)
    t:SetPoint("RIGHT", bar, "LEFT", 0, 0)
    t:SetScale(0.25)
    bar.le = t
  end

  if reTex and not bar.re then
    local t = bar:CreateTexture(nil, "BACKGROUND", nil, -7)
    t:SetTexture(reTex)
    t:SetSize(64, 64)
    t:SetPoint("LEFT", bar, "RIGHT", 0, 0)
    t:SetScale(0.25)
    bar.re = t
  end

  -- Highlight overlay (same logic as nameplates: scaled frame + highlight texture)
  if hlTex and not bar.hl then
    local hlf = CreateFrame("Frame", nil, bar)
    hlf:SetAllPoints(bar)
    hlf:SetScale(0.25)
    bar.hlf = hlf

    local t = hlf:CreateTexture(nil, "BACKGROUND", nil, -6)
    t:SetTexture(hlTex)
    -- These offsets mimic the nameplate highlight “bloom”
    t:SetPoint("TOP", 50, 0)
    t:SetPoint("LEFT", -30, 0)
    t:SetPoint("RIGHT", 30, 0)
    t:SetPoint("BOTTOM", 40, 0)
    t:SetScale(0.25)
    t:SetAlpha(0.9)
    bar.hl = t
  end

  -- Paladin tick marker (last 0.4s)
  local tick = bar:CreateTexture(nil, "OVERLAY", nil, 1)
  tick:SetTexture(pxTex)
  tick:SetSize(2, h + 6)
  tick:SetVertexColor(1, 1, 1, 1)
  tick:SetAlpha(0.9)
  tick:Hide()
  bar.tick = tick

  -- Paladin green marker (last possible SoC cast point ~1.6s before swing)
  local pre = bar:CreateTexture(nil, "OVERLAY", nil, 1)
  pre:SetTexture(pxTex)
  pre:SetSize(2, h + 6)
  pre:SetVertexColor(0.2, 1.0, 0.2, 1)
  pre:SetAlpha(0.9)
  pre:Hide()
  bar.preTick = pre

  return bar
end

------------------------------------------------------------
-- Module init
------------------------------------------------------------
local function Init()
  local cfg = ns.cfg and ns.cfg.units and ns.cfg.units.player and ns.cfg.units.player.swingtimer
  if not cfg or not cfg.show then return end

  local playerClass = select(2, UnitClass("player"))
  local isPaladin = (playerClass == "PALADIN")

  local tickLead = tonumber(cfg.paladinTickSeconds) or 0.4
  local preLead  = 1.6 -- 1.5s GCD + 0.1s safety buffer

  local w       = tonumber(cfg.width) or 240
  local h       = tonumber(cfg.height) or 8
  local spacing = tonumber(cfg.spacing) or 4
  local texture = cfg.texture or (RothTex("statusbar_fill") or "Interface\\TargetingFrame\\UI-StatusBar")
  local bgAlpha = tonumber(cfg.bgAlpha) or 0.6

  -- Fallback spell per class to read GCD from (must be a GCD-locked spell)
  local gcdSpellByClass = {
    WARRIOR = 6673,  -- Battle Shout
    PALADIN = 635,   -- Holy Light
    HUNTER  = 1978,  -- Serpent Sting (learned early; swap if you test lvl 1)
    ROGUE   = 1752,  -- Sinister Strike
    PRIEST  = 585,   -- Smite
    SHAMAN  = 403,   -- Lightning Bolt
    MAGE    = 133,   -- Fireball
    WARLOCK = 686,   -- Shadow Bolt
    DRUID   = 5176,  -- Wrath
  }
  local gcdSpellID = gcdSpellByClass[playerClass]

  local frame = CreateFrame("Frame", "Roth_UISwingTimer", UIParent)
  frame:SetFrameStrata("LOW")
  frame:SetFrameLevel(10)
  frame:SetScale(cfg.scale or 1)
  frame:SetClipsChildren(false)
  frame:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)

  -- Hard size (prevents width=0 rendering issues)
  frame:SetWidth(w)
  frame:SetHeight(h)
  frame:Show()

  if ns.Visibility and ns.Visibility.Register then
    ns.Visibility.Register("swingtimer", frame, {
      name = "Swing Timer",
      group = "Player",
      props = { "shown", "alpha", "scale" },
    })
  end

  if ns.func and ns.func.applyDragFunctionality then
    ns.func.applyDragFunctionality(frame)
  end

  local mh = CreateSwingBar(frame, "Roth_UISwingTimerMH", w, h, texture, bgAlpha)
  mh:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
  mh:Show()

  local oh = CreateSwingBar(frame, "Roth_UISwingTimerOH", w, h, texture, bgAlpha)
  oh:SetPoint("TOPLEFT", mh, "BOTTOMLEFT", 0, -spacing)
  oh:Hide()

  -- GCD ticker bar (thin) above MH, styled with Roth textures
  local gcdBar = CreateFrame("StatusBar", "Roth_UISwingTimerGCD", frame)
  gcdBar:SetSize(w, 3)
  gcdBar:SetPoint("BOTTOMLEFT", mh, "TOPLEFT", 0, 3)
  gcdBar:SetMinMaxValues(0, 1)
  gcdBar:SetValue(0)

  local gcdFillTex = RothTex("statusbar_fill") or "Interface\\TargetingFrame\\UI-StatusBar"
  local gcdBgTex   = RothTex("statusbar_bg") or "Interface\\TargetingFrame\\UI-StatusBar"
  local gcdHlTex   = RothTex("statusbar_highlight")

  gcdBar:SetStatusBarTexture(gcdFillTex)
  gcdBar:SetStatusBarColor(0.85, 0.75, 0.30, 0.95) -- match main bar; subtle

  local gcdBG = gcdBar:CreateTexture(nil, "BACKGROUND", nil, -8)
  gcdBG:SetAllPoints(gcdBar)
  gcdBG:SetTexture(gcdBgTex)
  gcdBG:SetAlpha(0.45)
  gcdBar.bg = gcdBG

  if gcdHlTex then
    local hlf = CreateFrame("Frame", nil, gcdBar)
    hlf:SetAllPoints(gcdBar)
    hlf:SetScale(0.25)
    gcdBar.hlf = hlf

    local t = hlf:CreateTexture(nil, "BACKGROUND", nil, -6)
    t:SetTexture(gcdHlTex)
    t:SetPoint("TOP", 50, 0)
    t:SetPoint("LEFT", -30, 0)
    t:SetPoint("RIGHT", 30, 0)
    t:SetPoint("BOTTOM", 40, 0)
    t:SetScale(0.25)
    t:SetAlpha(0.75)
    gcdBar.hl = t
  end

  gcdBar:Hide()

  -- Delta display (dual wield only)
  local deltaText = frame:CreateFontString(nil, "OVERLAY")
  deltaText:SetPoint("LEFT", mh, "RIGHT", 8, 0)
  deltaText:SetJustifyH("LEFT")
  deltaText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
  deltaText:SetText("")
  deltaText:Hide()

  local function ApplyMedia()
    local texPath = cfg.texture or RothTex("statusbar_fill") or texture

    mh:SetStatusBarTexture(texPath); mh.bg:SetTexture(RothTex("statusbar_bg") or texPath)
    oh:SetStatusBarTexture(texPath); oh.bg:SetTexture(RothTex("statusbar_bg") or texPath)

    gcdBar:SetStatusBarTexture(RothTex("statusbar_fill") or texPath)
    if gcdBar.bg then gcdBar.bg:SetTexture(RothTex("statusbar_bg") or texPath) end

    local font = STANDARD_TEXT_FONT
    if ns.Media and ns.Media.Font then
      local maybe = ns.Media.Font("RothFont", nil)
      if maybe then font = maybe end
    end
    deltaText:SetFont(font, 12, "OUTLINE")
  end

  if ns.ListenForMediaChange then
    ns:ListenForMediaChange(ApplyMedia)
  end
  ApplyMedia()

  ----------------------------------------------------------
  -- State
  ----------------------------------------------------------
  local lastSwing = { MH = nil, OH = nil }
  local nextSwing = { MH = nil, OH = nil }
  local speed     = { MH = 2.0, OH = nil }
  local dualWield = false

  local function FixSizes()
    if frame:GetWidth() < 1 then frame:SetWidth(w) end
    if dualWield then
      frame:SetHeight(h + spacing + h)
    else
      frame:SetHeight(h)
    end
  end

  local function UpdateSpeeds()
    local mhSpd, ohSpd = UnitAttackSpeed("player")
    speed.MH = tonumber(mhSpd) or speed.MH or 2.0
    speed.OH = tonumber(ohSpd)
    dualWield = (speed.OH and speed.OH > 0)

    if dualWield then
      oh:Show()
    else
      oh:Hide()
      deltaText:Hide()
    end

    FixSizes()
  end

  local function SeedIfNeeded(now)
    if not lastSwing.MH then
      lastSwing.MH = now - (speed.MH or 2.0)
      nextSwing.MH = now
    end
    if dualWield and not lastSwing.OH then
      lastSwing.OH = now - (speed.OH or 2.0)
      nextSwing.OH = now
    end
  end

  local function OnSwing(hand, now)
    local spd = (hand == "OH") and (speed.OH or speed.MH) or speed.MH
    lastSwing[hand] = now
    nextSwing[hand] = now + (spd or 2.0)
  end

  ----------------------------------------------------------
  -- Events
  ----------------------------------------------------------
  frame:RegisterEvent("PLAYER_ENTERING_WORLD")
  frame:RegisterEvent("UNIT_ATTACK_SPEED")
  frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
  frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  frame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
      UpdateSpeeds()
      local now = GetTime()
      SeedIfNeeded(now)
      FixSizes()
      return
    end

    if event == "UNIT_ATTACK_SPEED" then
      local unit = ...
      if unit == "player" then UpdateSpeeds() end
      return
    end

    if event == "PLAYER_EQUIPMENT_CHANGED" then
      UpdateSpeeds()
      return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
      local _, subEvent, _, sourceGUID = CombatLogGetCurrentEventInfo()
      if sourceGUID ~= UnitGUID("player") then return end
      if subEvent ~= "SWING_DAMAGE" and subEvent ~= "SWING_MISSED" then return end

      local now = GetTime()
      local isOffHand = getOffhandFlagFromCLEU(CombatLogGetCurrentEventInfo())
      OnSwing(isOffHand and "OH" or "MH", now)
      return
    end
  end)

  ----------------------------------------------------------
  -- OnUpdate
  ----------------------------------------------------------
  local elapsedAccum = 0
  local repairAccum = 0

  frame:SetScript("OnUpdate", function(_, elapsed)
    elapsedAccum = elapsedAccum + elapsed
    repairAccum = repairAccum + elapsed

    if repairAccum >= 0.25 then
      repairAccum = 0
      FixSizes()
    end

    if elapsedAccum < 0.02 then return end
    elapsedAccum = 0

    UpdateSpeeds()
    local now = GetTime()
    SeedIfNeeded(now)

    -- GCD ticker (Classic-safe)
    do
      local start, dur, enabled = GetSpellCooldown(61304)

      if not (enabled == 1 and dur and dur > 0 and dur <= 2.0 and start and start > 0) then
        if gcdSpellID then
          start, dur, enabled = GetSpellCooldown(gcdSpellID)
        end
      end

      if enabled == 1 and start and start > 0 and dur and dur > 0 and dur <= 2.0 then
        local p = (now - start) / dur
        gcdBar:SetValue(clamp01(p))
        gcdBar:Show()
      else
        gcdBar:Hide()
      end
    end

    -- MH
    do
      local dur = speed.MH or 2.0
      local exp = nextSwing.MH or (now + dur)
      local p = 1 - ((exp - now) / dur)
      mh:SetValue(clamp01(p))

      if isPaladin and dur > tickLead then
        local tickPos = clamp01((dur - tickLead) / dur)
        mh.tick:ClearAllPoints()
        mh.tick:SetPoint("CENTER", mh, "LEFT", w * tickPos, 0)
        mh.tick:Show()
      else
        mh.tick:Hide()
      end

      if isPaladin and dur > preLead then
        local prePos = clamp01((dur - preLead) / dur)
        mh.preTick:ClearAllPoints()
        mh.preTick:SetPoint("CENTER", mh, "LEFT", w * prePos, 0)
        mh.preTick:Show()
      else
        mh.preTick:Hide()
      end
    end

    -- OH
    if dualWield then
      local dur = speed.OH or speed.MH or 2.0
      local exp = nextSwing.OH or (now + dur)
      local p = 1 - ((exp - now) / dur)
      oh:SetValue(clamp01(p))

      if isPaladin and dur > tickLead then
        local tickPos = clamp01((dur - tickLead) / dur)
        oh.tick:ClearAllPoints()
        oh.tick:SetPoint("CENTER", oh, "LEFT", w * tickPos, 0)
        oh.tick:Show()
      else
        oh.tick:Hide()
      end

      -- Only show the green "latest SoC cast point" on MH
      oh.preTick:Hide()
    else
      oh.tick:Hide()
      oh.preTick:Hide()
    end

    -- Delta
    if dualWield and cfg.showDualWieldDelta then
      local mhNext = nextSwing.MH
      local ohNext = nextSwing.OH
      if mhNext and ohNext then
        local delta = mhNext - ohNext -- negative => MH earlier
        local ms = msAbs(delta)
        if ms <= 0 then
          deltaText:Hide()
        else
          deltaText:SetText(tostring(ms))
          if delta < 0 then
            deltaText:SetTextColor(0.2, 1.0, 0.2, 1)
          else
            deltaText:SetTextColor(1.0, 0.2, 0.2, 1)
          end
          deltaText:Show()
        end
      else
        deltaText:Hide()
      end
    else
      deltaText:Hide()
    end
  end)
end

ns:RegisterInit(Init)
