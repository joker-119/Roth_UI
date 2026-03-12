local parent, ns = ...
local oUF = ns.oUF or oUF

local class = select(2, UnitClass("player"))
local spec = GetSpecialization()

local Update = function(self, event, unit, powerType)
  local bar = self.ComboBar
  local num = UnitPower("player", Enum.PowerType.ComboPoints)
  local max
  if class == "ROGUE" and select(4, GetTalentInfo(3,2,1)) then
	max = 6
  else
	max = 5
  end
  MAX_COMBO_POINTS = UnitPowerMax("player", Enum.PowerType.ComboPoints)
  --adjust the width of the holy power frame
  local w = 64*(max+2)
  bar:SetWidth(w)
  for i = 1, max do
    local orb = self.ComboPoints[i]
    if i > max then
       if orb:IsShown() then orb:Hide() end
    else
      if not orb:IsShown() then orb:Show() end
    end
  end
  for i = 1, max do
    local orb = self.ComboPoints[i]
    local full = num/max
    if(i <= num) then
      if full == 1 then
        orb.fill:SetVertexColor(1,0,0)
        orb.glow:SetVertexColor(1,0,0)
      else
        orb.fill:SetVertexColor(bar.color.r,bar.color.g,bar.color.b)
        orb.glow:SetVertexColor(bar.color.r,bar.color.g,bar.color.b)
      end
      orb.fill:Show()
      orb.glow:Show()
      orb.highlight:Show()
    else
      orb.fill:Hide()
      orb.glow:Hide()
      orb.highlight:Hide()
    end
  end
end

local Visibility = function(self, event, unit)
  local element = self.ComboPoints
  local bar = self.ComboBar
  if UnitHasVehicleUI("player")
    or ((HasVehicleActionBar() and UnitVehicleSkin("player") and UnitVehicleSkin("player") ~= "")
    or (HasOverrideActionBar() and GetOverrideBarSkin() and GetOverrideBarSkin() ~= ""))
  then
    bar:Hide()
  elseif class == "ROGUE" or (class == "DRUID" and (GetSpecialization() == 2 or (select(4, GetTalentInfo(3,2,1)) and GetShapeshiftForm() == 2))) then
    bar:Show()
    element.ForceUpdate(element)
  else
    bar:Hide()
  end
end

local Path = function(self, ...)
  return (self.ComboPoints.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
  return Path(element.__owner, "ForceUpdate", element.__owner.unit, "COMBO_POINTS")
end

local function Enable(self, unit)
  local element = self.ComboPoints
  if(element and unit == "player") then
    element.__owner = self
    element.ForceUpdate = ForceUpdate
    
    self:RegisterEvent("UNIT_POWER_FREQUENT", Path)
    self:RegisterEvent("UNIT_DISPLAYPOWER", Path)
    self:RegisterEvent("PLAYER_TALENT_UPDATE", Visibility, true)
    self:RegisterEvent("SPELLS_CHANGED", Visibility, true)
    self:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR", Visibility, true)
    self:RegisterEvent("UNIT_ENTERED_VEHICLE", Visibility)
    self:RegisterEvent("UNIT_EXITED_VEHICLE", Visibility)
    
    local helper = CreateFrame("Frame") --this is needed...adding player_login to the visivility events does not do anything
    helper:RegisterEvent("PLAYER_ENTERING_WORLD")
    helper:SetScript("OnEvent", function() Visibility(self) end)
--    helper:SetScript("OnEvent", function() Update(self) end)
    
    return true
  end
end

local function Disable(self)
  local element = self.ComboPoints
  if(element) then
    self:UnregisterEvent("UNIT_POWER_FREQUENT", Path)
    self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)
    self:UnregisterEvent("PLAYER_TALENT_UPDATE", Visibility)
    self:UnregisterEvent("SPELLS_CHANGED", Visibility)
    self:UnregisterEvent("UPDATE_OVERRIDE_ACTIONBAR", Visibility)
    self:UnregisterEvent("UNIT_ENTERED_VEHICLE", Visibility)
    self:UnregisterEvent("UNIT_EXITED_VEHICLE", Visibility)
  end
end

oUF:AddElement("ComboPoints", Path, Enable, Disable)
