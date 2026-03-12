--[[Written by Galaxy119 - 2016]]

if select(2, UnitClass("player")) ~= "MAGE" then return end

local parent, ns = ...
local oUF = ns.oUF or oUF

print("Arc Charges")

-- Locals
local POWER_ARCANE_CHARGES = (Enum and Enum.PowerType and Enum.PowerType.ArcaneCharges) or 16
local ARCANE_CHARGE_NAME = GetSpellInfo("Arcane Charge") or "Arcane Charge" -- fine for enUS; swap to spellID if you prefer

-- MoP Classic: scan HARMFUL auras for Arcane Charge stacks
local function GetArcaneChargeCount_Classic(unit)
  for i = 1, 40 do
    local name, _, count = UnitAura(unit, i, "HARMFUL")
    if not name then break end
    if name == ARCANE_CHARGE_NAME then
      return count or 0
    end
  end
  return 0
end

-- Retail: real secondary power
local function GetArcaneChargeCount_Retail(unit)
  return UnitPower(unit, POWER_ARCANE_CHARGES) or 0
end

-- Public: universal getter
function GetArcaneChargeCount(unit)
  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    return GetArcaneChargeCount_Retail(unit or "player")
  else
    return GetArcaneChargeCount_Classic(unit or "player")
  end
end

-- Optional: a matching "max" helper
function GetArcaneChargeMax(unit)
  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    return UnitPowerMax(unit or "player", POWER_ARCANE_CHARGES) or 4
  else
    return 4 -- MoP Classic is always 0..4 stacks
  end
end



local Update = function(self, event, unit, powerType)
  local bar = self.ArcBar
  local cur = GetArcaneChargeCount("player")
  local max = GetArcaneChargeMax("player")

  --adjust the width of the soulshard power frame
  local w = 64*(max+1)
  bar:SetWidth(w)
  for i = 1, bar.maxOrbs do
    local orb = self.ACharges[i]
    if i > max then
       if orb:IsShown() then orb:Hide() end
    else
      if not orb:IsShown() then orb:Show() end
    end
  end
  
  for i = 1, bar.maxOrbs do
    local orb = self.ACharges[i]
    local full = cur/max
    if(i <= cur) then
      orb.fill:Show()
      orb.highlight:Show()
    else
      orb.fill:Hide()
      orb.highlight:Hide()
    end
  end

end

local Visibility = function(self, event, unit)
  local element = self.ACharges
  local bar = self.ArcBar
  if UnitHasVehicleUI("player")
    or ((HasVehicleActionBar() and UnitVehicleSkin("player") and UnitVehicleSkin("player") ~= "")
    or (HasOverrideActionBar() and GetOverrideBarSkin() and GetOverrideBarSkin() ~= "")) then
        bar:Hide()
    elseif (GetPrimaryTalentTree() == 1) then
        bar:Show()
        element.ForceUpdate(element)
    else
        bar:Hide()
    end
end

local Path = function(self, ...)
  return (self.ACharges.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
  return Path(element.__owner, "ForceUpdate", element.__owner.unit, "ARCANE_CHARGES")
end

local function Enable(self, unit)
  local element = self.ACharges
  if(element and unit == "player") then
        local bar = self.ArcBar
        if UnitHasVehicleUI("player")
          or ((HasVehicleActionBar() and UnitVehicleSkin("player") and UnitVehicleSkin("player") ~= "")
          or (HasOverrideActionBar() and GetOverrideBarSkin() and GetOverrideBarSkin() ~= "")) then
              bar:Hide()
          elseif (GetPrimaryTalentTree() == 1) then
              bar:Show()
              if (element.ForceUpdate) then
                element.ForceUpdate(element)
            end
          else
              bar:Hide()
          end
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
    helper:RegisterEvent("PLAYER_LOGIN")
    helper:SetScript("OnEvent", function() Visibility(self) end)

    return true
  end
end

local function Disable(self)
  local element = self.ACharges
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

oUF:AddElement("ACharges", Path, Enable, Disable)
