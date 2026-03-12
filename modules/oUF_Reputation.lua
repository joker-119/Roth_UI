local __, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF Reputation was unable to locate oUF install')

for tag, func in pairs({
  ['currep'] = function()
    local __, __, min, __, value = C_Reputation.GetWatchedFactionData()
    return value - min
  end,
  ['maxrep'] = function()
    local __, __, min, max = C_Reputation.GetWatchedFactionData()
    return max - min
  end,
  ['perrep'] = function()
    local __, __, min, max, value = C_Reputation.GetWatchedFactionData()
    return math.floor((value - min) / (max - min) * 100 + 0.5)
  end,
  ['standing'] = function()
    local __, standing = C_Reputation.GetWatchedFactionData()
    return GetText('FACTION_STANDING_LABEL' .. standing, UnitSex('player'))
  end,
  ['reputation'] = function()
    return C_Reputation.GetWatchedFactionData()
  end,
}) do
  oUF.Tags.Methods[tag] = func
  oUF.Tags.Events[tag] = 'UPDATE_FACTION'
end

oUF.Tags.SharedEvents.UPDATE_FACTION = true

local function Update(self, event, unit)
  local reputation = self.Reputation

  local _, name, _, standing, min, max, value = C_Reputation.GetWatchedFactionData()
  if(not name) then
    return reputation:Hide()
  else
    reputation:Show()
  end

  reputation:SetMinMaxValues(0, max - min)
  reputation:SetValue(value)

  if(reputation.colorStanding) then
    local color = FACTION_BAR_COLORS[standing]
    reputation:SetStatusBarColor(color.r, color.g, color.b)
  end

  if(reputation.PostUpdate) then
    return reputation:PostUpdate(unit, name, standing, min, max, value)
  end
end

local function Path(self, ...)
  return (self.Reputation.Override or Update) (self, ...)
end

local function ForceUpdate(element)
  return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
  local reputation = self.Reputation
  if(reputation) then
    reputation.__owner = self
    reputation.ForceUpdate = ForceUpdate

    self:RegisterEvent('UPDATE_FACTION', Path, true)
    self:RegisterEvent('COMBAT_TEXT_UPDATE', Path, true)
    self:RegisterEvent('QUEST_FINISHED', Path, true)

    if(not reputation:GetStatusBarTexture()) then
      reputation:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
    end

    return true
  end
end

local function Disable(self)
  if(self.Reputation) then
    self:UnregisterEvent('UPDATE_FACTION', Path)
  end
end

oUF:AddElement('Reputation', Path, Enable, Disable)
