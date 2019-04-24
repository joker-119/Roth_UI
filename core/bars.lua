
  --get the addon namespace
  local addon, ns = ...

  --object container
  local bars = CreateFrame("Frame")
  ns.bars = bars

  --get the functions
  local func = ns.func
  local cfg = ns.cfg
  local barposition = ns.player
  local mediapath = "Interface\\AddOns\\Roth_UI\\media\\"

  ---------------------------------------------
  -- FUNCTIONS
  ---------------------------------------------

  --create the exp bar
  bars.createExpBar = function(self)
    local cfg = self.cfg.expbar
    if not cfg.show then return end

    local w, h = 365, 5

    local f = CreateFrame("StatusBar","Roth_UIExpBar",self)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(2)
    f:SetSize(w,h)
--    f:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
    f:SetScale(cfg.scale)
    f:SetStatusBarTexture(cfg.texture)
    f:SetStatusBarColor(cfg.color.r,cfg.color.g,cfg.color.b)

    local r = CreateFrame("StatusBar",nil,f)
    r:SetAllPoints(f)
    r:SetStatusBarTexture(cfg.texture)
    r:SetStatusBarColor(cfg.rested.color.r,cfg.rested.color.g,cfg.rested.color.b)

    func.applyDragFunctionality(f)

    local t = r:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(r)
    t:SetTexture(cfg.texture)
    t:SetVertexColor(cfg.color.r,cfg.color.g,cfg.color.b,0.3)
    f.bg = t

    f:SetScript("OnEnter", function(s)
      mxp = UnitXPMax("player")
      xp = UnitXP("player")
      rxp = GetXPExhaustion()
      GameTooltip:SetOwner(s, "ANCHOR_TOP")
      GameTooltip:AddLine("Experience / Rested", 0, 1, 0.5, 1, 1, 1)
      if UnitLevel("player") ~= MAX_PLAYER_LEVEL then
        GameTooltip:AddDoubleLine(COMBAT_XP_GAIN, xp.."/"..mxp.." ("..floor((xp/mxp)*1000)/10 .."%)", cfg.color.r,cfg.color.g,cfg.color.b,1,1,1)
        if rxp then
          GameTooltip:AddDoubleLine(TUTORIAL_TITLE26, rxp .." (".. floor((rxp/mxp)*1000)/10 .."%)", cfg.rested.color.r,cfg.rested.color.g,cfg.rested.color.b,1,1,1)
        end
      end
      GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(s) GameTooltip:Hide() end)

    self.Experience = f
    self.Experience.Rested = r

  end

  --create the reputation bar
  bars.createRepBar = function(self)
    local cfg = self.cfg.repbar
    if not cfg.show then return end

    local w, h = 365, 5

    local f = CreateFrame("StatusBar","Roth_UIRepBar",self)
    f:SetFrameStrata("BACKGROUND")
    f:SetFrameLevel(0)
    f:SetSize(w,h)
    f:SetScale(cfg.scale)
    f:SetStatusBarTexture(cfg.texture)
    f:SetStatusBarColor(0,0.7,0)

    func.applyDragFunctionality(f)

    local t = f:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetAllPoints(f)
    t:SetTexture(cfg.texture)
    t:SetVertexColor(0,0.7,0)
    t:SetAlpha(0.3)
    f.bg = t

    f:SetScript("OnEnter", function(s)
      name, standing, minrep, maxrep, value = GetWatchedFactionInfo()
      GameTooltip:SetOwner(s, "ANCHOR_TOP")
      GameTooltip:AddLine("Reputation", 0, 1, 0.5, 1, 1, 1)
      if name then
        GameTooltip:AddDoubleLine(FACTION, name, FACTION_BAR_COLORS[standing].r, FACTION_BAR_COLORS[standing].g, FACTION_BAR_COLORS[standing].b,1,1,1)
        GameTooltip:AddDoubleLine(STANDING, _G["FACTION_STANDING_LABEL"..standing], FACTION_BAR_COLORS[standing].r, FACTION_BAR_COLORS[standing].g, FACTION_BAR_COLORS[standing].b,1,1,1)
        GameTooltip:AddDoubleLine(REPUTATION, value-minrep .."/"..maxrep-minrep.." ("..floor((value-minrep)/(maxrep-minrep)*1000)/10 .."%)", FACTION_BAR_COLORS[standing].r, FACTION_BAR_COLORS[standing].g, FACTION_BAR_COLORS[standing].b,1,1,1)
      end
      GameTooltip:Show()
    end)
    f:SetScript("OnLeave", function(s) GameTooltip:Hide() end)

    self.Reputation = f

  end
  
  --create the Artifact Bar
  bars.createArtifactPowerBar = function(self)
  
	local cfg = self.cfg.ArtifactPower
	if not cfg.show then return end
	
	local w, h = 365, 5
	
	-- Create the Bar Frame
	local f = CreateFrame("StatusBar","Roth_UIArtifactPower",self)
	f:SetFrameStrata("BACKGROUND")
	f:SetFrameLevel(1)
	f:SetSize(w,h)
	f:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
	f:SetScale(cfg.scale)
	f:SetStatusBarTexture(cfg.texture)
	f:SetStatusBarColor(.05,.5,.5)
	
	--Add Drag Functionality
	func.applyDragFunctionality(f)
	
	--Add Text
	local t = f:CreateFontString(nil,"TOOLTIP")
	t:SetPoint("CENTER")
	t:SetFontObject(GameFontHighlight)
	
	--Create Bar Background
	local bg = f:CreateTexture(nil,"BACKGROUND",nil,-8)
	bg:SetAllPoints(f)
	bg:SetTexture(cfg.texture)
	bg:SetVertexColor(.05,.5,.5)
	bg:SetAlpha(0.3)
	f.bg = bg
	
	--Add Mouseover
	f:EnableMouse(true)
	
	--Register with oUF
	self.ArtifactPower = f
end


  --create harmony power bar
  bars.createHarmonyPowerBar = function(self)

    self.Harmony = {}

    local t
    local bar = CreateFrame("Frame","Roth_UIHarmonyPower",self)
    bar.maxOrbs = 6
    local w = 64*(bar.maxOrbs+2) --create the bar for
    local h = 64
    --bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:SetPoint(self.cfg.harmony.pos.a1,self.cfg.harmony.pos.af,self.cfg.harmony.pos.a2,self.cfg.harmony.pos.x,self.cfg.harmony.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)

    --color
    bar.color = self.cfg.harmony.color

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",0,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, bar.maxOrbs do

      local orb = CreateFrame("Frame",nil,bar)
      self.Harmony[i] = orb

      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.85

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_orb_bg")

      --orb filling
      orb.fill = orb:CreateTexture(nil,"BACKGROUND",nil,-6)
      orb.fill:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      orb.fill:SetTexture(mediapath.."combo_orb_fill1")
      orb.fill:SetVertexColor(self.cfg.harmony.color.r,self.cfg.harmony.color.g,self.cfg.harmony.color.b)
      --orb.fill:SetBlendMode("ADD")

      --orb border
      orb.border = orb:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_orb_border")

      --orb glow
      orb.glow = orb:CreateTexture(nil,"BACKGROUND",nil,-4)
      orb.glow:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.glow:SetPoint("CENTER")
      orb.glow:SetTexture(mediapath.."combo_orb_glow")
      orb.glow:SetVertexColor(self.cfg.harmony.color.r,self.cfg.harmony.color.g,self.cfg.harmony.color.b)
      orb.glow:SetBlendMode("BLEND")

      --orb highlight
      orb.highlight = orb:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_orb_highlight")

    end

    bar:SetScale(self.cfg.harmony.scale)
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.harmony.combat.enable then
      rCombatFrameFader(bar, self.cfg.harmony.combat.fadeIn, self.cfg.harmony.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end

    self.HarmonyPowerBar = bar

  end

  --create holy power bar
  bars.createHolyPowerBar = function(self)

    self.HolyPower = {}

    local t
    local bar = CreateFrame("Frame","Roth_UIHolyPower",self)
    bar.maxOrbs = 5
    local w = 64*(bar.maxOrbs+2) --create the bar for
    local h = 64
    --bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:SetPoint(self.cfg.holypower.pos.a1,self.cfg.holypower.pos.af,self.cfg.holypower.pos.a2,self.cfg.holypower.pos.x,self.cfg.holypower.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)

    --color
    bar.color = self.cfg.holypower.color

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",0,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, bar.maxOrbs do

      local orb = CreateFrame("Frame",nil,bar)
      self.HolyPower[i] = orb

      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.85

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_orb_bg")

      --orb filling
      orb.fill = orb:CreateTexture(nil,"BACKGROUND",nil,-6)
      orb.fill:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      orb.fill:SetTexture(mediapath.."combo_orb_fill1")
      orb.fill:SetVertexColor(self.cfg.holypower.color.r,self.cfg.holypower.color.g,self.cfg.holypower.color.b)
      --orb.fill:SetBlendMode("ADD")

      --orb border
      orb.border = orb:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_orb_border")

      --orb glow
      orb.glow = orb:CreateTexture(nil,"BACKGROUND",nil,-4)
      orb.glow:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.glow:SetPoint("CENTER")
      orb.glow:SetTexture(mediapath.."combo_orb_glow")
      orb.glow:SetVertexColor(self.cfg.holypower.color.r,self.cfg.holypower.color.g,self.cfg.holypower.color.b)
      orb.glow:SetBlendMode("BLEND")

      --orb highlight
      orb.highlight = orb:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_orb_highlight")

    end

    bar:SetScale(self.cfg.holypower.scale)
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.holypower.combat.enable then
      rCombatFrameFader(bar, self.cfg.holypower.combat.fadeIn, self.cfg.holypower.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end

    self.HolyPowerBar = bar

  end

  --create soulshard power bar
  bars.createSoulShardPowerBar = function(self)

    self.SoulShards = {}

    local t
    local bar = CreateFrame("Frame","Roth_UISoulShardPower",self)
    bar.maxOrbs = 5
    local w = 64*(bar.maxOrbs+2) --create the bar for
    local h = 64
    --bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:SetPoint(self.cfg.soulshards.pos.a1,self.cfg.soulshards.pos.af,self.cfg.soulshards.pos.a2,self.cfg.soulshards.pos.x,self.cfg.soulshards.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)
    bar:Hide() --hide bar (it will become available if the spec matches)

    --color
    bar.color = self.cfg.soulshards.color

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",64,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, bar.maxOrbs do

      local orb = CreateFrame("Frame",nil,bar)
      self.SoulShards[i] = orb
      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.95

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_gem_bg")

      --orb filling
      orb.fill = orb:CreateTexture(nil,"BACKGROUND",nil,-6)
      orb.fill:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      orb.fill:SetTexture(mediapath.."combo_gem_fill1")
      orb.fill:SetVertexColor(self.cfg.soulshards.color.r,self.cfg.soulshards.color.g,self.cfg.soulshards.color.b)
      --orb.fill:SetBlendMode("ADD")

      --orb border
      orb.border = orb:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_gem_border")

      --orb glow
      orb.glow = orb:CreateTexture(nil,"BACKGROUND",nil,-4)
      orb.glow:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.glow:SetPoint("CENTER")
      orb.glow:SetTexture(mediapath.."combo_gem_glow")
      orb.glow:SetVertexColor(self.cfg.soulshards.color.r,self.cfg.soulshards.color.g,self.cfg.soulshards.color.b)
      orb.glow:SetBlendMode("BLEND")

      --orb highlight
      orb.highlight = orb:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_gem_highlight")

    end

    bar:SetScale(self.cfg.soulshards.scale)
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.soulshards.combat.enable then
      rCombatFrameFader(bar, self.cfg.soulshards.combat.fadeIn, self.cfg.soulshards.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end

    self.SoulShardPowerBar = bar

  end


  --create rune orbs bar
  bars.createRuneBar = function(self)

    self.RuneOrbs = {}

    local t
    local bar = CreateFrame("Frame","Roth_UIRuneBar",self)
    bar.maxOrbs = 6
    local w = 64*(bar.maxOrbs+2) --create the bar for
    local h = 64
    bar:SetPoint(self.cfg.runes.pos.a1,self.cfg.runes.pos.af,self.cfg.runes.pos.a2,self.cfg.runes.pos.x,self.cfg.runes.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)
    bar:Hide() --hide bar (it will become available if the spec matches)

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",0,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, bar.maxOrbs do

      local orb = CreateFrame("Frame",nil,bar)
      self.RuneOrbs[i] = orb
      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.85

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_orb_bg")

      --orb filling
      orb.fill = CreateFrame("StatusBar",nil,orb)
      orb.fill:SetSize(64*orbSizeMultiplier,64*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      local fill = orb.fill:CreateTexture(nil,"BACKGROUND",nil,-6)
      fill:SetTexture(mediapath.."combo_orb_fill64_1")
      orb.fill:SetStatusBarTexture(fill)
      orb.fill:SetOrientation("VERTICAL")

      --stack another frame to correct the texture stacking
      local helper = CreateFrame("Frame",nil,orb.fill)
      helper:SetAllPoints(orb)

      --orb border
      orb.border = helper:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_orb_border")

      --orb glow
      orb.glow = helper:CreateTexture(nil,"BACKGROUND",nil,-4)
      orb.glow:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.glow:SetPoint("CENTER")
      orb.glow:SetTexture(mediapath.."combo_orb_glow")
      orb.glow:SetBlendMode("BLEND")
      orb.glow:Hide()

      --orb highlight
      orb.highlight = helper:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_orb_highlight")

    end

    bar:SetScale(self.cfg.runes.scale)
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.runes.combat.enable then
      rCombatFrameFader(bar, self.cfg.runes.combat.fadeIn, self.cfg.runes.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end
    self.RuneBar = bar

  end
  
 --create combo
  bars.createComboBar = function(self)

    self.ComboPoints = {}
    local class = select(2, UnitClass("player"))
    local t
    local max
    local bar = CreateFrame("Frame","Roth_UIComboPoints",self)
    local w = 64*(MAX_COMBO_POINTS+2)
    local h = 64
    if class == "ROGUE" and select(4, GetTalentInfo(3,2,1)) then
	max = 6
    else
	max = 5
    end
    --bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:SetPoint(self.cfg.combobar.pos.a1,self.cfg.combobar.pos.af,self.cfg.combobar.pos.a2,self.cfg.combobar.pos.x,self.cfg.combobar.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)
    bar:SetScale(self.cfg.combobar.scale)

    --color
    bar.color = self.cfg.combobar.color

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",0,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, max do

      local orb = CreateFrame("Frame",nil,bar)
      self.ComboPoints[i] = orb

      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.85

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_orb_bg")

      --orb filling
      orb.fill = orb:CreateTexture(nil,"BACKGROUND",nil,-6)
      orb.fill:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      orb.fill:SetTexture(mediapath.."combo_orb_fill1")
      orb.fill:SetVertexColor(self.cfg.combobar.color.r,self.cfg.combobar.color.g,self.cfg.combobar.color.b)
      --orb.fill:SetBlendMode("ADD")

      --orb border
      orb.border = orb:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_orb_border")

      --orb glow
      orb.glow = orb:CreateTexture(nil,"BACKGROUND",nil,-4)
      orb.glow:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.glow:SetPoint("CENTER")
      orb.glow:SetTexture(mediapath.."combo_orb_glow")
      orb.glow:SetVertexColor(self.cfg.combobar.color.r,self.cfg.combobar.color.g,self.cfg.combobar.color.b)
      orb.glow:SetBlendMode("BLEND")

      --orb highlight
      orb.highlight = orb:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_orb_highlight")

    end

	
	
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.combobar.combat.enable then
      rCombatFrameFader(bar, self.cfg.combobar.combat.fadeIn, self.cfg.combobar.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end    
    self.ComboBar = bar

  end
			

  --Arcane Charges
  bars.createArcBar = function(self)
	self.ACharges = {}

    local t
    local bar = CreateFrame("Frame","Roth_UIArcanePower",self)
    bar.maxOrbs = 4
    local w = 64*(bar.maxOrbs+2) --create the bar for
    local h = 64
    --bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    bar:SetPoint(self.cfg.arcbar.pos.a1,self.cfg.arcbar.pos.af,self.cfg.arcbar.pos.a2,self.cfg.arcbar.pos.x,self.cfg.arcbar.pos.y)
    bar:SetWidth(w)
    bar:SetHeight(h)
    bar:Hide() --hide bar (it will become available if the spec matches)

    --color
    bar.color = self.cfg.arcbar.color

    --left edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("LEFT",0,0)
    t:SetTexture(mediapath.."combo_left")
    bar.leftEdge = t

    --right edge
    t = bar:CreateTexture(nil,"BACKGROUND",nil,-8)
    t:SetSize(64,64)
    t:SetPoint("RIGHT",65,0)
    t:SetTexture(mediapath.."combo_right")
    bar.rightEdge = t

    for i = 1, bar.maxOrbs do

      local orb = CreateFrame("Frame",nil,bar)
      self.ACharges[i] = orb

      orb:SetSize(64,64)
      orb:SetPoint("LEFT",i*64,0)

      local orbSizeMultiplier = 0.95

      --bar background
      orb.barBg = orb:CreateTexture(nil,"BACKGROUND",nil,-8)
      orb.barBg:SetSize(64,64)
      orb.barBg:SetPoint("CENTER")
      orb.barBg:SetTexture(mediapath.."combo_bar_bg")

      --orb background
      orb.bg = orb:CreateTexture(nil,"BACKGROUND",nil,-7)
      orb.bg:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.bg:SetPoint("CENTER")
      orb.bg:SetTexture(mediapath.."combo_orb_bg")

      --orb filling
      orb.fill = orb:CreateTexture(nil,"BACKGROUND",nil,-6)
      orb.fill:SetSize(64*orbSizeMultiplier,64*orbSizeMultiplier)
      orb.fill:SetPoint("CENTER")
      orb.fill:SetTexture[[Interface\PLAYERFRAME\MageArcaneCharges]]
	  orb.fill:SetTexCoord(0.25, 0.375, 0.5, 0.75)
      --orb.fill:SetBlendMode("ADD")

      --orb border
      orb.border = orb:CreateTexture(nil,"BACKGROUND",nil,-5)
      orb.border:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.border:SetPoint("CENTER")
      orb.border:SetTexture(mediapath.."combo_orb_border")


      --orb highlight
      orb.highlight = orb:CreateTexture(nil,"BACKGROUND",nil,-3)
      orb.highlight:SetSize(128*orbSizeMultiplier,128*orbSizeMultiplier)
      orb.highlight:SetPoint("CENTER")
      orb.highlight:SetTexture(mediapath.."combo_orb_highlight")

    end

    bar:SetScale(self.cfg.arcbar.scale)
    func.applyDragFunctionality(bar)
    --combat fading
    if self.cfg.arcbar.combat.enable then
      rCombatFrameFader(bar, self.cfg.arcbar.combat.fadeIn, self.cfg.arcbar.combat.fadeOut) --frame, buttonList, fadeIn, fadeOut
    end

    self.ArcBar = bar

  end
