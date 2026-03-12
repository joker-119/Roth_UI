local __, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "oUF Reputation was unable to locate oUF install")

-- Tags must pull fresh data too
oUF.Tags.Methods.currep = function()
  local name, standing, min, max, value = ns.Reputation.GetFactionData()
  if not name then return 0 end
  return value - min
end

oUF.Tags.Methods.maxrep = function()
  local name, standing, min, max, value = ns.Reputation.GetFactionData()
  if not name then return 0 end
  return max - min
end

oUF.Tags.Methods.perrep = function()
  local name, standing, min, max, value = ns.Reputation.GetFactionData()
  if not name then return 0 end
  local denom = (max - min)
  if denom <= 0 then return 0 end
  return math.floor(((value - min) / denom) * 100 + 0.5)
end

oUF.Tags.Methods.standing = function()
  local name, standing = GetFactionData()
  if not name or not standing then return "" end
  return GetText("FACTION_STANDING_LABEL" .. standing, UnitSex("player"))
end

for _, tag in ipairs({ "currep", "maxrep", "perrep", "standing" }) do
  oUF.Tags.Events[tag] = "UPDATE_FACTION"
end
oUF.Tags.SharedEvents.UPDATE_FACTION = true

local function Update(self)
  local rep = self.Reputation
  if not rep then return end

  local name, standing, min, max, value = ns.Reputation.GetFactionData()
  if not name then
    rep:Hide()
    return
  end

  rep:Show()

  local cur = value - min
  local cap = max - min

  rep:SetMinMaxValues(0, cap)
  rep:SetValue(cur)

  if rep.colorStanding and standing and FACTION_BAR_COLORS[standing] then
    local c = FACTION_BAR_COLORS[standing]
    rep:SetStatusBarColor(c.r, c.g, c.b)
  end

  if rep.PostUpdate then
    rep:PostUpdate(self.unit, name, standing, min, max, value)
  end
end

local function Path(self, ...)
  return (self.Reputation.Override or Update)(self, ...)
end

local function ForceUpdate(element)
  return Path(element.__owner, "ForceUpdate")
end

local function Enable(self)
  local rep = self.Reputation
  if not rep then return end

  rep.__owner = self
  rep.ForceUpdate = ForceUpdate

  self:RegisterEvent("UPDATE_FACTION", Path, true)
  self:RegisterEvent("PLAYER_ENTERING_WORLD", Path, true)

  if not rep:GetStatusBarTexture() then
    rep:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
  end

  return true
end

local function Disable(self)
  if self.Reputation then
    self:UnregisterEvent("UPDATE_FACTION", Path)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD", Path)
  end
end

oUF:AddElement("Reputation", Path, Enable, Disable)
