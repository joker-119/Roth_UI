
  --get the addon namespace
  local addon, ns = ...

  --get oUF namespace (just in case needed)
  local oUF = ns.oUF or oUF
  local rLib = ns.rLib or rLib

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
    self:RegisterForClicks("AnyDown")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
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
	if self.cfg.vertical == true then
	 h:SetPoint("TOP",0,-29)
	 h:SetPoint("LEFT",46,0)
	 h:SetPoint("RIGHT",-46,0)
	 h:SetPoint("BOTTOM",0,26)
	else
     h:SetPoint("TOP",0,-29)
     h:SetPoint("LEFT",21,0)
     h:SetPoint("RIGHT",-21,0)
     h:SetPoint("BOTTOM",0,26)
	end
    h:SetStatusBarTexture(cfg.texture)
    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_hpglow")
	h.glow:SetPoint("TOP",0,-42)
	h.glow:SetPoint("LEFT",-40,0)
	h.glow:SetPoint("RIGHT",42,0)
	h.glow:SetPoint("BOTTOM",0,36)
    h.glow:SetVertexColor(0,0,0,1)

    h.highlight = h:CreateTexture(nil,"OVERLAY",nil,-4)
    h.highlight:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_highlight")
    h.highlight:SetAllPoints(self)

    self.Health = h
    self.Health.Smooth = true
    self.Health.frequentUpdates = self.cfg.health.frequentUpdates or false
  end

  --create power frames
  local createPowerFrame = function(self)
    local cfg = self.cfg.power

    --power
    local h = CreateFrame("StatusBar", nil, self.Health)
	if self.cfg.vertical == true then
     h:SetPoint("TOP",0,-12.5)
     h:SetPoint("LEFT",7,0)
     h:SetPoint("RIGHT",-7,0)
     h:SetPoint("BOTTOM",0,-8)
	else
     h:SetPoint("TOP",0,-12.5)
     h:SetPoint("LEFT",7,0)
     h:SetPoint("RIGHT",-7,0)
     h:SetPoint("BOTTOM",0,-8)
	end
    h:SetStatusBarTexture(cfg.texture)

    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_ppglow")
    h.glow:SetAllPoints(self)
    h.glow:SetVertexColor(0,0,0,1)

    self.Power = h
    self.Power.Smooth = true
    self.Power.frequentUpdates = self.cfg.power.frequentUpdates or false

  end

  --create health power strings
  local createHealthPowerStrings = function(self)

    local name = func.createFontString(self.Health, cfg.font, self.cfg.misc.NameFontSize, "THINOUTLINE")
	name:SetPoint("BOTTOM", self, "TOP", 0, -13)
    name:SetPoint("LEFT", self.Health, 0, 0)
    name:SetPoint("RIGHT", self.Health, 0, 0)
	self.Name = name

    local hpval = func.createFontString(self.Health, cfg.font, self.cfg.health.fontSize, "THINOUTLINE")
    hpval:SetPoint(self.cfg.health.point, self.cfg.health.x,self.cfg.health.y)

    self:Tag(name, "[diablo:name]")
    self:Tag(hpval, self.cfg.health.tag or "")

  end

  ---------------------------------------------
  -- PARTY STYLE FUNC
  ---------------------------------------------

  local function createStyle(self)

    --apply config to self
    self.cfg = cfg.units.party
    self.cfg.style = "party"

    self.cfg.width = self.cfg.portrait.width
    self.cfg.height = 64

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

    --create portrait
    if self.cfg.portrait.show then
      func.createPortrait(self)
      if self.PortraitHolder then
        if(InCombatLockdown()) then
          self.PortraitHolder:RegisterEvent("PLAYER_REGEN_ENABLED")
        else
			if self.cfg.vertical then
				self:SetHitRectInsets(-35,0, -17, 0)
			else 
				self:SetHitRectInsets(0,0,-100,0)
			end
        end      
        self.PortraitHolder:SetScript("OnEvent", function(...)
          self.PortraitHolder:UnregisterEvent("PLAYER_REGEN_ENABLED")
          self:SetHitRectInsets(0, 0, -100, 0)
        end)
      end      
    end

    --auras
    if self.cfg.auras.show then
      func.createDebuffs(self)
	  self.Debuffs.PostCreateIcon = func.createAuraIcon
	  func.createBuffs(self)
	  self.Buffs.PostCreateIcon = func.createAuraIcon
    end

    --aurawatch
    if self.cfg.aurawatch.show then
      func.createAuraWatch(self)
    end

    --debuffglow
    func.createDebuffGlow(self)

    --range
    self.Range = {
      insideAlpha = 1,
      outsideAlpha = self.cfg.alpha.notinrange
    }

    --icons
    self.RaidIcon = func.createIcon(self,"OVERLAY",18,self.Name,"RIGHT","LEFT",0,0,-1)
    self.ReadyCheck = func.createIcon(self.Health,"OVERLAY",24,self.Health,"CENTER","CENTER",0,0,-1)
    if self.Border then
      self.Leader = func.createIcon(self,"OVERLAY",13,self.Border,"BOTTOMRIGHT","BOTTOMLEFT",16,18,-1)
      if self.cfg.portrait.use3D then
        self.LFDRole = func.createIcon(self.BorderHolder,"OVERLAY",12,self.Health,"CENTER","CENTER",0,0,5)
      else
        self.LFDRole = func.createIcon(self.PortraitHolder,"OVERLAY",12,self.Health,"CENTER","CENTER",0,0,5)
      end
    else
      self.Leader = func.createIcon(self,"OVERLAY",13,self,"RIGHT","LEFT",16,-18,-1)
      self.LFDRole = func.createIcon(self,"OVERLAY",12,self,"RIGHT","LEFT",16,18,-1)
    end
    self.LFDRole:SetTexture("Interface\\AddOns\\Roth_UI\\media\\lfd_role")
    --self.LFDRole:SetDesaturated(1)

    --add heal prediction
    func.healPrediction(self)
    
    --add total absorb
    func.totalAbsorb(self)

    --threat
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", func.checkThreat)

  end
  
--------------------------------------------
-- Drag Frame (time for hacks)
--------------------------------------------
local A, L = ...
L.addonName     = A 
L.dragFrames    = {}
L.addonColor    = "00FFFFFF"
L.addonShortcut = "dparty"

rLib:CreateDragFrame(frame, L.dragFrames, -2, true)
rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)
  ---------------------------------------------
  -- SPAWN PARTY UNIT
  ---------------------------------------------

  if cfg.units.party.show then
    oUF:RegisterStyle("diablo:party", createStyle)
    oUF:SetActiveStyle("diablo:party")

    local attr = cfg.units.party.attributes
	
	

    local partyDragFrame = CreateFrame("Frame", "Roth_UIPartyDragFrame", UIParent)
    partyDragFrame:SetSize(50,50)
    partyDragFrame:SetPoint(cfg.units.party.pos.a1,cfg.units.party.pos.af,cfg.units.party.pos.a2,cfg.units.party.pos.x,cfg.units.party.pos.y)
    func.applyDragFunctionality(partyDragFrame)
    table.insert(Roth_UI_Units,"Roth_UIPartyDragFrame") --add frames to the slash command function

	if cfg.units.party.vertical == true then
    local party = oUF:SpawnHeader(
      "Roth_UIPartyHeader",
      nil,
      attr.visibility,
      "showPlayer",         attr.showPlayer,
      "showSolo",           attr.showSolo,
      "showParty",          attr.showParty,
      "showRaid",           attr.showRaid,
      "point",              attr.VerticalPoint,
      "oUF-initialConfigFunction", ([[
        self:SetWidth(%d)
        self:SetHeight(%d)
        self:SetScale(%f)
      ]]):format(228, 64, cfg.units.party.scale)
    )
    party:SetPoint("TOPLEFT",partyDragFrame,0,0)
 else
     local party = oUF:SpawnHeader(
      "Roth_UIPartyHeader",
      nil,
      attr.visibility,
      "showPlayer",         attr.showPlayer,
      "showSolo",           attr.showSolo,
      "showParty",          attr.showParty,
      "showRaid",           attr.showRaid,
      "point",             	attr.HorizontalPoint,
      "oUF-initialConfigFunction", ([[
        self:SetWidth(%d)
        self:SetHeight(%d)
        self:SetScale(%f)
      ]]):format(128, 64, cfg.units.party.scale)
    )
    party:SetPoint("TOPLEFT",partyDragFrame,0,0)
  end
 end
