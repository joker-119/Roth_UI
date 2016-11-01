
--get the addon namespace
local addon, ns = ...
local addonName, Roth_UI = ...
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
    self:SetFrameStrata("MEDIUM")
    self:SetFrameLevel(1)
    self:SetSize(self.cfg.width, self.cfg.height)
    self:SetScale(Roth_UI.db.char.target.scale)
    self:SetPoint(self.cfg.pos.a1,self.cfg.pos.af,self.cfg.pos.a2, Roth_UI.db.char.target.xpos, Roth_UI.db.char.target.ypos)
    self:RegisterForClicks("AnyDown")
    self:SetScript("OnEnter", UnitFrame_OnEnter)
    self:SetScript("OnLeave", UnitFrame_OnLeave)
    func.applyDragFunctionality(self)
    self:SetHitRectInsets(10,10,10,10)
    self:RegisterEvent("PLAYER_TARGET_CHANGED")
    ZoneTextFrame:SetFrameStrata("HIGH")
    SubZoneTextFrame:SetFrameStrata("HIGH")
end

  --Target Frame
local createArtwork = function(self)
    local t = self:CreateTexture(nil,"LOW",nil,-8)
    t:SetPoint("TOP",0,25)
    t:SetPoint("LEFT",-62,0)
    t:SetPoint("RIGHT",60,0)
    t:SetPoint("BOTTOM",0,-15)

    self.RareIcon = t
end


--make a sound when target gets selected
local playTargetSound = function(self,event)
    if event == "PLAYER_TARGET_CHANGED" then
        if (UnitExists(self.unit)) then
            if (UnitIsEnemy(self.unit, "player")) then
                PlaySound("igCreatureAggroSelect")
            elseif ( UnitIsFriend("player", self.unit)) then
                PlaySound("igCharacterNPCSelect")
            else
                PlaySound("igCreatureNeutralSelect")
            end
        else
            PlaySound("INTERFACESOUND_LOSTTARGETUNIT")
        end
    end
end

--create health frames
local createHealthFrame = function(self)

    local cfg = self.cfg.health

    --health
    local h = CreateFrame("StatusBar", nil, self)
    h:SetPoint("TOP",0,-21.9)
    h:SetPoint("LEFT",24.5,0)
    h:SetPoint("RIGHT",-24.5,0)
    h:SetPoint("BOTTOM",0,29.7)
    h:SetFrameStrata("BACKGROUND")


    h:SetStatusBarTexture(cfg.texture)
    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target_hpglow")
    h.glow:SetVertexColor(0,0,0,1)

    h.highlight = h:CreateTexture(nil,"OVERLAY",nil,-4)
    h.highlight:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target_highlight")
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
    h:SetPoint("TOP",0,-20)
    h:SetPoint("LEFT",11,0)
    h:SetPoint("RIGHT",-12,0)
    h:SetPoint("BOTTOM",0,-14)

    h:SetStatusBarTexture(cfg.texture)

    h.bg = h:CreateTexture(nil,"BACKGROUND",nil,-6)
    h.bg:SetTexture(cfg.texture)
    h.bg:SetAllPoints(h)

    h.glow = h:CreateTexture(nil,"OVERLAY",nil,-5)
    h.glow:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target_ppglow")
    h.glow:SetAllPoints(self)
    h.glow:SetVertexColor(0,0,0,1)

    self.Power = h
    self.Power.Smooth = true
    self.Power.frequentUpdates = self.cfg.power.frequentUpdates or false

end

--create health power strings
local createHealthPowerStrings = function(self)

    local name = func.createFontString(self, "header", self.cfg.misc.NameFontSize, "THINOUTLINE")
    name:SetPoint("BOTTOM", self, "TOP", 0, 0)
    name:SetPoint("LEFT", self.Health, 0, 0)
    name:SetPoint("RIGHT", self.Health, 0, 0)
    self.Name = name

    local hpval = func.createFontString(self.Health, "text", self.cfg.health.fontSize, "THINOUTLINE")
    hpval:SetPoint(self.cfg.health.point, self.cfg.health.x,self.cfg.health.y)

    local perphp = func.createFontString(self.Health, "text", self.cfg.healper.fontSize, "THINOUTLINE")
    perphp:SetPoint(self.cfg.healper.point, self.cfg.healper.x,self.cfg.healper.y)

    local perpp = func.createFontString(self.Power, "text", self.cfg.powper.fontSize, "THINOUTLINE")
    perpp:SetPoint(self.cfg.powper.point, self.cfg.powper.x,self.cfg.powper.y)

    local ppval = func.createFontString(self.Health, "text", self.cfg.power.fontSize, "THINOUTLINE")
    ppval:SetPoint(self.cfg.power.point, self.cfg.power.x,self.cfg.power.y)

    local classtext = func.createFontString(self, "text", self.cfg.misc.classFontSize, "THINOUTLINE")
    classtext:SetPoint("BOTTOM", self, "TOP", 0, -15)

    self:Tag(name, "[diablo:name]")
    self:Tag(hpval, self.cfg.health.tag or "")
    self:Tag(perphp, self.cfg.healper.tag or "")
    self:Tag(perpp, self.cfg.powper.tag or "")
    self:Tag(ppval, self.cfg.power.tag or "")
    self:Tag(classtext, "[diablo:classtext]")
end

--check for interruptable spellcast
local checkShield = function(self, unit)
    if self.Shield:IsShown() and UnitCanAttack("player", unit) then
        --show shield
        self:SetStatusBarColor(self.cfg.color.shieldbar.r,self.cfg.color.shieldbar.g,self.cfg.color.shieldbar.b,self.cfg.color.shieldbar.a)
        self.bg:SetVertexColor(self.cfg.color.shieldbg.r,self.cfg.color.shieldbg.g,self.cfg.color.shieldbg.b,self.cfg.color.shieldbg.a)
        self.Spark:SetVertexColor(0.8,0.8,0.8,1)
        self.background:SetDesaturated(1)
    else
        --no shield
        self:SetStatusBarColor(self.cfg.color.bar.r,self.cfg.color.bar.g,self.cfg.color.bar.b,self.cfg.color.bar.a)
        self.bg:SetVertexColor(self.cfg.color.bg.r,self.cfg.color.bg.g,self.cfg.color.bg.b,self.cfg.color.bg.a)
        self.Spark:SetVertexColor(0.8,0.6,0,1)
        self.background:SetDesaturated(nil)
    end
end

--check for interruptable spellcast
local checkCast = function(bar, unit, name, rank, castid)
    checkShield(bar, unit)
end

--check for interruptable spellcast
local checkChannel = function(bar, unit, name, rank)
    checkShield(bar, unit)
end

--create buffs
local createBuffs = function(self)
    local f = CreateFrame("Frame", nil, self)
    f.size = self.cfg.auras.size
    f.num = 40
    f:SetHeight((f.size+5)*4)
    f:SetWidth((f.size+5)*10)
    f:SetPoint(self.cfg.auras.buffs.pos.a1, self, self.cfg.auras.buffs.pos.a2, self.cfg.auras.buffs.pos.x, self.cfg.auras.buffs.pos.y)
    f.initialAnchor = self.cfg.auras.buffs.initialAnchor
    f["growth-x"] = self.cfg.auras.buffs.growthx
    f["growth-y"] = self.cfg.auras.buffs.growthy
    f.spacing = 5
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerBuffs
    f.showStealableBuffs = self.cfg.auras.showStealableBuffs
    self.Buffs = f
end

--create debuff func
local createDebuffs = function(self)
    local f = CreateFrame("Frame", nil, self)
    f.size = self.cfg.auras.size
    f.num = 40
    f:SetHeight((f.size+5)*4)
    f:SetWidth((f.size+5)*10)
    f:SetPoint(self.cfg.auras.debuffs.pos.a1, self, self.cfg.auras.debuffs.pos.a2, self.cfg.auras.debuffs.pos.x, self.cfg.auras.debuffs.pos.y)
    f.initialAnchor = self.cfg.auras.debuffs.initialAnchor
    f["growth-x"] = self.cfg.auras.debuffs.growthx
    f["growth-y"] = self.cfg.auras.debuffs.growthy
    f.spacing = 5
    f.showDebuffType = self.cfg.auras.showDebuffType
    f.onlyShowPlayer = self.cfg.auras.onlyShowPlayerDebuffs
    self.Debuffs = f
end

---------------------------------------------
-- UNIT SPECIFIC TAG
---------------------------------------------

oUF.Tags.Methods["diablo:classtext"] = function(unit)
    local string, tmpstring, sp = "", "", " "
    if UnitLevel(unit) == 0 then
        string = "Haxx, unit undefined"
    elseif UnitLevel(unit) ~= -1 then
        string = UnitLevel(unit)
    else
        string = "??"
    end
    string = string..sp
    local unitrace = UnitRace(unit)
    local creatureType = UnitCreatureType(unit)
    if unitrace and UnitIsPlayer(unit) then
        string = string..unitrace..sp
    end
    if creatureType and not UnitIsPlayer(unit) then
        string = string..creatureType..sp
    end
    local unit_classification = UnitClassification(unit)
    if unit_classification == "worldboss" or UnitLevel(unit) == -1 then
        tmpstring = "Boss"
    elseif unit_classification == "rare" or unit_classification == "rareelite" then
        tmpstring = "Rare"
        if unit_classification == "rareelite" then
            tmpstring = tmpstring.." Elite"
        end
    elseif unit_classification == "elite" then
        tmpstring = "Elite"
    end
    if tmpstring ~= "" then
        tmpstring = tmpstring..sp
    end
    string = string..tmpstring
    tmpstring = ""
    local localizedClass, englishClass = UnitClass(unit)

    if localizedClass and UnitIsPlayer(unit) then
        string = string..localizedClass..sp
    end
    return string
end


---------------------------------------------
-- TARGET STYLE FUNC
---------------------------------------------

local function createStyle(self)

    --apply config to self
    self.cfg = cfg.units.target
    self.cfg.style = "target"



    --init
    initUnitParameters(self)

    --create the art
    createArtwork(self)

    --createhealthPower
    createHealthFrame(self)
    createPowerFrame(self)


    --sound
    self:RegisterEvent("PLAYER_TARGET_CHANGED", playTargetSound)
    self.Health:SetScript("OnShow",function(s)
        playTargetSound(self,"PLAYER_TARGET_CHANGED")
    end)

    --health power strings
    createHealthPowerStrings(self)

    --health power update
    self.Health.PostUpdate = func.updateHealth
    self.Power.PostUpdate = func.updatePower

    --auras
    if self.cfg.auras.show then
        createBuffs(self)
        createDebuffs(self)
        self.Buffs.PostCreateIcon = func.createAuraIcon
        self.Debuffs.PostCreateIcon = func.createAuraIcon
        if self.cfg.auras.desaturateDebuffs then
            self.Debuffs.PostUpdateIcon = func.postUpdateDebuff
        end
    end

    --castbar
    if self.cfg.castbar.show then
        func.createCastbar(self)
        self.Castbar.cfg = self.cfg.castbar
        self.Castbar.PostCastStart = checkCast
        self.Castbar.PostChannelStart = checkChannel
    end

    --debuffglow
    func.createDebuffGlow(self)

    --icons
    self.RaidIcon = func.createIcon(self,"BACKGROUND",24,self.Name,"BOTTOM","TOP",0,0,-1)
    self.RaidIcon:SetTexture("Interface\\AddOns\\Roth_UI\\media\\raidicons")

    --create portrait
    if self.cfg.portrait.show then
        func.createStandAlonePortrait(self)
    end

    --add heal prediction
    func.healPrediction(self)

    --add total absorb
    func.totalAbsorb(self)
    --add self to unit container (maybe access to that unit is needed in another style)
    unit.target = self

end


local targetConfig = {
    type = "group",
    name = "Target",
    args = {
        enable = {
            name = "Enable",
            desc = "Whether or not to enable the target frame",
            order = 1,
            type = "toggle",
            set = function(self, value)
                Roth_UI.db.char.target.enabled = value
            end,
            get = function()
                return Roth_UI.db.char.target.enabled
            end
        },
        scale = {
            name = "Scale",
            desc = "The scale of the target frame",
            order = 2,
            type = "range",
            min = 0.5,
            max = 2.5,
            softMin = 0.75,
            softMax = 1.5,
            step = 0.01,
            bigStep = 0.05,
            set = function(self, value)
                Roth_UI.db.char.target.scale = value
            end,
            get = function()
                return Roth_UI.db.char.target.scale
            end
        },
        xpos = {
            name = "X Position",
            desc = "The position of the target on the horizontal axis",
            order = 3,
            type = "range",
            min = -2000,
            max = 2000,
            softMin = -2000,
            softMax = 2000,
            step = .5,
            bigStep = 1,
            set = function(self, value)
                Roth_UI.db.char.target.xpos = value
            end,
            get = function()
                return Roth_UI.db.char.target.xpos
            end
        },
        ypos = {
            name = "Y Position",
            desc = "The position of the target on the vertical axis",
            order = 3,
            type = "range",
            max = 0,
            min = -2000,
            softMin = -2000,
            softMax = 0,
            step = .5,
            bigStep = 1,
            set = function(self, value)
                Roth_UI.db.char.target.ypos = value
            end,
            get = function()
                return Roth_UI.db.char.target.ypos
            end
        },
    }
}

local targetDefaults = {
    target = {
        enabled = true,
        scale = 1.5,
        xpos = 0,
        ypos = -200,
    }
}

Roth_UI:AddConfig("target", targetConfig, nil, targetDefaults)

---------------------------------------------
-- SPAWN TARGET UNIT
---------------------------------------------
Roth_UI:ListenForLoaded(function()
    if Roth_UI.db.char.target.enabled then
        oUF:RegisterStyle("diablo:target", createStyle)
        oUF:SetActiveStyle("diablo:target")
        oUF:Spawn("target", "Roth_UITargetFrame")
    end
end)
