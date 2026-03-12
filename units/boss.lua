
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

  ---------------------------------------------
  -- UNIT SPECIFIC FUNCTIONS
  ---------------------------------------------

  --init parameters
  local initUnitParameters = function(self)
    self:SetFrameStrata("BACKGROUND")
    self:SetFrameLevel(1)
    self:SetSize(self.cfg.width, self.cfg.height)
    self:SetScale(self.cfg.scale)
    self:RegisterForClicks("AnyDown")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    self:SetHitRectInsets(10,10,10,10)
  end

  --actionbar background
  local createArtwork = function(self)
    local t = self:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(self)
    t:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget")
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
	h:SetFrameStrata("LOW")

    h:SetStatusBarTexture(cfg.texture)
    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_hpglow")
    h.glow:SetPoint("TOP",0,17)
    h.glow:SetPoint("LEFT",-24,0)
    h.glow:SetPoint("RIGHT",24,0)
    h.glow:SetPoint("BOTTOM",0,-20)
    h.glow:SetVertexColor(0,0,0,1)

    h.highlight = h:CreateTexture(nil,"OVERLAY",nil,-4)
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
	 h:SetFrameStrata("LOW")

    h:SetStatusBarTexture(cfg.texture)

    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_ppglow")
    h.glow:SetAllPoints(self)
    h.glow:SetVertexColor(0,0,0,1)

    self.Power = h

  end

  --create health power strings
  local createHealthPowerStrings = function(self)

    local name = func.createFontString(self, cfg.fonts.headerFont, 14, "THINOUTLINE")
    name:SetPoint("BOTTOM", self, "TOP", 0, -14)
    name:SetPoint("LEFT", self.Health, 0, 0)
    name:SetPoint("RIGHT", self.Health, 0, 0)
    self.Name = name

    local hpval = func.createFontString(self.Health, cfg.fonts.textFont, 11, "THINOUTLINE")
    hpval:SetPoint("RIGHT", -2,0)

    local ppval = func.createFontString(self.Health, cfg.fonts.textFont, 10, "THINOUTLINE")
    ppval:SetPoint("TOP",self.Health,"BOTTOM", 0,0)
    ppval:SetVertexColor(0.6,0.6,0.6,1)

    self:Tag(name, "[diablo:name]")
    self:Tag(hpval, self.cfg.health.tag or "")
    self:Tag(ppval, self.cfg.power.tag or "")

  end


  ---------------------------------------------
  -- BOSS STYLE FUNC
  ---------------------------------------------

  local bossid = 1
  unit.boss = {}

  local function createStyle(self)

    --apply config to self
    self.cfg = cfg.units.boss
    self.cfg.style = "boss"

    --init
    initUnitParameters(self)

    --create the art
    createArtwork(self)

    --createhealthPower
    createHealthFrame(self)
    createPowerFrame(self)

    --health power strings
    createHealthPowerStrings(self)

    --health power update
    self.Health.PostUpdate = func.updateHealth
    self.Power.PostUpdate = func.updatePower

    --icons
    self.RaidIcon = func.createIcon(self,"BACKGROUND",16,self.Name,"BOTTOM","TOP",0,0,-1)
    

    --add self to unit container (maybe access to that unit is needed in another style)
    unit.boss[bossid] = self

    bossid = bossid+1

  end

  ---------------------------------------------
  -- SPAWN BOSS UNIT
  ---------------------------------------------
  local respawnQueued = false
  local spawnedFrames = {}
local function Init()
if respawnQueued then return end
respawnQueued = true

  if cfg.units.boss.show then
      ns.Scheduler.NextFrame(function()
      
      local BossAnchor = CreateFrame("Frame", "Roth_UIBossAnchor", UIParent, "SecureHandlerBaseTemplate")
      BossAnchor:SetSize(1, 1)
      
        local mm = _G[cfg.units.boss.pos.af] or MinimapCluster or Minimap
        local left = mm:GetLeft()
        local top  = mm:GetTop()
        BossAnchor:SetPoint(cfg.units.boss.pos.a1, UIParent, cfg.units.boss.pos.a2, left + cfg.units.boss.pos.x, top + cfg.units.boss.pos.y)

        local styleName = "diablo:boss"..GetTime()
        respawnQueued = false
        
        for _,f in ipairs(spawnedFrames) do
            if (f.RareIcon) then
                f:DisableElement("RareIcon")
            end
            if (f.Name) then
                f:DisableElement("Name")
            end
            
            UnregisterUnitWatch(f)
            f:UnregisterAllEvents()
            for _, child in ipairs({f:GetChildren()}) do
                child:UnregisterAllEvents()
                child:Hide()
            end
            f:Hide()
            f:SetParent(nil)
            if f:GetName() then _G[f:GetName()] = nil end
        end
        
        oUF:RegisterStyle(styleName, createStyle)
        oUF:SetActiveStyle(styleName)
        
        local boss = {}
        for i = 1, MAX_BOSS_FRAMES do
        local name = "Roth_UIBossFrame"..i
        local unit = oUF:Spawn("boss"..i, name)
        unit:ClearAllPoints()
        if i == 1 then
          unit:SetPoint("TOPLEFT", BossAnchor, "TOPLEFT", 0, 0)
        else
          unit:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -5)
        end
        
          table.insert(Roth_UI_Units,name) --add frames to the slash command function
          table.insert(spawnedFrames, unit)
          func.applyDragFunctionality(unit)
          boss[i] = unit
          unit:EnableElement("RareIcon")
          unit:EnableElement("Name")
          unit:UpdateAllElements("ForceUpdate")
        end
    end)
    end
end

ns:RegisterInit(Init)

Roth_UI:AddConfig("units.boss", {}, "Boss", Init)