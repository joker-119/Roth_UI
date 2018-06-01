-- rNamePlates: core
-- Galaxy 2016

-----------------------------
-- Variables
-----------------------------

local addon, ns = ...
local EliteTag = "+"
local RareTag = "^"
local BossTag = "*"
local cfg = ns.cfg
if not cfg.embeds.rNamePlates then return end
-----------------------------
-- SetCVar
-----------------------------

SetCVar("namePlateMinScale", 1)
SetCVar("namePlateMaxScale", 1)

-----------------------------
-- Options
-----------------------------
local groups = {
	"Enemy",
	"Friendly",
	}

if not IsInInstance() then
	local options = {
		useClassColors = true,
		displayNameWhenSelected = true,
		displayNameByPlayerNameRules = true,
		playLoseAggroHighlight = false,
		displayAggroHighlight = true,
		displaySelectionHighlight = true,
		considerSelectionInCombatAsHostile = true,
		colorNameWithExtendedColors = true,
		colorHealthWithExtendedColors = true,
		selectedBorderColor = CreateColor(0, 0, 0, 1),
		tankBorderColor = false,
		defaultBorderColor = CreateColor(0, 0, 0, 1),
		showClassificationIndicator = true,
		}
	for i, group  in next, groups do
	for key, value in next, options do
		_G["DefaultCompactNamePlate"..group.."FrameOptions"][key] = value
	end
end
end


-----------------------------
-- Functions
-----------------------------

local function GetHexColorFromRGB(r, g, b)
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

--SetupNamePlate
local h = CreateFrame("Frame")
h:RegisterEvent("NAME_PLATE_CREATED")
h:SetScript("OnEvent", function(h, event, ...)
    if event == "NAME_PLATE_CREATED" then
        hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", function(frame, setupOptions, frameOptions, ...)
		local unit = ...
            --Health Bar
			if frame:IsForbidden() then return end
            frame.healthBar:SetStatusBarTexture(mediapath.."statusbar_fill")
            frame.healthBar:SetSize(256,32)
            frame.healthBar:SetScale(0.35)
			frame.RaidTargetFrame.RaidTargetIcon:SetTexture(mediapath.."raidicons")
			frame.RaidTargetFrame:SetPoint("RIGHT", frame.healthBar,"RIGHT",35,0)
			frame.ClassificationFrame:Hide()
  
            --Left Edge artwork
			if (not frame.healthBar.le) then
				frame.healthBar.le = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
				frame.healthBar.le:SetTexture(mediapath.."edge_left")
				frame.healthBar.le:SetSize(64,64)
				frame.healthBar.le:SetPoint("RIGHT",frame.healthBar,"LEFT",0,0)
			end
	
            --Right Edge artwork
			if (not frame.healthBar.re) then
				frame.healthBar.re = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
				frame.healthBar.re:SetTexture(mediapath.."edge_right")
				frame.healthBar.re:SetSize(64,64)
				frame.healthBar.re:SetPoint("LEFT",frame.healthBar,"RIGHT",0,0)
            end
			
            --Healthbar Background
			if (not frame.healthBar.bg) then
				frame.healthBar.bg = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
				frame.healthBar.bg:SetTexture(mediapath.."statusbar_bg")
				frame.healthBar.bg:SetAllPoints()
			end
			
            --Name shadow
			if (not frame.healthBar.shadow) then
				frame.healthBar.shadow = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
				frame.healthBar.shadow:SetTexture("Interface\\Common\\NameShadow")
				frame.healthBar.shadow:SetPoint("BOTTOM",frame.healthBar,"TOP",0,-20)
				frame.healthBar.shadow:SetSize(256,32)
				frame.healthBar.shadow:SetTexCoord(1,1,1,0,0,1,0,0)
				frame.healthBar.shadow:SetAlpha(0.5)
			end
  
            --Highlight Frame
			if (not frame.healthBar.hlf) then
				frame.healthBar.hlf = CreateFrame("Frame",nil,frame.healthBar)
				frame.healthBar.hlf:SetAllPoints(frame.healthBar)
				frame.healthBar.hlf = frame.healthBar.hlf
			end
  
            --Highlight
			if (not frame.healthBar.hl) then
				frame.healthBar.hl = frame.healthBar.hlf:CreateTexture(nil,"BACKGROUND",nil,-8)
				frame.healthBar.hl:SetTexture(mediapath.."statusbar_highlight")
				frame.healthBar.hl:SetPoint("TOP",50,0)
				frame.healthBar.hl:SetPoint("LEFT",-30,0)
				frame.healthBar.hl:SetPoint("RIGHT",30,0)
				frame.healthBar.hl:SetPoint("BOTTOM",40,0)
			end
  
            --Cast Bar
            frame.castBar:SetStatusBarTexture(mediapath.."statusbar_fill")
            if GetCVar("NamePlateVerticalScale") == "1" then
				if frame:IsForbidden() then return end
                frame.castBar:SetHeight(11)
                frame.castBar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
                frame.castBar.Icon:SetSize(17,17)
                frame.castBar.Icon:ClearAllPoints()
                frame.castBar.Icon:SetPoint("BOTTOMRIGHT",frame.castBar,"BOTTOMLEFT",-2,0)
			end
        end)
    end
end)


--Name
hooksecurefunc("CompactUnitFrame_UpdateName", function (frame)
	if frame:IsForbidden() then return end
   --Set the tag based on UnitClassification, can return "worldboss", "rare", "rareelite", "elite", "normal", "minus"
	local tag 
	local level = UnitLevel(frame.unit)
	local name = UnitName(frame.unit)
	local hexColor
   
	if level >= UnitLevel("player")+5 then
		hexColor = GetHexColorFromRGB(1,0,0)
	elseif level >= UnitLevel("player")+3 then
		hexColor = "ff6600"
	elseif level <= UnitLevel("player")-5 then
		hexColor = GetHexColorFromRGB(.5,.5,.5)
	elseif level <= UnitLevel("player")-3 then
		hexColor = GetHexColorFromRGB(0,1,0)
	else
		hexColor = GetHexColorFromRGB(1,1,0)
	end

	if UnitClassification(frame.unit) == "worldboss" or UnitLevel(frame.unit) == -1 then
		level = "??"
		hexColor = "ff6600"
	elseif UnitClassification(frame.unit) == "rare" then
		name = "*"..name.."*"
	elseif UnitClassification(frame.unit) == "rareelite" then
		name = "*"..name.."*"
		level = "+"..level
	elseif UnitClassification(frame.unit) == "elite" then
		level = "+"..level
	end
	--Set the nameplate name to include tag(if any), name and level
	frame.name:SetText("|cff"..hexColor.."("..level..")|r "..name)
	frame.name:SetFont(cfg.font, 12)
	
	--explosiove orbs
	if (name == "Fel Explosives") then
		frame.healthBar:SetSize(384,48)
		frame.healthBar:SetScale(0.35)
		frame.healthBar.re:SetSize(128,128)
		frame.healthBar.le:SetSize(128,128)
	else
		frame.healthBar.re:SetSize(64,64)
		frame.healthBar.le:SetSize(64,64)
	end
end)



local function IsTank()
  local assignedRole = UnitGroupRolesAssigned("player")
  if assignedRole == "TANK" then return true end
  local role = GetSpecializationRole(GetSpecialization())
  if role == "TANK" then return true end
  return false
end


--UpdateHealthBorder
local function UpdateHealthBorder(frame)
	if frame:IsForbidden() then return end
	if frame.displayedUnit:match("(nameplate)%d?$") ~= "nameplate" then return end
	if not IsTank() then return end
	local status = UnitThreatSituation("player", frame.displayedUnit)
	if status and status >= 3 then
		frame.healthBar.border:SetVertexColor(0, 1, 0, 0.8)
	end
end
hooksecurefunc("CompactUnitFrame_UpdateHealthBorder", UpdateHealthBorder)
