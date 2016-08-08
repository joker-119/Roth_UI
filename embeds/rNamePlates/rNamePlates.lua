-- rNamePlates: core
-- Galaxy/zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

-----------------------------
-- SetCVar
-----------------------------

SetCVar("namePlateMinScale", 1)
SetCVar("namePlateMaxScale", 1)

-----------------------------
-- Options
-----------------------------

local mediapath = "Interface\\AddOns\\Roth_UI\\embeds\\rNamePlates\\media\\"

local groups = {
  "Friendly",
  "Enemy",
}

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

-----------------------------
-- Functions
-----------------------------

--SetupNamePlate
local function SetupNamePlate(frame, setupOptions, frameOptions)
 --Health Bar
  frame.healthBar:SetStatusBarTexture(mediapath.."statusbar_fill")
  frame.healthBar:SetSize(256,32)
  frame.healthBar:SetScale(0.35)
  
  local le = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  le:SetTexture(mediapath.."edge_left")
  le:SetSize(64,64)
  le:SetPoint("RIGHT",frame.healthBar,"LEFT",0,0)
  
  local re = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  re:SetTexture(mediapath.."edge_right")
  re:SetSize(64,64)
  re:SetPoint("LEFT",frame.healthBar,"RIGHT",0,0)
  
  local bg = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  bg:SetTexture(mediapath.."statusbar_bg")
  bg:SetAllPoints()
  
  local shadow = frame.healthBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  shadow:SetTexture("Interface\\Common\\NameShadow")
  shadow:SetPoint("BOTTOM",frame.healthBar,"TOP",0,-20)
  shadow:SetSize(256,32)
  shadow:SetTexCoord(1,1,1,0,0,1,0,0)
  shadow:SetAlpha(0.5)
  
  local hlf = CreateFrame("Frame",nil,frame.healthBar)
  hlf:SetAllPoints()
  frame.healthBar.hlf = hlf
  
  local hl = hlf:CreateTexture(nil,"BACKGROUND",nil,-8)
  hl:SetTexture(mediapath.."statusbar_highlight")
  hl:SetAllPoints()

  --Cast Bar
  frame.castBar:SetStatusBarTexture(mediapath.."statusbar_fill")
  if GetCVar("NamePlateVerticalScale") == "1" then
    frame.castBar:SetHeight(11)
    frame.castBar.Icon:SetTexCoord(0.1,0.9,0.1,0.9)
    frame.castBar.Icon:SetSize(17,17)
    frame.castBar.Icon:ClearAllPoints()
    frame.castBar.Icon:SetPoint("BOTTOMRIGHT",frame.castBar,"BOTTOMLEFT",-2,0)
  end
end
hooksecurefunc("DefaultCompactNamePlateFrameSetupInternal", SetupNamePlate)

local function IsTank()
  local assignedRole = UnitGroupRolesAssigned("player")
  if assignedRole == "TANK" then return true end
  local role = GetSpecializationRole(GetSpecialization())
  if role == "TANK" then return true end
  return false
end

--UpdateHealthBorder
local function UpdateHealthBorder(frame)
  if frame.displayedUnit:match("(nameplate)%d?$") ~= "nameplate" then return end
  if not IsTank() then return end
  local status = UnitThreatSituation("player", frame.displayedUnit)
  if status and status >= 3 then
    frame.healthBar.border:SetVertexColor(0, 1, 0, 0.8)
  end
end
hooksecurefunc("CompactUnitFrame_UpdateHealthBorder", UpdateHealthBorder)