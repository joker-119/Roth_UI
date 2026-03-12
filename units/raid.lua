
  --get the addon namespace
  local addon, ns = ...

  --get oUF namespace (just in case needed)
  local oUF = ns.oUF or oUF

  --get the config
  local cfg = ns.cfg

  --get the functions
  local func = ns.func

  --get the unit container
  local unit = ns.unit

  local dragFrameList = ns.dragFrameList
  local whitelist = {}
  local blacklist = {}

  ---------------------------------------------
  -- UNIT SPECIFIC FUNCTIONS
  ---------------------------------------------

  --init parameters
local initUnitParameters = function(self)
  self:EnableMouse(true)
  self:RegisterForClicks("AnyUp")

  self:SetScript("OnEnter", UnitFrame_OnEnter)
  self:SetScript("OnLeave", UnitFrame_OnLeave)

  -- Right-click unit menu (TBC)
  self:SetAttribute("type2", "togglemenu")
end


  --custom aura filter
  local customFilter = function(icons, unit, icon, name, texture, count, dtype, duration, timeLeft, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
    local ret = false
	if(spellID == '25771') then
		ret = true
    elseif isBossDebuff then
		ret = true
	elseif(dtype == 'Magic') then
		ret = true
	elseif(dtype == 'Poison') then
		ret = true
	elseif(dtype == 'Disease') then
		ret = true
	elseif(dtype == 'Curse') then
		ret = true
    elseif isBossDebuff or (caster and caster:match("(boss)%d?$") == "boss")then
		ret = true
	elseif(spellID == '313255') then
		ret = true
	end
	if (whitelist[spellID]) then
		ret = true
	end
    return ret
  end

  --create buffs
  local createBuffs = function(self)
	local f = CreateFrame("Frame", nil, self)
	local cfg = self.cfg.auras
	f.size = cfg.size or 26
	f.num = cfg.num or 5
	f.spacing = cfg.spacing or 5
	f:SetAlpha(0.75)
	f.initialAnchor = cfg.initialAnchor or "TOPLEFT"
	f["growth-x"] = cfg.growthX or "RIGHT"
	f["growth-y"] = cfg.growthY or "DOWN"
	f.disableCooldown = cfg.disableCooldown or false
	--f.showDebuffType = cfg.showDebuffType or false
    f.showBuffType = cfg.showBuffType or false
    f.onlyShowPlayer = cfg.onlyShowPlayer
    f:SetHeight(f.size)
    f:SetWidth((f.size+f.spacing)*f.num)
    if cfg.buffPos then
      f:SetPoint(cfg.buffPos.a1 or "CENTER", self, cfg.buffPos.a2 or "CENTER", cfg.buffPos.x or 0, cfg.buffPos.y or 0)
    else
      f:SetPoint("CENTER",0,-5)
	end
	self.Buffs = f
  end

  --create aura func
  local createDebuffs = function(self)
    local f = CreateFrame("Frame", nil, self)
    local cfg = self.cfg.auras
    f.size = cfg.size or 26
    f.num = cfg.num or 5
    f.spacing = cfg.spacing or 5
    f.initialAnchor = cfg.initialAnchor or "TOPLEFT"
    f["growth-x"] = cfg.growthX or "RIGHT"
    f["growth-y"] = cfg.growthY or "DOWN"
    f.disableCooldown = cfg.disableCooldown or false
    f.disableCooldownText = cfg.disableCooldownText or false
    f.showDebuffType = cfg.showDebuffType or false
    f.showBuffType = cfg.showBuffType or false
    f:SetHeight(f.size)
    f:SetWidth((f.size+f.spacing)*f.num)
    if cfg.debuffPos then
      f:SetPoint(cfg.debuffPos.a1 or "CENTER", self, cfg.debuffPos.a2 or "CENTER", cfg.debuffPos.x or 0, cfg.debuffPos.y or 0)
    else
      f:SetPoint("CENTER",0,-5)
    end
    self.Debuffs = f
  end

  --update health func
  local updateHealth = function(bar, unit, min, max)
    local d = floor(min/max*100)
    local color
    local dead
	local offline

  if unit and UnitIsTapDenied(unit) then
    color = {r = 0.65, g = 0.65, b = 0.65}
  elseif UnitIsDeadOrGhost(unit) then
    color = {r = 0.4, g = 0.4, b = 0.4}
    dead = 1
	elseif not UnitIsConnected(unit) then
		color = {r = 0.4, g = 0.4, b = 0.4}
		offline = 1
  elseif not cfg.colorswitcher.classcolored then
    color = cfg.colorswitcher.bright
  elseif cfg.colorswitcher.threatColored and unit and UnitThreatSituation(unit) == 3 then
    color = { r = 1, g = 0, b = 0, }
  elseif UnitIsPlayer(unit) then
    color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
  else
    color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
  end
  
  if not color then color = { r = 0.5, g = 0.5, b = 0.5, } end
    --dead
    if offline == 1 then
		bar:SetStatusBarColor(0.4, 0.4, 0.4, 0.4)
		bar.glow:SetVertexColor(0, 0, 0, 0)
    else
      --alive
      if cfg.colorswitcher.useBrightForeground then
        bar:SetStatusBarColor(color.r,color.g,color.b,color.a or 1)
        bar.bg:SetVertexColor(cfg.colorswitcher.dark.r,cfg.colorswitcher.dark.g,cfg.colorswitcher.dark.b,cfg.colorswitcher.dark.a)
      else
        bar:SetStatusBarColor(cfg.colorswitcher.dark.r,cfg.colorswitcher.dark.g,cfg.colorswitcher.dark.b,cfg.colorswitcher.dark.a)
        bar.bg:SetVertexColor(color.r,color.g,color.b,color.a or 1)
      end
    end
    --low hp
    if d <= 25 or dead == 1 then
      if cfg.colorswitcher.useBrightForeground then
        bar.glow:SetVertexColor(0.3,0,0,0.9)
        bar:SetStatusBarColor(1,0,0,1)
        bar.bg:SetVertexColor(0.15,0,0,0.7)
      else
        bar.glow:SetVertexColor(1,0,0,1)
      end
    else
      --inner shadow
      --bar.glow:SetVertexColor(0,0,0,0.7)
    end
    bar.highlight:SetAlpha((min/max)*cfg.highlightMultiplier)
  end

  --check threat
  local checkThreat = function(self,event,unit)
    self.Health:ForceUpdate()
  end

  --actionbar background
  local createArtwork = function(self)
    local t = self:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(self)
    t:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget")

    if self.cfg.special.chains then
      local c1 = self:CreateTexture(nil,"BACKGROUND",nil,-7)
      c1:SetTexture("Interface\\AddOns\\Roth_UI\\media\\chain2")
      c1:SetSize(32,32)
      c1:SetPoint("CENTER",-32,28)
      c1:SetAlpha(0.9)
      local c2 = self:CreateTexture(nil,"BACKGROUND",nil,-7)
      c2:SetTexture("Interface\\AddOns\\Roth_UI\\media\\chain2")
      c2:SetSize(32,32)
      c2:SetPoint("CENTER",32,28)
      c2:SetAlpha(0.9)
    end
	self.Texture = t

  end

  --create health frames
  local createHealthFrame = function(self)

    local cfg = self.cfg.health

    --health
    local h = CreateFrame("StatusBar", nil, self)
    h:SetPoint("TOP",0,-27.9)
    h:SetPoint("LEFT",24.5,0)
    h:SetPoint("RIGHT",-24.5,0)
    h:SetPoint("BOTTOM",0,28.7)
	h:SetFrameStrata("BACKGROUND")

    h:SetStatusBarTexture(cfg.texture)
    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"BACKGROUND",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_hpglow")
    h.glow:SetPoint("TOP",0,17)
    h.glow:SetPoint("LEFT",-24,0)
    h.glow:SetPoint("RIGHT",24,0)
    h.glow:SetPoint("BOTTOM",0,-20)
    h.glow:SetVertexColor(0,0,0,1)

    h.highlight = h:CreateTexture(nil,"BACKGROUND",nil,-4)
    h.highlight:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_highlight")
    h.highlight:SetAllPoints(self)

    self.Health = h
    self.Health.Smooth = true
  end

  --create power frames
  local createPowerFrame = function(self)
    local cfg = self.cfg.power

    --power
    local h = CreateFrame("StatusBar", nil, self.Health)
     h:SetPoint("TOP",0,-13)
     h:SetPoint("LEFT",5,0)
     h:SetPoint("RIGHT",-5,0)
     h:SetPoint("BOTTOM",0,-10)

    h:SetStatusBarTexture(cfg.texture)

    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"ARTWORK",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_ppglow")
    h.glow:SetAllPoints(self)
    h.glow:SetVertexColor(0,0,0,1)

    self.Power = h
    self.Power.Smooth = true

  end

  --create health power strings
  local createHealthPowerStrings = function(self)

    local name = func.createFontString(self, cfg.fonts.headerFont, 12, "THINOUTLINE", "OVERLAY")
    name:SetPoint("BOTTOM", self, "TOP", 0, -20)
    name:SetPoint("LEFT", self.Health, 0, 0)
    name:SetPoint("RIGHT", self.Health, 0, 0)
    --name:SetJustifyH("LEFT")
    self.Name = name

    local hpval = func.createFontString(self, cfg.fonts.textFont, 11, "THINOUTLINE", "BACKGROUND")
    hpval:SetPoint("RIGHT", -20,10)

    self:Tag(name, "[diablo:name]")
    self:Tag(hpval, self.cfg.health.tag or "")

  end


  ---------------------------------------------
  -- RAID STYLE FUNC
  ---------------------------------------------

  local function createStyle(self)

    --apply config to self
    self.cfg = cfg.units.raid
    self.cfg.style = "raid"

    --init
    initUnitParameters(self)

    --create the art
    createArtwork(self)

    --createhealthPower
    createHealthFrame(self)
    createPowerFrame(self)

    --health power strings
    createHealthPowerStrings(self)

    --health update
    self.Health.PostUpdate = updateHealth
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", checkThreat)
    self:RegisterEvent("UNIT_AURA", func.checkColors)
    self.Power.PostUpdate = func.updatePower

    --debuffglow
    func.createDebuffGlow(self)

    --range
    self.Range = {
      insideAlpha = 1,
      outsideAlpha = self.cfg.alpha.notinrange
    }

    --auras
    if self.cfg.auras.showBuffs then
	createBuffs(self)
    end

    if self.cfg.auras.showDebuffs then
	createDebuffs(self)
	self.Debuffs.PostCreateIcon = createAuraIcon
    end

    --aurawatch
    if self.cfg.aurawatch.show then
      func.createAuraWatch(self)
    end

    --icons
    self.RaidTargetIndicator = func.createIcon(self,"OVERLAY",14,self.Health,"CENTER","CENTER",0,0,7)
	self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\raidicons")
    self.ReadyCheckIndicator = func.createIcon(self,"OVERLAY",24,self.Health,"CENTER","CENTER",0,0,7)
    self.GroupRoleIndicator = func.createIcon(self,"OVERLAY",14,self.Health,"CENTER","CENTER",0,0,7)
    self.GroupRoleIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\lfd_role")
    self.GroupRoleIndicator:SetDesaturated(1)
	self.LeaderIndicator = func.createIcon(self,"OVERLAY",14,self.Name,"TOPLEFT","TOPLEFT",-7,-10,7)
	self.LeaderIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\leader")

    --add heal prediction
    func.healPrediction(self)
    
    --add total absorb
    func.totalAbsorb(self)

  end

  ---------------------------------------------
  -- SPAWN RAID UNIT
  ---------------------------------------------
local respawnQueued = false
local spawnedRaidGroups = {}
local spawnedRaidDragFrames = {}

local function MakeRaidDragFramePersistent(f, idx)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetClampedToScreen(true)

  f:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end
    self:StartMoving()
  end)

  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    -- Save point into profile by GROUP INDEX (stable key), not frame name
    local a1, af, a2, x, y = self:GetPoint(1)
    local afName = (af and af:GetName()) or "UIParent"

    Roth_UI.db.profile.units.raid.groupPos = Roth_UI.db.profile.units.raid.groupPos or {}
    Roth_UI.db.profile.units.raid.groupPos[idx] = {
      a1 = a1,
      af = afName,
      a2 = a2,
      x  = x,
      y  = y,
    }
  end)
end

-- Default positions if no saved pos exists yet (your old layout)
local function ApplyDefaultRaidDragPos(f, i, cfg)
  -- You can adjust these defaults as needed
  local a1 = (cfg.units.raid.pos and cfg.units.raid.pos.a1) or "TOPLEFT"
  local a2 = (cfg.units.raid.pos and cfg.units.raid.pos.a2) or "TOPLEFT"
  local y  = (cfg.units.raid.pos and cfg.units.raid.pos.y)  or -5

  f:ClearAllPoints()
  f:SetPoint(a1, UIParent, a2, 5, y)

  if i == 2 then
    f:SetPoint(a1, UIParent, a2, 133, y)
  elseif i == 3 then
    f:SetPoint(a1, UIParent, a2, 5, -310)
  elseif i == 4 then
    f:SetPoint(a1, UIParent, a2, 133, -310)
  elseif i == 5 then
    f:SetPoint(a1, UIParent, a2, 5, -310*2)
  elseif i == 6 then
    f:SetPoint(a1, UIParent, a2, 133, -310*2)
  elseif i == 7 then
    f:SetPoint(a1, UIParent, a2, 5, -310*3)
  elseif i == 8 then
    f:SetPoint(a1, UIParent, a2, 133, -310*3)
  end
end

local function ApplySavedRaidDragPosIfAny(f, i, cfg)
  local gp = cfg.units.raid.groupPos and cfg.units.raid.groupPos[i]
  if not gp then return false end

  local af = _G[gp.af] or UIParent
  f:ClearAllPoints()
  f:SetPoint(gp.a1 or "TOPLEFT", af, gp.a2 or gp.a1 or "TOPLEFT", gp.x or 0, gp.y or 0)
  return true
end

local function cleanupRaidFrames()
  -- Hide and detach previously spawned secure headers (not the stable drag frames)
  for _, group in ipairs(spawnedRaidGroups) do
    if group then
      -- Don't try to “nuke” secure headers too aggressively; just hide/detach.
      group:Hide()
      group:ClearAllPoints()
      group:SetParent(nil)
    end
  end
  wipe(spawnedRaidGroups)

  -- Drag frames are stable; don't destroy them, just hide.
  for _, drag in ipairs(spawnedRaidDragFrames) do
    if drag then
      drag:Hide()
      drag:ClearAllPoints()
      drag:SetParent(UIParent)
    end
  end
  wipe(spawnedRaidDragFrames)
end

local function Init()
  cfg = ns.cfg
  if not cfg or not cfg.units or not cfg.units.raid then return end
  if not cfg.units.raid.show then return end

  if respawnQueued then return end
  respawnQueued = true

  ns.Scheduler.NextFrame(function()
    respawnQueued = false

    -- Ensure per-group position table exists in profile
    Roth_UI.db.profile.units.raid.groupPos = Roth_UI.db.profile.units.raid.groupPos or {}

    cleanupRaidFrames()

    -- IMPORTANT: keep header names unique to avoid “clones” across reloads
    local styleName = "diablo:raid"..GetTime()
    oUF:RegisterStyle(styleName, createStyle)
    oUF:SetActiveStyle(styleName)

    local attr = cfg.units.raid.attributes
    local groups = {}

for i = 1, NUM_RAID_GROUPS do
  local idx = i

  local dragName = "Roth_UIRaidDragFrame"..idx
  local raidDragFrame = _G[dragName] or CreateFrame("Frame", dragName, UIParent)
  raidDragFrame:SetSize(50, 50)

  -- register with /roth unlockunits
  Roth_UI_Units = Roth_UI_Units or {}
  local inList=false
  for _,v in pairs(Roth_UI_Units) do if v==dragName then inList=true break end end
  if not inList then table.insert(Roth_UI_Units, dragName) end

  -- IMPORTANT: position it BEFORE defaultPosition capture inside applyDragFunctionality
  local gp = Roth_UI.db.profile.units.raid.groupPos and Roth_UI.db.profile.units.raid.groupPos[idx]
  if gp then
    raidDragFrame:ClearAllPoints()
    raidDragFrame:SetPoint(gp.a1, _G[gp.af] or UIParent, gp.a2, gp.x, gp.y)
  end

  func.applyDragFunctionality(raidDragFrame)

  -- Save on the *child* dragframe (that’s what is actually dragged)
  if raidDragFrame.dragframe then
    raidDragFrame.dragframe:HookScript("OnDragStop", function(self)
      local parent = self:GetParent()
      local a1, af, a2, x, y = parent:GetPoint(1)
      local afName = (af and af:GetName()) or "UIParent"
      Roth_UI.db.profile.units.raid.groupPos = Roth_UI.db.profile.units.raid.groupPos or {}
      Roth_UI.db.profile.units.raid.groupPos[idx] = { a1=a1, af=afName, a2=a2, x=x, y=y }
    end)
  end

      -- Load saved pos first; otherwise apply your defaults
      if not ApplySavedRaidDragPosIfAny(raidDragFrame, i, cfg) then
        ApplyDefaultRaidDragPos(raidDragFrame, i, cfg)
      end

      -- Make draggable + persist to profile (keyed by group index)
      MakeRaidDragFramePersistent(raidDragFrame, i)

      -- If you have your own drag visuals/handlers, you can still call them,
      -- but DON'T let them overwrite point-saving (or you’ll lose persistence).
      -- func.applyDragFunctionality(raidDragFrame)

      table.insert(spawnedRaidDragFrames, raidDragFrame)

      -- Unique secure header name (ok to be unique)
      local headerName = "Roth_UIRaidGroup"..i.."_"..styleName

      local group = oUF:SpawnHeader(
        headerName,
        nil,
        "show",
        "showPlayer",         attr.showPlayer,
        "showSolo",           attr.showSolo,
        "showParty",          attr.showParty,
        "showRaid",           attr.showRaid,
        "point",              attr.point,
        "yOffset",            attr.yOffset,
        "xoffset",            attr.xoffset,
        "groupFilter",        tostring(i),
        "maxColumns",         attr.maxColumns,
        "unitsPerColumn",     attr.unitsPerColumn,
        "oUF-initialConfigFunction", ([[ self:SetWidth(%d) self:SetHeight(%d) ]]):format(128, 64)
      )

    -- Ensure the secure header visibility logic is applied
    if attr.visibility then
      UnregisterStateDriver(group, "visibility")
      RegisterStateDriver(group, "visibility", attr.visibility)
    else
      -- fallback: just force show if no visibility rule exists
      UnregisterStateDriver(group, "visibility")
      group:Show()
    end
    
      group:ClearAllPoints()
      group:SetPoint("TOPLEFT", raidDragFrame, 0, 0)
      group:Show()

      groups[i] = group
      table.insert(spawnedRaidGroups, group)
    end

    -- Apply scaling to the headers
    local scale = cfg.units.raid.scale or 1
    for _, group in pairs(groups) do
      if group then group:SetScale(scale) end
    end

    -- Hide Blizzard compact party frame (if it exists in this client)
    local updater = CreateFrame("Frame")
    updater:SetScript("OnUpdate", function()
      if CompactPartyFrame then
        CompactPartyFrame:Hide()
      end
      if CompactRaidFrameContainer then
          CompactRaidFrameContainer:Hide()
      end
    end)
  end)
end

ns:RegisterInit(Init)

Roth_UI:AddConfig("units.raid", {}, "Raid", Init)