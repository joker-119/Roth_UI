
  --get the addon namespace
  local addon, ns = ...

  --get oUF namespace (just in case needed)
  local oUF = ns.oUF or oUF
  local LSM = LibStub("LibSharedMedia-3.0")

  --get the config
  local cfg = ns.cfg

  --object container
  local func = CreateFrame("Frame")
  ns.func = func
  RothUI = {}

  ---------------------------------------------
  -- VARIABLES
  ---------------------------------------------

  local tinsert, tremove, floor, mod, format = tinsert, tremove, floor, mod, format

  ---------------------------------------------
  -- FUNCTIONS
  ---------------------------------------------
    
  --number format func
  func.numFormat = function(v)
    if v > 1E10 then
      return (floor(v/1E9)).."b"
    elseif v > 1E9 then
      return (floor((v/1E9)*10)/10).."b"
    elseif v > 1E7 then
      return (floor(v/1E6)).."m"
    elseif v > 1E6 then
      return (floor((v/1E6)*10)/10).."m"
    elseif v > 1E4 then
      return (floor(v/1E3)).."k"
    elseif v > 1E3 then
      return (floor((v/1E3)*10)/10).."k"
    else
      return v
    end
  end

  --round number
  func.round = function(val)
    return floor(val*1000)/1000
  end

  --backdrop func
  func.createBackdrop = function(f)
    f:SetBackdrop(cfg.backdrop)
    f:SetBackdropColor(0,0,0,0.7)
    f:SetBackdropBorderColor(0,0,0,1)
  end

local function NormalizeSpellList(list)
    if not list then return nil end

    local t = {}
    for _, spellId in ipairs(list) do
        t[spellId] = true
    end
    return t
end

  --create debuff func
  func.createDebuffs = function(self)
  if self.cfg.vertical then
	local f = CreateFrame("Frame", nil, self)
	f.disableCooldownText = self.cfg.auras.disableCooldownText
    f.size = self.cfg.auras.size
    if self.cfg.style == "targettarget" then
      f.num = 8
    else
      f.num = cfg.units.party.auras.number
    end
    f:SetHeight((f.size+5)*(f.num/4))
    f:SetWidth((f.size+5)*4)
	if self.cfg.style == "targettarget" then
		f:SetPoint("BOTTOM", self, "RIGHT", 0, 0)
	elseif self.cfg.style == "party" then
		f:SetPoint("BOTTOM", self.Health, "RIGHT", 22,-19)
	else
		f:SetPoint("TOP", self, "RIGHT", 50, -5)

	end
    f.initialAnchor = "TOPLEFT"
    f["growth-x"] = "RIGHT"
    f["growth-y"] = "DOWN"
    f.spacing = 5
    f.showDebuffType = self.cfg.auras.showDebuffType
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerDebuffs
    f.onlyDispellable = self.cfg.auras.onlyDispellable
    f.whitelist = NormalizeSpellList(self.cfg.auras.whitelist or {})
    f.blacklist = NormalizeSpellList(self.cfg.auras.blacklist or {})
    self.Debuffs = f
  else
	local f = CreateFrame("Frame", nil, self)
	f.disableCooldownText = self.cfg.auras.disableCooldownText
    f.size = self.cfg.auras.size
    if self.cfg.style == "targettarget" then
      f.num = 8
    else
      f.num = cfg.units.party.auras.number
    end
    f:SetHeight((f.size+5)*(f.num/9))
    f:SetWidth((f.size+5)*4)
	if self.cfg.style == "targettarget" then
		f:SetPoint("BOTTOM", self, "RIGHT", -90, -40)
	else
		f:SetPoint("TOP", self, "RIGHT", -60, -67)
	end
    f.initialAnchor = "TOPLEFT"
    f["growth-x"] = "RIGHT"
    f["growth-y"] = "DOWN"
    f.spacing = 5
    f.showDebuffType = self.cfg.auras.showDebuffType
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerDebuffs
    f.onlyDispellable = self.cfg.auras.onlyDispellable
    f.whitelist = NormalizeSpellList(self.cfg.auras.whitelist or {})
    f.blacklist = NormalizeSpellList(self.cfg.auras.blacklist or {})
    self.Debuffs = f
  end
  end

  --create buff func
  func.createBuffs = function(self)
  if self.cfg.auras.hideBuffs == true then return end
  if self.cfg.vertical == false then
    local f = CreateFrame("Frame", nil, self)
    f.size = self.cfg.auras.size
    if self.cfg.style == "targettarget" then
      f.num = 8
    else
      f.num = cfg.units.party.auras.number
    end
    f:SetHeight((f.size+5)*(f.num/9))
    f:SetWidth((f.size+5)*4)
    f:SetPoint("TOP", self, "RIGHT", -60, -27)
    f.initialAnchor = "TOPLEFT"
    f["growth-x"] = "RIGHT"
    f["growth-y"] = "DOWN"
    f.spacing = 5
    f.showBuffType = self.cfg.auras.showBuffType
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerBuffs
    f.disableCooldownText = self.cfg.auras.disableCooldownText
    self.Buffs = f
  else
	local f = CreateFrame("Frame", nil, self)
    f.size = self.cfg.auras.size
    if self.cfg.style == "targettarget" then
      f.num = 8
    else
      f.num = cfg.units.party.auras.number
    end
    f:SetHeight((f.size+5)*(f.num/9))
    f:SetWidth((f.size+5)*9)
    f:SetPoint("TOP", self, "RIGHT", 117.5, 30)
    f.initialAnchor = "TOPLEFT"
    f["growth-x"] = "RIGHT"
    f["growth-y"] = "UP"
    f.spacing = 5
    f.showBuffType = self.cfg.auras.showBuffType
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerBuffs
    f.disableCooldownText = self.cfg.auras.disableCooldownText
    self.Buffs = f
  end
  end
    
  func.checkColors = function(self, event, unit, full, auras)
      local hasDebuff = false
  
      local function handleAura(name, icon, _, debuffType, _, _, _, _, _, spellId, ...)
          if debuffType and ns.Roles.canDispelDebuff(debuffType) then
              local color = DebuffTypeColor[debuffType] or DebuffTypeColor.none
              if color ~= DebuffTypeColor.none then
                  hasDebuff = true
                  self.Health.buffOverride = true
                  if self.Health.glow then
                      self.Health.glow:SetVertexColor(color.r, color.g, color.b)
                  end
              end
          end
      end
  
      if AuraUtil and AuraUtil.ForEachAura then
          -- Retail
          AuraUtil.ForEachAura(unit, "HARMFUL", nil, handleAura)
      else
          -- Classic fallback
          for i = 1, 40 do
              local name, icon, _, debuffType, _, _, _, _, _, spellId = UnitAura(unit, i, "HARMFUL")
              if not name then break end
              handleAura(name, icon, _, debuffType, _, _, _, _, _, spellId)
          end
      end

    -- reset if no debuff found
	if (not hasDebuff) then
		self.Health.buffOverride = false
		if (self.Health.glow) then
			self.Health.glow:SetVertexColor(0, 0, 0)
		end
	end
  end
  

	

  --Desaturated and Button CD
  func.postUpdateDebuff = function(element, unit, button, index, duration, expirationTime)
    if(UnitIsFriend("player", unit) or button.isPlayer) then
      button.icon:SetDesaturated(false)
      --button.cd:Show()
    else
      button.icon:SetDesaturated(true)
      --button.cd:Hide()
    end
    button.icon.duration = duration
    button.icon.timeLeft = expirationTime
    button.icon.first = true
  end

  --aura icon func
  func.createAuraIcon = function(icons, button)
    local font = ns.Media.Font(cfg.fonts.textFont)
    --button:SetSize(icons.size,icons.size)
    --button.cd:SetReverse()
    local size = icons.size or button:GetWidth()
	button.Cooldown:SetFrameStrata("MEDIUM")
    button.Cooldown:SetPoint("TOPLEFT", 1, -1)
    button.Cooldown:SetPoint("BOTTOMRIGHT", -1, 1)
    button.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    --count helper frame, this push the count fontstring over the cooldown spiral
    button.countFrame = CreateFrame("Frame",nil,button)
    button.countFrame:SetAllPoints()
	button.countFrame:SetFrameStrata("MEDIUM")
    button.countFrame:SetFrameLevel(button.Cooldown:GetFrameLevel()+2)
    --button count
    button.Count:SetParent(button.countFrame)
    button.Count:ClearAllPoints()
    button.Count:SetPoint("TOPRIGHT", 4, 4)
    button.Count:SetTextColor(0.9,0.9,0.9)
    --fix fontsize to be based on button size
    button.Count:SetFont(font,size/1.8,"THINOUTLINE")
    button.Overlay:SetTexture(ns.mediapath.."gloss2")
    button.Overlay:SetTexCoord(0,1,0,1)
    button.Overlay:SetPoint("TOPLEFT", -1, 1)
    button.Overlay:SetPoint("BOTTOMRIGHT", 1, -1)
    button.Overlay:SetVertexColor(0.4,0.35,0.35,1)
    button.Overlay:Show()
    button.Overlay.Hide = function() end
    local back = button:CreateTexture(nil, "BACKGROUND", nil, 0)
    back:SetPoint("TOPLEFT",button.Icon,"TOPLEFT",-0.18*size,0.18*size)
    back:SetPoint("BOTTOMRIGHT",button.Icon,"BOTTOMRIGHT",0.18*size,-0.18*size)
    back:SetTexture(ns.mediapath.."simplesquare_glow")
    back:SetVertexColor(0, 0, 0, 1)
  end

    --create aura watch func
func.createAuraWatch = function(self)
    local auras = {}
    local spellIDs = {}
    
    if self.cfg.aurawatch.spellIds.ALL then
        for _, id in ipairs(self.cfg.aurawatch.spellIds.ALL) do
            table.insert(spellIDs, id)
        end
    end
    
    if self.cfg.aurawatch.spellIds[ns.player.class] then
        for _, id in ipairs(self.cfg.aurawatch.spellIds[ns.player.class]) do
            table.insert(spellIDs, id)
        end
    end
    
    auras.onlyShowPresent = self.cfg.aurawatch.onlyShowPresent
    auras.presentAlpha = self.cfg.aurawatch.alpha
        
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
        icon:SetFrameStrata("TOOLTIP")
        icon.spellID = sid
                    
        local setup = {size = self.cfg.aurawatch.size, pos = self.cfg.aurawatch.pos.a1, x = self.cfg.aurawatch.pos.x * i, y = self.cfg.aurawatch.pos.y}
        -- set the dimensions and positions
        icon.size = setup.size
        icon:SetSize(setup.size,setup.size)
        --position icon
        icon:SetPoint("CENTER", self, self.cfg.aurawatch.pos.a1, self.cfg.aurawatch.pos.x + ((i-1) * self.cfg.aurawatch.size), self.cfg.aurawatch.pos.y)
        --make indicator
        --if dir[i].indicator then
        local tex = icon:CreateTexture(nil, "BACKGROUND", nil, 1)
            tex:SetAllPoints()
            tex:SetTexture(C_Spell.GetSpellTexture(sid))
            --tex:SetVertexColor(dir[i].color.r,dir[i].color.g,dir[i].color.b)
            icon.icon = tex
        
            auras.icons[sid] = icon
    -- Set any other AuraWatch icon settings
    end
    --call aurawatch
    self.AuraWatch = auras
end


  --update health func
  func.updateHealth = function(bar, unit, min, max)
  
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
    --elseif cfg.colorswitcher.threatColored and unit and UnitThreatSituation(unit) == 3 then
      --color = { r = 1, g = 0, b = 0, }
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
      bar.highlight:SetAlpha(0)
      if cfg.colorswitcher.useBrightForeground then
        bar.glow:SetVertexColor(1,0,0,0.6)
        bar:SetStatusBarColor(1,0,0,1)
        bar.bg:SetVertexColor(0.2,0,0,0.9)
      else
        bar.glow:SetVertexColor(1,0,0,1)
      end
    elseif (not bar.buffOverride) then
      --inner shadow
        if (bar.glow) then
            bar.glow:SetVertexColor(0,0,0,0.7)
        end
        if (bar.highlight) then
            bar.highlight:SetAlpha(cfg.highlightMultiplier)
        end
    end
    --bar.highlight:SetAlpha((min/max)*cfg.highlightMultiplier)
  end

  --update power func
  func.updatePower = function(bar, unit, min, max)
    local color = cfg.powercolors[select(2, UnitPowerType(unit))]
    if not color then
      --prevent powertype from bugging out on certain encounters.
      color = {r=1,g=0.5,b=0.25}
    end
      bar:SetStatusBarColor(color.r, color.g, color.b,1) 
      bar.bg:SetVertexColor(color.r, color.g, color.b,0.2)
  end

  --debuffglow
  func.createDebuffGlow = function(self)
    local t = self:CreateTexture(nil,"BACKGROUND",nil,-5)
    if self.cfg.style == "target" then
      t:SetTexture(ns.mediapath.."target_debuffglow")
    else
      t:SetTexture(ns.mediapath.."targettarget_debuffglow")
    end
	if self.cfg.style == "party" then
		if cfg.units.party.vertical == true then
			t:SetPoint("TOP",0,29)
			t:SetPoint("LEFT",0,0)
			t:SetPoint("RIGHT",0,0)
			t:SetPoint("BOTTOM",0,-10)
		else
			t:SetPoint("TOP",0,19)
			t:SetPoint("LEFT",0,0)
			t:SetPoint("RIGHT",0,0)
			t:SetPoint("BOTTOM",0,-15)
		end
	elseif self.cfg.style == "target" then
		t:SetPoint("TOP",0,25)
		t:SetPoint("LEFT",-60,0)
		t:SetPoint("RIGHT",60,0)
		t:SetPoint("BOTTOM",0,-15)
	else
		t:SetAllPoints()
	end
    t:SetBlendMode("BLEND")
    t:SetVertexColor(0, 1, 1, 0) -- set alpha to 0 to hide the texture
    self.DebuffHighlight = t
    self.DebuffHighlightAlpha = 1
    self.DebuffHighlightFilter = false
  end

  --check threat
  func.checkThreat = function(self,event,unit)
    if unit then
      if self.unit ~= unit then return end
      local threat = UnitThreatSituation(unit)
      if(threat and threat > 0) then
        local r, g, b = GetThreatStatusColor(threat)
        if self.Border then
          self.Border:SetVertexColor(r,g,b)
          self.PortraitBack:SetVertexColor(r,g,b,1)
        end
      else
        if self.Border then
          self.Border:SetVertexColor(0.6,0.5,0.5)
          self.PortraitBack:SetVertexColor(0.1,0.1,0.1,0.9)
        end
      end
    end
  end

  --create portrait func
  func.createPortrait = function(self)
  

    local back = CreateFrame("Frame",nil,self)
    back:SetSize(self.cfg.width,self.cfg.width)
	
	if self.cfg.style == "party" then
		if cfg.units.party.vertical == false then
			back:SetPoint("BOTTOM", self, "TOP", 0, -35)
		else
			back:SetPoint("BOTTOM", self, "LEFT", 10, -38)
		end
	else 
		back:SetPoint("BOTTOM", self, "TOP", 0, -35)
	end
    self.PortraitHolder = back

    local t = back:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(back)
    t:SetTexture(ns.mediapath.."portrait_back")
    t:SetVertexColor(0.1,0.1,0.1,0.9)
    self.PortraitBack = t

	if self.cfg.style == "party" then
		if self.cfg.portrait.use3D then
			self.Portrait = CreateFrame("PlayerModel", nil, back)
			self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",22,-20)
			self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-19,21)

			local borderholder = CreateFrame("Frame", nil, self.Portrait)
				borderholder:SetAllPoints(back)
				self.BorderHolder = borderholder

			local border = borderholder:CreateTexture(nil,"BACKGROUND",nil,-6)
				border:SetAllPoints(borderholder)
				border:SetTexture(ns.mediapath.."portrait_border")
				border:SetVertexColor(0.6,0.5,0.5)
				--border:SetVertexColor(1,0,0,1) --threat test
				self.Border = border

			local gloss = borderholder:CreateTexture(nil,"BACKGROUND",nil,-5)
				gloss:SetAllPoints(borderholder)
				gloss:SetTexture(ns.mediapath.."portrait_gloss")
				gloss:SetVertexColor(0.9,0.95,1,0.6)

		else
			self.Portrait = back:CreateTexture(nil,"BACKGROUND",nil,-7)
			self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",21,-21)
			self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-21,21)
			self.Portrait:SetTexCoord(0.15,0.85,0.15,0.85)

			local border = back:CreateTexture(nil,"BACKGROUND",nil,-6)
				border:SetAllPoints(back)
				border:SetTexture(ns.mediapath.."portrait_border")
				border:SetVertexColor(0.6,0.5,0.5)
				self.Border = border

			local gloss = back:CreateTexture(nil,"BACKGROUND",nil,-5)
				gloss:SetAllPoints(back)
				gloss:SetTexture(ns.mediapath.."portrait_gloss")
				gloss:SetVertexColor(0.9,0.95,1,0.6)

		end
	else
		if self.cfg.portrait.use3D then
			self.Portrait = CreateFrame("PlayerModel", nil, back)
			self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",27,-27)
			self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-27,27)

			local borderholder = CreateFrame("Frame", nil, self.Portrait)
				borderholder:SetAllPoints(back)
				self.BorderHolder = borderholder

			local border = borderholder:CreateTexture(nil,"BACKGROUND",nil,-6)
				border:SetAllPoints(borderholder)
				border:SetTexture(ns.mediapath.."portrait_border")
				border:SetVertexColor(0.6,0.5,0.5)
				--border:SetVertexColor(1,0,0,1) --threat test
				self.Border = border

			local gloss = borderholder:CreateTexture(nil,"BACKGROUND",nil,-5)
				gloss:SetAllPoints(borderholder)
				gloss:SetTexture(ns.mediapath.."portrait_gloss")
				gloss:SetVertexColor(0.9,0.95,1,0.6)

		else
			self.Portrait = back:CreateTexture(nil,"BACKGROUND",nil,-7)
			self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",27,-27)
			self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-27,27)
			self.Portrait:SetTexCoord(0.15,0.85,0.15,0.85)

			local border = back:CreateTexture(nil,"BACKGROUND",nil,-6)
				border:SetAllPoints(back)
				border:SetTexture(ns.mediapath.."portrait_border")
				border:SetVertexColor(0.6,0.5,0.5)
				self.Border = border

			local gloss = back:CreateTexture(nil,"BACKGROUND",nil,-5)
				gloss:SetAllPoints(back)
				gloss:SetTexture(ns.mediapath.."portrait_gloss")
				gloss:SetVertexColor(0.9,0.95,1,0.6)

		end	
	end
		
	if self.cfg.vertical == true then
    self.Name:SetPoint("CENTER", 0, 0)
	else
	self.Name:SetPoint("BOTTOM", self, "TOP", 0, self.cfg.width-53)
	end

  end

  --create standalone portrait func
  func.createStandAlonePortrait = function(self)

    local fname
    if self.cfg.style == "player" then
      fname = "Roth_UIPlayerPortrait"
    elseif self.cfg.style == "target" then
      fname = "Roth_UITargetPortrait"
    end

    local pcfg = self.cfg.portrait

    local back = CreateFrame("Frame",fname,self)
    back:SetSize(pcfg.size,pcfg.size)
    back:SetPoint(pcfg.pos.a1,pcfg.pos.af,pcfg.pos.a2,pcfg.pos.x,pcfg.pos.y)

    func.applyDragFunctionality(back)

    local t = back:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(back)
    t:SetTexture(ns.mediapath.."portrait_back")
    t:SetVertexColor(0.1,0.1,0.1,0.9)

    if pcfg.use3D then
      self.Portrait = CreateFrame("PlayerModel", nil, back)
      self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",pcfg.size*27/128,-pcfg.size*27/128)
      self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-pcfg.size*27/128,pcfg.size*27/128)

      local borderholder = CreateFrame("Frame", nil, self.Portrait)
      borderholder:SetAllPoints(back)

      local border = borderholder:CreateTexture(nil,"BACKGROUND",nil,-6)
      border:SetAllPoints(borderholder)
      border:SetTexture(ns.mediapath.."portrait_border")
      border:SetVertexColor(0.6,0.5,0.5)

      local gloss = borderholder:CreateTexture(nil,"BACKGROUND",nil,-5)
      gloss:SetAllPoints(borderholder)
      gloss:SetTexture(ns.mediapath.."portrait_gloss")
      gloss:SetVertexColor(0.9,0.95,1,0.6)

    else
      self.Portrait = back:CreateTexture(nil,"BACKGROUND",nil,-7)
      self.Portrait:SetPoint("TOPLEFT",back,"TOPLEFT",pcfg.size*27/128,-pcfg.size*27/128)
      self.Portrait:SetPoint("BOTTOMRIGHT",back,"BOTTOMRIGHT",-pcfg.size*27/128,pcfg.size*27/128)
      self.Portrait:SetTexCoord(0.15,0.85,0.15,0.85)

      local border = back:CreateTexture(nil,"BACKGROUND",nil,-6)
      border:SetAllPoints(back)
      border:SetTexture(ns.mediapath.."portrait_border")
      border:SetVertexColor(0.6,0.5,0.5)

      local gloss = back:CreateTexture(nil,"BACKGROUND",nil,-5)
      gloss:SetAllPoints(back)
      gloss:SetTexture(ns.mediapath.."portrait_gloss")
      gloss:SetVertexColor(0.9,0.95,1,0.6)

    end

  end

-- Roth D3 minimal icon skin
-- Uses:
--  - Interface\\AddOns\\Roth_UI\\media\\simplesquare_roth
--  - Interface\\AddOns\\Roth_UI\\media\\simplesquare_glow (optional)
--
-- Call once per icon frame:
--   ns.SkinIconMinimal(button, button.icon, { size = 28 })

function ns.SkinIconMinimal(f, icon, opt)
  if f.__rothSkinned then return end
  f.__rothSkinned = true

  opt = opt or {}

  -- Tuning knobs (safe defaults)
  local inset     = opt.inset or 3
  local bgAlpha   = opt.bgAlpha or 0.72
  local useGlow   = (opt.glow ~= false) -- default true
  local crop      = opt.crop or 0.07    -- 0.07 looks good for most icons

  -- Crop icon so Blizzard’s baked borders don’t show
  icon:ClearAllPoints()
  icon:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset)
  icon:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
  icon:SetTexCoord(crop, 1 - crop, crop, 1 - crop)
  icon:SetAlpha(0.92)

  -- Dark backing (gives depth, avoids “flat sticker” look)
  local bg = f:CreateTexture(nil, "BACKGROUND", nil, -8)
  bg:SetAllPoints(icon)
  bg:SetColorTexture(0, 0, 0, bgAlpha)
  f._rothBG = bg

  -- Minimal frame (stone/metal look)
  local frame = f:CreateTexture(nil, "BORDER", nil, 2)
  frame:SetAllPoints(f)
  frame:SetTexture("Interface\\AddOns\\Roth_UI\\media\\simplesquare_roth")
  frame:SetVertexColor(0.65, 0.60, 0.55)
  f._rothFrame = frame
  
  -- after you create f._rothFrame
  local hi = f:CreateTexture(nil, "BORDER", nil, 1)
  hi:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
  hi:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
  hi:SetColorTexture(1, 1, 1, 0.06)  -- tiny bevel highlight
  f._rothHi = hi
  
  local sh = f:CreateTexture(nil, "BACKGROUND", nil, -8)
  sh:SetPoint("TOPLEFT", f, "TOPLEFT", -3, 3)
  sh:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 3, -3)
  sh:SetTexture("Interface\\AddOns\\Roth_UI\\media\\border") -- or simplesquare_glow if border is too sharp
  sh:SetVertexColor(0, 0, 0, 0.35)
  f._rothShadow = sh
  
  local vignette = f:CreateTexture(nil, "ARTWORK", nil, -1)
  vignette:SetAllPoints(f.icon)
  vignette:SetColorTexture(0, 0, 0, 0.10)  -- subtle, raises contrast
  f._rothVignette = vignette

  -- Optional glow (keep it subtle; show only for “important” states)
  if useGlow then
    local glow = f:CreateTexture(nil, "ARTWORK", nil, 3)
    glow:SetAllPoints(f)
    glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\simplesquare_glow")
    glow:SetAlpha(opt.glowAlpha or 0.9)
    glow:Hide()
    f._rothGlow = glow
  end
end

  --create castbar func
  func.createCastbar = function(f)
	local frame = CreateFrame("Frame", "$parentCastBarDragFrame", f)
	frame:SetPoint(f.cfg.castbar.pos.a1, f.cfg.castbar.pos.af, f.cfg.castbar.pos.a2, f.cfg.castbar.pos.x+8, f.cfg.castbar.pos.y)
	frame:SetSize(100,10)
    local c = CreateFrame("StatusBar", "$parentCastbar", frame)
    --wow is this outdated...man I really need to rewrite how the drag stuff is handled
    tinsert(Roth_UI_Bars,frame:GetName())
    c:SetSize(265,15)
    c:SetStatusBarTexture(f.cfg.castbar.texture)
    c:SetScale(f.cfg.castbar.scale)
    c:SetPoint("CENTER", frame, 0,0)
	c:SetFrameStrata("HIGH")
    c:SetStatusBarColor(f.cfg.castbar.color.bar.r,f.cfg.castbar.color.bar.g,f.cfg.castbar.color.bar.b,f.cfg.castbar.color.bar.a)
    --c:SetStatusBarColor(0,0,0,1)

    c.background = c:CreateTexture(nil,"OVERLAY",nil,-8)
    c.background:SetTexture(ns.mediapath.."castbar")
    c.background:SetPoint("TOP",0,24.9)
    c.background:SetPoint("LEFT",-170,0)
    c.background:SetPoint("RIGHT",170,0)
    c.background:SetPoint("BOTTOM",0,-24.2)

    c.bg = c:CreateTexture(nil,"BACKGROUND",nil,-6)
    c.bg:SetTexture(f.cfg.castbar.texture)
    c.bg:SetAllPoints(c)
    c.bg:SetVertexColor(f.cfg.castbar.color.bg.r,f.cfg.castbar.color.bg.g,f.cfg.castbar.color.bg.b,f.cfg.castbar.color.bg.a)

    c.Text =  func.createFontString(c, cfg.fonts.textFont, f.cfg.castbar.fontSize, "THINOUTLINE")
    c.Text:SetPoint("LEFT", 5, 0)
    c.Text:SetJustifyH("LEFT")

    c.Time =  func.createFontString(c, cfg.fonts.textFont, f.cfg.castbar.fontSize, "THINOUTLINE")
    c.Time:SetPoint("RIGHT", -2, 0)

    c.Text:SetPoint("RIGHT", -50, 0)
    --c.Text:SetPoint("RIGHT", c.Time, "LEFT", -10, 0) --right point of text will anchor left point of time


    c.Spark = c:CreateTexture(nil,"OVERLAY",nil,-7)
    c.Spark:SetBlendMode("ADD")
    c.Spark:SetVertexColor(0.8,0.6,0,1)

    c.glow = c:CreateTexture(nil, "OVERLAY",nil,-4)
    c.glow:SetTexture(ns.mediapath.."castbar_glow")
    c.glow:SetPoint("TOP",0,26.5)
    c.glow:SetPoint("LEFT",-35,0)
    c.glow:SetPoint("RIGHT",35,0)
    c.glow:SetPoint("BOTTOM",0,-24.2)
    c.glow:SetVertexColor(0,0,0,1)

    c.highlight = c:CreateTexture(nil,"OVERLAY",nil,-3)
    c.highlight:SetTexture(ns.mediapath.."castbar_highlight")
    c.highlight:SetPoint("TOP",0,26.5)
    c.highlight:SetPoint("LEFT",-35,0)
    c.highlight:SetPoint("RIGHT",35,0)
    c.highlight:SetPoint("BOTTOM",0,-24.2)
	

    if f.cfg.style == "target" then
      c.Shield = c:CreateTexture(nil,"BACKGROUND",nil,-8)
      c.Shield:SetColorTexture(0,0,0,0)
    end

    --safezone
    if f.cfg.style == "player" and f.cfg.castbar.latency then
      c.SafeZone = c:CreateTexture(nil,"OVERLAY")
      c.SafeZone:SetTexture(f.cfg.castbar.texture)
      c.SafeZone:SetVertexColor(0.6,0,0,0.6)
      c.SafeZone:SetPoint("TOPRIGHT")
      c.SafeZone:SetPoint("BOTTOMRIGHT")
    end

    if f.cfg.style == "player" then
      c.PostUpdateStage = func.PostUpdateStage
      c.cfg = f.cfg
    end
    func.applyDragFunctionality(frame)

    f.Castbar = c

  end

  func.PostUpdateStage = function(self, stage)
    if (stage == 1) then
      self:SetStatusBarColor(1, 0, 0)
    elseif (stage == 2) then
      self:SetStatusBarColor(0, 0, 1)
    elseif (stage == 3) then
      self:SetStatusBarColor(self.cfg.castbar.color.bar.r,self.cfg.castbar.color.bar.g,self.cfg.castbar.color.bar.b,self.cfg.castbar.color.bar.a)
    end
  end
  
  --fontstring func
  func.createFontString = function(f, font, size, outline,layer)
    local fs = f:CreateFontString(nil, layer or "OVERLAY")
    local fontPath = ns.Media.Font(font)
    fs:SetFont(fontPath, size, outline)
    fs:SetShadowColor(0,0,0,1)
    return fs
  end

  --allows frames to become movable but frames can be locked or set to default positions
  func.applyDragFunctionality = function(f,special)
    --save the default position
    local getPoint = function(self)
      local pos = {}
      pos.a1, pos.af, pos.a2, pos.x, pos.y = self:GetPoint()
      if pos.af and pos.af:GetName() then pos.af = pos.af:GetName() end
      return pos
    end
    f.defaultPosition = getPoint(f)
    --new form of dragframe
    local df = CreateFrame("Frame",nil,f)
    df:SetAllPoints(f)
    df:SetFrameStrata("HIGH")
    --df:SetHitRectInsets(-15,-15,-15,-15)
    df:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:GetParent():StartMoving() end end)
    df:SetScript("OnDragStop", function(self) 
        self:GetParent():StopMovingOrSizing()
            if InCombatLockdown() then return end
            local f = self:GetParent()
            local a1, af, a2, x, y = f:GetPoint(1)
            local afName = (af and af.GetName and af:GetName()) or "UIParent"
        
            -- IMPORTANT: mutate the existing pos table so it persists cleanly
            if not f.cfg then return end
            local pos = f.cfg.pos
            pos.a1, pos.af, pos.a2, pos.x, pos.y = a1, afName, a2, x, y
        end)
    local t = df:CreateTexture(nil,"OVERLAY",nil,6)
    t:SetAllPoints(df)
    t:SetColorTexture(0,1,0)
    t:SetAlpha(0.2)
    df.texture = t
    f.dragframe = df
    f.dragframe:Hide()
    if not special then
      f:SetClampedToScreen(true)
    end
    if not cfg.framesUserplaced then
      f:SetMovable(false)
    else
      f:SetMovable(true)
      f:SetUserPlaced(true)
      if not cfg.framesLocked then
        f.dragframe:Show()
        f.dragframe:EnableMouse(true)
        f.dragframe:RegisterForDrag("LeftButton")
        f.dragframe:SetScript("OnEnter", function(s)
          GameTooltip:SetOwner(s, "ANCHOR_TOP")
          GameTooltip:AddLine(s:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
          GameTooltip:AddLine("Hold down SHIFT to drag!", 1, 1, 1, 1, 1, 1)
          GameTooltip:Show()
        end)
        f.dragframe:SetScript("OnLeave", function(s) GameTooltip:Hide() end)
      end
    end
    --print(f:GetName())
    --print(f:IsUserPlaced())
  end

  --simple frame movement
  func.simpleDragFunc = function(f)

    f:SetHitRectInsets(-15,-15,-15,-15)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetUserPlaced(true)

    f:EnableMouse(true)

    f:RegisterForDrag("LeftButton")
    --[[
    f:SetScript("OnEnter", function(s)
      GameTooltip:SetOwner(s, "ANCHOR_CURSOR")
      GameTooltip:AddLine(s:GetName(), 0, 1, 0.5, 1, 1, 1)
      GameTooltip:AddLine("Hold down ALT+SHIFT to drag!", 1, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(s) GameTooltip:Hide() end)
    ]]--
    --f:SetScript("OnDragStart", function(s) if IsAltKeyDown() and IsShiftKeyDown() then s:StartMoving() end end)
    f:SetScript("OnDragStart", function(s) s:StartMoving() end)
    f:SetScript("OnDragStop", function(s) s:StopMovingOrSizing() end)

  end

  --create icon func
  func.createIcon = function(f,layer,size,anchorframe,anchorpoint1,anchorpoint2,posx,posy,sublevel)
    local icon = f:CreateTexture(nil,layer,nil,sublevel)
    icon:SetSize(size,size)
    icon:SetPoint(anchorpoint1,anchorframe,anchorpoint2,posx,posy)
    return icon
  end

func.healPrediction = function(self)
  if not self.cfg.healprediction
    or (self.cfg.healprediction and not self.cfg.healprediction.show)
    or Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC)
  then return end

  local cfg = self.cfg.healprediction

  -- Use the actual filled part of the healthbar
  local healthTex = self.Health:GetStatusBarTexture()
  if not healthTex then return end

  local w = self.Health:GetWidth()
  if w == 0 then
    w = self:GetWidth() - 24.5 - 24.5
  end

  local overflow = math.floor(w * ((self.cfg.healprediction.maxoverflow or 1.25) -1 ))
  -- my heals
  local mhpb = CreateFrame("StatusBar", nil, self.Health)
  mhpb:SetFrameLevel(self.Health:GetFrameLevel())
  mhpb:SetStatusBarTexture(cfg.texture)
  mhpb:SetStatusBarColor(cfg.color.myself.r, cfg.color.myself.g, cfg.color.myself.b, cfg.color.myself.a)
  mhpb:SetOrientation(self.Health:GetOrientation() or "HORIZONTAL")
  mhpb:SetReverseFill(self.Health:GetReverseFill() or false)

  mhpb:SetPoint("TOP", self.Health)
  mhpb:SetPoint("BOTTOM", self.Health)
  mhpb:SetPoint("LEFT", healthTex, "RIGHT", 0, 0)
  mhpb:SetWidth(w + overflow)

  -- other heals (stack after my heals)
  local ohpb = CreateFrame("StatusBar", nil, self.Health)
  ohpb:SetFrameLevel(self.Health:GetFrameLevel())
  ohpb:SetStatusBarTexture(cfg.texture)
  ohpb:SetStatusBarColor(cfg.color.other.r, cfg.color.other.g, cfg.color.other.b, cfg.color.other.a)
  ohpb:SetOrientation(self.Health:GetOrientation() or "HORIZONTAL")
  ohpb:SetReverseFill(self.Health:GetReverseFill() or false)

  ohpb:SetPoint("TOP", self.Health)
  ohpb:SetPoint("BOTTOM", self.Health)
  ohpb:SetPoint("LEFT", mhpb:GetStatusBarTexture(), "RIGHT", 0, 0)
  ohpb:SetWidth(w + overflow)
  
  self.HealthPrediction = {
    myBar = mhpb,
    otherBar = ohpb,
    maxOverflow = cfg.maxoverflow,
  }
  
  self.Health:SetClipsChildren(false)

end

--========================================================
-- Heal Prediction Crescent for PLAYER HEALTH ORB
-- Drop-in replacement for your healPredictionOrb code
--========================================================

-- Put this in the same file/section where you define other ns.func helpers.
-- Assumes:
--   - self.Health is the orb StatusBar (VERTICAL) for the player's health orb
--   - self.cfg.size exists (orb size)
--   - self.cfg.healprediction exists (at least .show, .color, .maxoverflow optional)
--   - You already have your "values" frame (the same parent you used for TotalAbsorb),
--     but this code will fall back safely if not.

local addon, ns = ...
local func = ns.func

local function HPOrb_GetTotalIncoming(unit)
  -- Retail + Wrath+ Classic: UnitGetIncomingHeals exists
  if UnitGetIncomingHeals then
    return UnitGetIncomingHeals(unit) or 0
  end
  return 0
end

local function HPOrb_Update(self)
  local hp = (UnitHealth(self.unit) or 0)
  local maxhp = (UnitHealthMax(self.unit) or 0)
  local inc = HPOrb_GetTotalIncoming(self.unit)

  local element = self.OrbHealPrediction
  if not element or maxhp <= 0 then return end

  -- Hide when full HP or no incoming
  if hp >= maxhp or inc <= 0 then
    element:Hide()
    return
  end

  local maxOverflow = element.maxOverflow or 1.05
  local predicted = hp + inc

  -- Overheal indicator (anything beyond maxhp)
  local willOverheal = predicted > maxhp

  -- Cap predicted to overflow limit so visuals stay sane
  local cap = maxhp * maxOverflow
  if predicted > cap then predicted = cap end

  -- We render a "new health value" crescent:
  -- fraction can exceed 1.0, but the crescent artwork itself can't extend beyond the orb,
  -- so we clamp the visible fill to 1.0 and use a separate indicator for overheal.
  local f = predicted / maxhp
  local fVisual = math.min(math.max(f, 0), 1)

  -- Critical fix:
  -- DO NOT resize/scale the crescent texture itself (that causes the morphing tips).
  -- Instead, keep the texture full-size and only change the CLIP WINDOW height.
  local H = element._h or element:GetHeight() or (self.cfg.size - 5)
  element._h = H

  element.clip:SetHeight(H * fVisual)

  -- Overheal indicator
  if element.overTex then
    if willOverheal then
      element.overTex:Show()
    else
      element.overTex:Hide()
    end
  end

  -- Slightly brighten when overhealing (optional, still subtle)
  if element.fillTex then
    if willOverheal then
      element.fillTex:SetVertexColor(element.colOver.r, element.colOver.g, element.colOver.b, element.colOver.a)
    else
      element.fillTex:SetVertexColor(element.colNorm.r, element.colNorm.g, element.colNorm.b, element.colNorm.a)
    end
  end

  element:Show()
end

-- Call this from your player-orb creation after self.Health exists (orb fill statusbar)
func.healPredictionOrb = function(self, parentFrameForOverlay)
  local cfg = self.cfg and self.cfg.healprediction
  if not cfg or not cfg.show then return end

  -- If you want to disable on some versions, do it here.
  -- (You previously had "not classic" checks; heal prediction *does* exist on Wrath+,
  -- and on many Classic clients. If you want to restrict, add your version check.)
  if not self.unit then self.unit = "player" end

  -- Pick a sane parent for the crescent.
  -- Best: the same overlay parent you used for TotalAbsorb (your "values" frame).
  local parent = parentFrameForOverlay
              or (self.Health and self.Health:GetParent())
              or self

  -- Prevent double-creation
  if self.OrbHealPrediction then
    self.OrbHealPrediction:Show()
    HPOrb_Update(self)
    return
  end

  local size = (self.cfg and self.cfg.size) or 128
  local pad = 5

  -- Container: lock it exactly like your absorb glow frame is locked.
  -- You said you can fix the side; default to RIGHT side here.
  local healPred = CreateFrame("Frame", nil, parent)
  healPred:SetSize(size - pad, size - pad)
  healPred:SetPoint("CENTER", 0, 0)
  healPred:Hide()

  -- You can adjust these anchors to match your absorb-bar's "fixed to side" positioning:
  -- healPred:ClearAllPoints()
  -- healPred:SetPoint("CENTER", parent, "CENTER", 0, 0)

  -- Background (dark green) - fixed, like your absorb bg glow
  local bg = healPred:CreateTexture(nil, "BACKGROUND", nil, -8)
  bg:SetAllPoints()
  bg:SetTexture("Interface\\AddOns\\Roth_UI\\media\\orb_absorb_glow") -- reuse your glow art
  bg:SetVertexColor(0, 1, 0, 1)
  bg:SetAlpha(0.18)
  bg:SetTexCoord(1,0,0,1)
  healPred.bg = bg

  -- Clip window (THIS is what changes height)
  local clip = CreateFrame("Frame", nil, healPred)
  clip:SetPoint("BOTTOMLEFT")
  clip:SetPoint("BOTTOMRIGHT")
  clip:SetHeight(0)
  clip:SetClipsChildren(true)
  healPred.clip = clip

  -- Full-size fill texture (NEVER resized)
  local fill = clip:CreateTexture(nil, "ARTWORK", nil, -8)
  fill:SetAllPoints(healPred) -- note: larger than clip region; clip reveals it
  fill:SetTexture("Interface\\AddOns\\Roth_UI\\media\\orb_absorb_glow") -- replace with your crescent art if desired
  fill:SetTexCoord(1,0,0,1)
  healPred.fillTex = fill

  -- Overheal indicator (small spark at top)
  local over = healPred:CreateTexture(nil, "OVERLAY", nil, -7)
  over:SetTexture("Interface\\AddOns\\Roth_UI\\media\\orb_spark") -- reuse your spark art
  over:SetPoint("TOP", healPred, "TOP", 0, -2)
  over:SetSize((size - pad) * 0.9, (size - pad) * 0.15)
  over:SetBlendMode("ADD")
  over:SetVertexColor(0.4, 1.0, 0.4, 0.9)
  over:Hide()
  healPred.overTex = over

  -- Colors (defaults if not configured)
  local colMy = (cfg.color and cfg.color.myself) or { r = 0.2, g = 1, b = 0.2, a = 0.55 }
  healPred.colNorm = { r = colMy.r or 0.2, g = colMy.g or 1, b = colMy.b or 0.2, a = colMy.a or 0.55 }
  healPred.colOver = { r = 0.4, g = 1.0, b = 0.4, a = math.min((healPred.colNorm.a or 0.55) + 0.2, 1) }

  healPred.maxOverflow = cfg.maxoverflow or cfg.maxOverflow or 1.05

  -- Start color
  fill:SetVertexColor(healPred.colNorm.r, healPred.colNorm.g, healPred.colNorm.b, healPred.colNorm.a)

  -- Save & hook updates
  self.OrbHealPrediction = healPred

  -- Events that can change prediction without HP changing:
  -- UNIT_HEAL_PREDICTION is the key one.
  self:RegisterEvent("UNIT_HEAL_PREDICTION", function(_, _, unit)
    if unit == self.unit then HPOrb_Update(self) end
  end)

  -- Still listen to health/maxhealth so it stays correct
  self:RegisterEvent("UNIT_HEALTH", function(_, _, unit)
    if unit == self.unit then HPOrb_Update(self) end
  end)
  self:RegisterEvent("UNIT_MAXHEALTH", function(_, _, unit)
    if unit == self.unit then HPOrb_Update(self) end
  end)

  -- Initial update
  HPOrb_Update(self)
end




  --total absorb
  func.totalAbsorb = function(self)
    if not self.cfg.totalabsorb or (self.cfg.totalabsorb and not self.cfg.totalabsorb.show) or Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then return end
	
    local w = self.Health:GetWidth()
	
	if self.cfg.style == "party" then
		if cfg.units.party.verical == false then
			if w == 0 then
				w = self:GetWidth()-24.5-24.5 --raids and party have no width on the health frame for whatever reason, thus use self and subtract the setpoint values
			end
		else
			if w == 0 then
				w = self:GetWidth()-60-24.5
			end
		end
	else
		if w == 0 then
			w = self:GetWidth()-24.5-24.5 --raids and party have no width on the health frame for whatever reason, thus use self and subtract the setpoint values
		end
	end
    local absorbBar = CreateFrame("StatusBar", nil, self.Health)
    --new anchorpoint, absorb will now overlay the healthbar from right to left
    absorbBar:SetFrameLevel(self.Health:GetFrameLevel()+1)
    absorbBar:SetPoint("TOPRIGHT", self.Health, 0, 0)
    absorbBar:SetPoint("BOTTOMRIGHT", self.Health, 0, 0)
    absorbBar:SetWidth(w)
    absorbBar:SetStatusBarTexture(self.cfg.totalabsorb.texture)
    absorbBar:SetStatusBarColor(self.cfg.totalabsorb.color.bar.r,self.cfg.totalabsorb.color.bar.g,self.cfg.totalabsorb.color.bar.b,self.cfg.totalabsorb.color.bar.a)    
    absorbBar:SetReverseFill(true)
    -- Register with oUF
    self.TotalAbsorb = absorbBar    
  end
  
--Register LSM media
LSM:Register("border", "RB border", "Interface\\AddOns\\Roth_UI\\media\\5.tga")
LSM:Register("statusbar", "Solid", "Interface\\AddOns\\Roth_UI\\media\\RothBuffs\\Solid.tga")
LSM:Register("statusbar", "Roth_Statusbar1", "Interface\\AddOns\\Roth_UI\\media\\statusbar")
LSM:Register("statusbar", "Roth_Statusbar2", "Interface\\AddOns\\Roth_UI\\media\\statusbar2")
LSM:Register("statusbar", "Roth_Statusbar3", "Interface\\AddOns\\Roth_UI\\media\\statusbar3")
LSM:Register("statusbar", "Roth_Statusbar4", "Interface\\AddOns\\Roth_UI\\media\\statusbar4")
LSM:Register("statusbar", "Roth_Statusbar5", "Interface\\AddOns\\Roth_UI\\media\\statusbar5")
LSM:Register("statusbar", "Roth_Statusbar6", "Interface\\AddOns\\Roth_UI\\media\\statusbar128")
LSM:Register("statusbar", "Roth_Statusbar7", "Interface\\AddOns\\Roth_UI\\media\\statusbar128_3")
LSM:Register("statusbar", "Roth_Statusbar8", "Interface\\AddOns\\Roth_UI\\media\\statusbar256")
LSM:Register("statusbar", "Roth_Statusbar9", "Interface\\AddOns\\Roth_UI\\media\\statusbar256_2")
LSM:Register("statusbar", "Roth_Statusbar10", "Interface\\AddOns\\Roth_UI\\media\\statusbar256_3")
LSM:Register("background", "Solid", "Interface\\AddOns\\Roth_UI\\media\\Solid.tga")
LSM:Register("font", "Cracked", "Interface\\AddOns\\Roth_UI\\media\\Cracked-Narrow.ttf")
LSM:Register("font", "Expressway", "Interface\\AddOns\\Roth_UI\\media\\Expressway.ttf")
