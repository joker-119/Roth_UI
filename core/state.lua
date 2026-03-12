-- Roth_UI/core/state.lua
local addon, ns = ...
ns.State = ns.State or {}
local State = ns.State

local Scheduler = ns.Scheduler

local current = {
  -- instance
  inInstance = false,
  instanceType = "none",
  talentGroup = 1,

  -- combat/target/group
  combat = false,
  hasTarget = false,
  targetHostile = false,
  targetFriendly = false,
  targetHealthPct = 100,
  targetClassification = "normal",

  inGroup = false,
  inRaid = false,
  groupSize = 0,

  -- player state
  mounted = false,
  dead = false,
  stealthed = false,
  vehicle = false,
  role = "NONE",
  threat = 0, -- 0..3 when available

  -- resources
  playerHealthPct = 100,
  playerPowerPct = 100,

  -- extras
  hasFocus = false,
  hasMouseover = false,
}

local frame = CreateFrame("Frame")
local function SafeBool(v) return v and true or false end

local function GetRole()
  if type(UnitGroupRolesAssigned) == "function" then
    local r = UnitGroupRolesAssigned("player")
    if r and r ~= "" then return r end
  end
  return "NONE"
end

local function Pct(unit)
  if type(UnitHealth) ~= "function" or type(UnitHealthMax) ~= "function" then return 100 end
  local hp = UnitHealth(unit) or 0
  local hpMax = UnitHealthMax(unit) or 0
  if hpMax > 0 then return (hp / hpMax) * 100 end
  return 100
end

local function UpdateAll()
  -- Instance
  local inInstance, instanceType = IsInInstance()
  current.inInstance = SafeBool(inInstance)
  current.instanceType = instanceType or "none"

  if GetActiveTalentGroup then
      current.talentGroup = GetActiveTalentGroup() or 1
  else
      current.talentGroup = 1
  end
  
  -- Combat
  current.combat = (type(InCombatLockdown) == "function") and SafeBool(InCombatLockdown()) or false

  -- Target basics
  current.hasTarget = (type(UnitExists) == "function") and SafeBool(UnitExists("target")) or false
  if current.hasTarget and type(UnitCanAttack) == "function" then
    current.targetHostile = SafeBool(UnitCanAttack("player", "target"))
  else
    current.targetHostile = false
  end
  if current.hasTarget and type(UnitIsFriend) == "function" then
    current.targetFriendly = SafeBool(UnitIsFriend("player", "target"))
  else
    current.targetFriendly = false
  end

  current.targetHealthPct = current.hasTarget and Pct("target") or 100

  if current.hasTarget and type(UnitClassification) == "function" then
    current.targetClassification = UnitClassification("target") or "normal"
  else
    current.targetClassification = "normal"
  end

  -- Group
  current.inGroup = (type(IsInGroup) == "function") and SafeBool(IsInGroup()) or false
  current.inRaid = (type(IsInRaid) == "function") and SafeBool(IsInRaid()) or false
  if current.inGroup and type(GetNumGroupMembers) == "function" then
    current.groupSize = GetNumGroupMembers() or 0
  else
    current.groupSize = 0
  end

  -- Player state
  current.mounted = (type(IsMounted) == "function") and SafeBool(IsMounted()) or false
  current.dead = (type(UnitIsDeadOrGhost) == "function") and SafeBool(UnitIsDeadOrGhost("player")) or false
  current.stealthed = (type(IsStealthed) == "function") and SafeBool(IsStealthed()) or false
  current.vehicle = (type(UnitHasVehicleUI) == "function") and SafeBool(UnitHasVehicleUI("player")) or false
  current.role = GetRole()

  if type(UnitThreatSituation) == "function" then
    current.threat = UnitThreatSituation("player") or 0
  else
    current.threat = 0
  end

  -- Player health/power %
  current.playerHealthPct = Pct("player")

  if type(UnitPower) == "function" and type(UnitPowerMax) == "function" then
    local p = UnitPower("player") or 0
    local pMax = UnitPowerMax("player") or 0
    current.playerPowerPct = (pMax > 0) and ((p / pMax) * 100) or 100
  else
    current.playerPowerPct = 100
  end

  -- Focus/mouseover
  current.hasFocus = (type(UnitExists) == "function") and SafeBool(UnitExists("focus")) or false
  current.hasMouseover = (type(UnitExists) == "function") and SafeBool(UnitExists("mouseover")) or false
end

-- ============================================================
-- Public API (backwards compatible)
-- ============================================================

function State.Get()
  return current
end

function State.GetValue(key)
  return current[key]
end

function State.GetHealthPct()
  return tonumber(current.playerHealthPct) or 100
end

function State.GetPowerPct()
  return tonumber(current.playerPowerPct) or 100
end

-- State predicates for non-CAEVS consumers (rCooldown, State Strip, etc.)
-- Conventions:
--  - threshold can be 0..1 (fraction) OR 0..100 (percent)
--  - returns boolean
function State.Eval(cond, value)
  cond = tostring(cond or "")

  local function NormalizeThreshold(v, defaultPct)
    if v == nil then
      return defaultPct or 35
    end
    local n = tonumber(v)
    if not n then return defaultPct or 35 end
    -- if user passes 0..1 treat as fraction
    if n >= 0 and n <= 1 then
      return n * 100
    end
    return n
  end

  if cond == "HealthLow" then
    local thr = NormalizeThreshold(value, 35)
    return (State.GetHealthPct() or 100) <= thr
  end

  if cond == "HealthHigh" then
    local thr = NormalizeThreshold(value, 95)
    return (State.GetHealthPct() or 100) >= thr
  end

  if cond == "ManaLow" or cond == "PowerLow" then
    local thr = NormalizeThreshold(value, 35)
    return (State.GetPowerPct() or 100) <= thr
  end

  if cond == "ManaHigh" or cond == "PowerHigh" then
    local thr = NormalizeThreshold(value, 95)
    return (State.GetPowerPct() or 100) >= thr
  end

  if cond == "HasTarget" then
    return current.hasTarget == true
  end

  if cond == "InCombat" then
    return current.combat == true
  end

  if cond == "Dead" then
    return current.dead == true
  end

  return false
end

-- ============================================================
-- Internal refresh + CAEVS visibility refresh hook
-- ============================================================

local function Refresh()
  UpdateAll()
  if ns.Visibility and ns.Visibility.EvaluateAll then
    ns.Visibility.EvaluateAll()
  end
end

local function MarkDirty(unit)
  if unit and unit ~= "player" and unit ~= "target" and unit ~= "focus" and unit ~= "mouseover" then
    return
  end
  if Scheduler and Scheduler.Throttle then
    Scheduler.Throttle("state_refresh", 0.05, Refresh)
  else
    Refresh()
  end
end

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("PLAYER_ALIVE")
frame:RegisterEvent("PLAYER_UNGHOST")
frame:RegisterEvent("UNIT_HEALTH")
frame:RegisterEvent("UNIT_MAXHEALTH")
frame:RegisterEvent("UNIT_POWER_UPDATE")
frame:RegisterEvent("UNIT_MAXPOWER")
frame:RegisterEvent("UNIT_DISPLAYPOWER")
frame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
frame:RegisterEvent("UPDATE_STEALTH")
frame:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("CHARACTER_POINTS_CHANGED")

frame:SetScript("OnEvent", function(_, _, unit)
  MarkDirty(unit)
end)

UpdateAll()