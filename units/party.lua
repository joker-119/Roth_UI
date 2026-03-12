
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
	if self.cfg.vertical == true then
		t:SetPoint("TOP",0,40)
		t:SetPoint("LEFT",-0,0)
		t:SetPoint("RIGHT",0,0)
		t:SetPoint("BOTTOM",0,-20)
	else
		t:SetPoint("TOP",0,20)
		t:SetPoint("LEFT",-10,0)
		t:SetPoint("RIGHT",10,0)
		t:SetPoint("BOTTOM",0,-20)
	end
    t:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget")
  end

  --create health frames
  local createHealthFrame = function(self)
    local cfg = self.cfg.health

    --health
    local h = CreateFrame("StatusBar", nil, self)
	if self.cfg.vertical == true then
	 h:SetPoint("TOP",0,-15)
	 h:SetPoint("LEFT",47,0)
	 h:SetPoint("RIGHT",-45,0)
	 h:SetPoint("BOTTOM",0,35)
	 h:SetFrameStrata("BACKGROUND")
	else
     h:SetPoint("TOP",0,-25)
     h:SetPoint("LEFT",10,0)
     h:SetPoint("RIGHT",-10,0)
     h:SetPoint("BOTTOM",0,25)
	 h:SetFrameStrata("BACKGROUND")
	end
    h:SetStatusBarTexture(cfg.texture)
    h.bg = h:CreateTexture(nil,"BORDER",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture(ns.mediapath.."targettarget_hpglow")
	if self.cfg.vertical == true then
		h.glow:SetPoint("TOP",0,25)
		h.glow:SetPoint("LEFT",-40,0)
		h.glow:SetPoint("RIGHT",40,0)
		h.glow:SetPoint("BOTTOM",0,-35)
	else
		h.glow:SetPoint("TOP", 0, 20)
        h.glow:SetPoint("LEFT",-20,0)
        h.glow:SetPoint("RIGHT",20,0)
        h.glow:SetPoint("BOTTOM",0,-20)
	end
		
    h.highlight = h:CreateTexture(nil,"OVERLAY",nil,-4)
    h.highlight:SetTexture("Interface\\AddOns\\Roth_UI\\media\\targettarget_highlight")
    h.highlight:SetAllPoints(h.glow)

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
     h:SetPoint("TOP",0,-20)
     h:SetPoint("LEFT",6,0)
     h:SetPoint("RIGHT",-6,0)
     h:SetPoint("BOTTOM",0,-20)
	 h:SetFrameStrata("BACKGROUND")
	else
     h:SetPoint("TOP",0,-20)
     h:SetPoint("LEFT",5,0)
     h:SetPoint("RIGHT",-5,0)
     h:SetPoint("BOTTOM",0,-15)
	 h:SetFrameStrata("BACKGROUND")
	end
    h:SetStatusBarTexture(cfg.texture)

    h.bg = h:CreateTexture(nil,"BORDER",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    self.Power = h
    self.Power.Smooth = true
    self.Power.frequentUpdates = self.cfg.power.frequentUpdates or false

  end

  --create health power strings
  local createHealthPowerStrings = function(self)
      
    local name = func.createFontString(self.Health, cfg.fonts.headerFont, self.cfg.fontSize, "THINOUTLINE")
	if self.cfg.vertical == true then
		name:SetPoint("BOTTOM", self, "TOP", 0, -3)
		name:SetPoint("LEFT", self.Health, 0, 0)
		name:SetPoint("RIGHT", self.Health, 0, 0)
	else
		name:SetPoint("TOP", self, "TOP", 0, 60)
		name:SetPoint("LEFT", self.Health, 0, 0)
		name:SetPoint("RIGHT", self.Health, 0, 0)
	end
	self.Name = name

    local hpval = func.createFontString(self.Health, cfg.fonts.textFont, self.cfg.health.fontSize, "THINOUTLINE")
    if self.cfg.vertical == true then
		hpval:SetPoint(self.cfg.health.textPos, self.cfg.health.x,self.cfg.health.y)
	else
		hpval:SetPoint(self.cfg.health.textPos, self.cfg.health.x+18,self.cfg.health.y)
	end

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
    end

    --auras
    if self.cfg.auras.show then
      func.createDebuffs(self)
	  self.Debuffs.PostCreateIcon = func.createAuraIcon
	  if self.cfg.auras.showBuffs then
		func.createBuffs(self)
		self.Buffs.PostCreateIcon = func.createAuraIcon
	  end
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
    self.RaidTargetIndicator = func.createIcon(self,"OVERLAY",18,self.Name,"RIGHT","LEFT",25,0,-1)
	self.RaidTargetIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\raidicons")
    self.ReadyCheckIndicator = func.createIcon(self,"OVERLAY",24,self.Health,"CENTER","CENTER",0,0,-1)
    if self.Border then
      self.LeaderIndicator = func.createIcon(self,"OVERLAY",13,self.Border,"BOTTOMRIGHT","TOPRIGHT",-5,-27,-1)
      if self.cfg.portrait.use3D then
        self.GroupRoleIndicator = func.createIcon(self.BorderHolder,"OVERLAY",12,self.Health,"CENTER","CENTER",0,0,5)
      else
        self.GroupRoleIndicator = func.createIcon(self.PortraitHolder,"OVERLAY",12,self.Name,"CENTER","CENTER",0,0,5)
      end
    else
      self.LeaderIndicator = func.createIcon(self,"OVERLAY",13,self,"RIGHT","LEFT",70,30,-1)
      self.GroupRoleIndicator = func.createIcon(self,"OVERLAY",12,self,"CENTER","CENTER",0,10,-1)
    end
	self.LeaderIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\leader")
    self.GroupRoleIndicator:SetTexture("Interface\\AddOns\\Roth_UI\\media\\lfd_role")
    --self.LFDRole:SetDesaturated(1)

    --add heal prediction
    func.healPrediction(self)
    
    --add total absorb
    func.totalAbsorb(self)

    --threat
    self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", func.checkThreat)
	
	-- debuff coloring
	self:RegisterEvent("UNIT_AURA", func.checkColors)

  end
  

  ---------------------------------------------
  -- SPAWN PARTY UNIT
  ---------------------------------------------
  local respawnQueued = false
  local spawnedHeader
  
local function Init()
    cfg = ns.cfg
    if respawnQueued then return end
    respawnQueued = true
    ns.Scheduler.NextFrame(function()
        if cfg.units.party.show then
            
            respawnQueued = false
            local styleName = "diablo:party"..GetTime()

            -- Cleanup old header
            if spawnedHeader then
                UnregisterUnitWatch(spawnedHeader)
                UnregisterStateDriver(spawnedHeader, "visibility")
                spawnedHeader:UnregisterAllEvents()
                spawnedHeader:Hide()
                spawnedHeader:SetParent(nil)
                if spawnedHeader:GetName() then _G[spawnedHeader:GetName()] = nil end
            end

            oUF:RegisterStyle(styleName, createStyle)
            oUF:SetActiveStyle(styleName)
            local attr = cfg.units.party.attributes

            local partyDragFrame = CreateFrame("Frame", "Roth_UIPartyDragFrame", UIParent)
            partyDragFrame:SetSize(50,50)
            partyDragFrame:SetPoint(cfg.units.party.pos.a1,cfg.units.party.pos.af,cfg.units.party.pos.a2,cfg.units.party.pos.x,cfg.units.party.pos.y)
            func.applyDragFunctionality(partyDragFrame)
            table.insert(Roth_UI_Units,"Roth_UIPartyDragFrame")

            local headerName = "Roth_UIPartyHeader"..GetTime()
            local party
            if cfg.units.party.vertical then
                party = oUF:SpawnHeader(
                    headerName,
                    nil,
                    attr.visibility,
                    "showPlayer", attr.showPlayer,
                    "showSolo",   attr.showSolo,
                    "showParty",  attr.showParty,
                    "showRaid",   attr.showRaid,
                    "point",      attr.VerticalAnchor,
                    "yOffset",    attr.yoffset,
                    "oUF-initialConfigFunction", ([[ 
                        self:SetWidth(%d)
                        self:SetHeight(%d)
                        self:SetScale(%f)
                    ]]):format(cfg.units.party.vertwidth, cfg.units.party.vertheight, cfg.units.party.scale),
                    "template", "SecureUnitButtonTemplate"
                )
            else
                party = oUF:SpawnHeader(
                    headerName,
                    nil,
                    attr.visibility,
                    "showPlayer", attr.showPlayer,
                    "showSolo",   attr.showSolo,
                    "showParty",  attr.showParty,
                    "showRaid",   attr.showRaid,
                    "point",      attr.HorizontalAnchor,
                    "oUF-initialConfigFunction", ([[ 
                        self:SetWidth(%d)
                        self:SetHeight(%d)
                        self:SetScale(%f)
                    ]]):format(cfg.units.party.width, cfg.units.party.height, cfg.units.party.scale)
                )
            end

            party:SetPoint("TOPLEFT", partyDragFrame, 0, 0)
            spawnedHeader = party

            -- Arena toggle uses consistent header name
            if attr.hideInArena then
                local Frame = CreateFrame("Frame")
                Frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
                Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
                Frame:SetScript("OnEvent", function()
                    local isArena = IsActiveBattlefieldArena()
                    if spawnedHeader then
                        if isArena then
                            RegisterStateDriver(spawnedHeader, "visibility", "hide")
                        else
                            if cfg.units.party.show then
                                RegisterStateDriver(spawnedHeader, "visibility", attr.visibility)
                            end
                        end
                    end
                end)
            end

            -- Force update children so Range alpha works right away
            for _, child in ipairs({spawnedHeader:GetChildren()}) do
                if child.UpdateAllElements then
                    child:UpdateAllElements("ForceUpdate")
                end
            end
            
            
            local updater = CreateFrame("Frame")
            updater.elapsed = 0
            updater:SetScript("OnUpdate", function(f, e)
            if CompactPartyFrame then
                CompactPartyFrame:Hide()
            end
            if PartyFrame then
                PartyFrame:Hide()
            end
                f.elapsed = f.elapsed + e
                if f.elapsed > 0.5 then -- match oUF default
                    f.elapsed = 0
                    if spawnedHeader then
                        for _, child in ipairs({spawnedHeader:GetChildren()}) do
                            if child:IsShown() and child.UpdateAllElements then
                                if child.Range and not UnitIsUnit(child.unit, "player") then
                                    local inRange,_ = UnitInRange(child.unit)
                                    if inRange then
                                        child:SetAlpha(child.Range.insideAlpha)
                                    else
                                        child:SetAlpha(child.Range.outsideAlpha)
                                    end
                                end
                            end
                        end
                    end
                end
            end)

        end
    end)
end


ns:RegisterInit(Init)

Roth_UI:AddConfig("units.party", {}, "Party", Init)