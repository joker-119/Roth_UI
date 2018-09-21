
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

  ---------------------------------------------
  -- UNIT SPECIFIC FUNCTIONS
  ---------------------------------------------

  --init parameters
  local initUnitParameters = function(self)
    self:RegisterForClicks("AnyDown")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
  end


  --whitelist
  local whitelist = {}
  if cfg.units.raid.auras.whitelist then
    for _,spellid in pairs(cfg.units.raid.auras.whitelist) do
      local spell = GetSpellInfo(spellid)
      if spell then whitelist[spellid] = true end
    end
  end

  --blacklist
  local blacklist = {}
  if cfg.units.raid.auras.blacklist then
    for _,spellid in pairs(cfg.units.raid.auras.blacklist) do
      local spell = GetSpellInfo(spellid)
      if spell then blacklist[spellid] = true end
    end
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
    elseif caster and caster:match("(boss)%d?$") == "boss" then
      ret = true
    end
    return ret
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
    f.showDebuffType = cfg.showDebuffType or false
    f.showBuffType = cfg.showBuffType or false
    if not cfg.doNotUseCustomFilter then
      f.CustomFilter = customFilter
    end
    f:SetHeight(f.size)
    f:SetWidth((f.size+f.spacing)*f.num)
    if cfg.pos then
      f:SetPoint(cfg.pos.a1 or "CENTER", self, cfg.pos.a2 or "CENTER", cfg.pos.x or 0, cfg.pos.y or 0)
    else
      f:SetPoint("CENTER",0,-5)
    end
    self.Debuffs = f
  end

  --aura icon func
  --[[local createAuraIcon = function(icons, button)
    --button:EnableMouse(false)
    local bw = button:GetWidth()
    if button.cd then
      button.cd:SetPoint("TOPLEFT", 1, -1)
      button.cd:SetPoint("BOTTOMRIGHT", -1, 1)
      button.count:SetParent(button.cd)
    end
    button.count:ClearAllPoints()
    button.count:SetPoint("TOPRIGHT", 4, 4)
    button.count:SetTextColor(0.9,0.9,0.9)
    button.count:SetFont(cfg.font,1.8,"THINOUTLINE")
    button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    button.overlay:SetTexture("Interface\\AddOns\\Roth_UI\\media\\default_border")
    button.overlay:SetTexCoord(0,1,0,1)
    button.overlay:SetPoint("TOPLEFT", -1, 1)
    button.overlay:SetPoint("BOTTOMRIGHT", 1, -1)
    button.overlay:SetVertexColor(0.2,0.15,0.15,1)
    button.overlay:Show()
    button.overlay.Hide = function() end
  end]]--

  --create aura watch func
   local createAuraWatch = function(self)
   
      local auras = {}
	  local spellIDs
    if cfg.playerclass == "PRIEST" then 
      spellIDs = {
        139, -- Renew
		17, -- Power Word Shield
		77489, -- Echo of Light
		41635, --Prayer of mending
		
      }
    elseif cfg.playerclass == "PALADIN" then
      spellIDs = {
        223306, -- Bestow Faith
        53563, -- Beacon of Light
        6940, -- Blessing of Sacrifice
        156910, -- Beacon of Faith
		200025, -- Beacon of Virtue
      }
	elseif cfg.playerclass == "DRUID" then
		spellIDs = {
		33763, -- Lifebloom
		774, -- Rejuvination
		8936, -- Regrowth
		102342, -- Ironback
		102351, -- Cenarion Ward
		48438, -- Wild Growth
		155777, -- Germination
		}
	elseif cfg.playerclass == "SHAMAN" then
		spellIDs = {
		61295, -- Riptide
		}
	elseif cfg.playerclass == "MONK" then
		spellIDs = {
		119611, --Renewing mist
		124682, -- Enveloping Mist
		}
	else -- Non Healer Classes
		spellIDs = {
		
		}
	end
      local dir = {
        [1] = {size = 15, pos = "CENTER",       x = 0, y = 12.5 },
        [2] = {size = 15, pos = "CENTER",       x = 15, y = 12.5 },
        [3] = {size = 15, pos = "CENTER",       x = -15, y = 12.5 },
        [4] = {size = 15, pos = "CENTER",       x = 30, y = 12.5 },
        [5] = {size = 15, pos = "CENTER",       x = -30, y = 12.5 },
        [6] = {size = 15, pos = "CENTER",       x = 15, y = 12.5 },
        [7] = {size = 15, pos = "CENTER",       x = 15, y = 12.5 },
      }
      auras.onlyShowPresent = true
      auras.presentAlpha = .75

      auras.PostCreateIcon = function(self, icon, sid)
        if icon.cd then
          icon.cd:SetPoint("TOPLEFT", 1, -1)
          icon.cd:SetPoint("BOTTOMRIGHT", -1, 1)
        end
        --count hack for lifebloom
        if sid == 33763 and icon.count then
          icon.count:SetFont("Interface\\AddOns\\Roth_UI\\media\\visitor1.ttf",8,"THINOUTLINE, MONOCHROME")
          icon.count:ClearAllPoints()
          icon.count:SetPoint("CENTER", 3, 3)
          icon.count:SetParent(icon.cd)
        end
      end

      -- Set any other AuraWatch settings
      auras.icons = {}
      for i, sid in pairs(spellIDs) do
        local icon = CreateFrame("Frame", nil, self)
		icon:SetFrameStrata("HIGH")
        icon.spellID = sid
        -- set the dimensions and positions
        icon.size = dir[i].size
        icon:SetSize(dir[i].size,dir[i].size)
        --position icon
        icon:SetPoint(dir[i].pos, self, dir[i].pos, dir[i].x, dir[i].y)
        --make indicator
        --if dir[i].indicator then
          local tex = icon:CreateTexture()
          tex:SetAllPoints()
          tex:SetTexture("Interface\\AddOns\\Roth_UI\\media\\indicator")
          --tex:SetVertexColor(dir[i].color.r,dir[i].color.g,dir[i].color.b)
          icon.icon = tex


        auras.icons[sid] = icon
        -- Set any other AuraWatch icon settings
      end
      --call aurawatch
      self.AuraWatch = auras
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
      bar.glow:SetVertexColor(0,0,0,0.7)
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

  end

  --create health power strings
  local createHealthPowerStrings = function(self)

    local name = func.createFontString(self, cfg.font, 12, "THINOUTLINE", "TOOLTIP")
    name:SetPoint("BOTTOM", self, "TOP", 0, -20)
    name:SetPoint("LEFT", self.Health, 0, 0)
    name:SetPoint("RIGHT", self.Health, 0, 0)
    --name:SetJustifyH("LEFT")
    self.Name = name

    local hpval = func.createFontString(self, cfg.font, 11, "THINOUTLINE", "BACKGROUND")
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
    self.Power.PostUpdate = func.updatePower

    --debuffglow
    func.createDebuffGlow(self)

    --range
    self.Range = {
      insideAlpha = 1,
      outsideAlpha = self.cfg.alpha.notinrange
    }

    --auras
    if self.cfg.auras.show then
      createDebuffs(self)
      self.Debuffs.PostCreateIcon = createAuraIcon
    end

    --aurawatch
    if self.cfg.aurawatch.show then
      createAuraWatch(self)
    end

    --icons
    self.RaidIcon = func.createIcon(self,"TOOLTIP",14,self.Health,"CENTER","CENTER",0,0,-1)
	self.RaidIcon:SetTexture("Interface\\AddOns\\Roth_UI\\media\\raidicons")
    self.ReadyCheck = func.createIcon(self,"TOOLTIP",24,self.Health,"CENTER","CENTER",0,0,-1)
    self.LFDRole = func.createIcon(self,"TOOLTIP",14,self.Health,"CENTER","CENTER",0,0,-1)
    self.LFDRole:SetTexture("Interface\\AddOns\\Roth_UI\\media\\lfd_role")
    self.LFDRole:SetDesaturated(1)

    --add heal prediction
    func.healPrediction(self)
    
    --add total absorb
    func.totalAbsorb(self)

  end

  ---------------------------------------------
  -- SPAWN RAID UNIT
  ---------------------------------------------

  if cfg.units.raid.show then

    --register style
    oUF:RegisterStyle("diablo:raid", createStyle)
    oUF:SetActiveStyle("diablo:raid")

    local attr = cfg.units.raid.attributes

    
    local groups, group = {}, nil
    for i=1, NUM_RAID_GROUPS do
      local name = "Roth_UIRaidGroup"..i
	local raidDragFrame = CreateFrame("Frame", "Roth_UIRaidDragFrame"..i, UIParent)
    raidDragFrame:SetSize(50,50)
    raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,5,cfg.units.raid.pos.y)
	if i == 2 then
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,133,cfg.units.raid.pos.y)
	elseif i == 3 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,5,-310)
	elseif i == 4 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,133,-310)
	elseif i == 5 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,5,-310*2)	
	elseif i == 6 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,133,-310*2)
	elseif i == 7 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,5,-310*3)
	elseif i == 8 then 
	raidDragFrame:SetPoint(cfg.units.raid.pos.a1,cfg.units.raid.pos.af,cfg.units.raid.pos.a2,133,-310*3)
	
	end
    func.applyDragFunctionality(raidDragFrame)
    table.insert(Roth_UI_Units,"Roth_UIRaidDragFrame"..i) --add frames to the slash command function
      group = oUF:SpawnHeader(
        name,
        nil,
        attr.visibility,
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
        --"columnSpacing",      attr.columnSpacing,
        --"columnAnchorPoint",  attr.columnAnchorPoint,
        "oUF-initialConfigFunction", ([[
          self:SetWidth(%d)
          self:SetHeight(%d)
        ]]):format(128, 64)
      )
		group:SetPoint("TOPLEFT", raidDragFrame, 0, 0)		
		groups[i] = group
    end
	   local scale = cfg.units.raid.scale
        for idx, group in pairs(groups) do
          if group then
            group:SetScale(scale)
          end
        end
	if attr.showInArena then
		local Frame = CreateFrame("Frame")
			Frame:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
			Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
			Frame:SetScript("OnEvent", function(...)
				isArena, _ = IsActiveBattlefieldArena();
				if isArena == true then
					RegisterStateDriver(Roth_UIRaidGroup1, "visibility", "show")
				else
					if cfg.units.party.show then
						RegisterStateDriver(Roth_UIRaidGroup1, "visibility", attr.visibility)
					end
				end
			end)
	end
  end
