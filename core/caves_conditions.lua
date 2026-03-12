-- Roth_UI/core/caevs_conditions.lua
local addon, ns = ...
ns.CAEVS = ns.CAEVS or {}
local CAEVS = ns.CAEVS

CAEVS.conditions = CAEVS.conditions or {}

-- ============================================================
-- Shared CAEVS Condition Evaluator API (for other modules)
-- ============================================================

-- Returns a stable map usable for AceConfig "select" values: key -> label
function CAEVS:GetConditionList()
  local out = {}
  for key, def in pairs(self.conditions) do
    if type(def) == "table" then
      out[key] = def.label or key
    end
  end
  return out
end

-- Initialize condition-specific data (so consumers can store per-leaf config safely)
function CAEVS:InitConditionData(key, data)
  local def = self.conditions[key]
  if not def or type(def.init) ~= "function" then
    return data or {}
  end
  return def.init(data)
end

-- Build AceConfig option table for the condition's parameters
function CAEVS:BuildConditionOptions(key, getData, setData)
  local def = self.conditions[key]
  if not def or type(def.buildOptions) ~= "function" then
    return {}
  end
  return def.buildOptions(getData, setData) or {}
end

-- Lightweight meta so other modules can present condition info
function CAEVS:GetConditionMeta(key)
  local def = self.conditions[key]
  if not def then return nil end
  return {
    key = key,
    label = def.label or key,
    hasOptions = (type(def.buildOptions) == "function"),
  }
end

-- Evaluate a condition. Consumers may pass a stateOverride; otherwise uses ns.State.Get().
function CAEVS:EvalCondition(key, data, stateOverride)
  local def = self.conditions[key]
  if not def or type(def.eval) ~= "function" then
    return false
  end
  local st
  if stateOverride then
    st = stateOverride
  else
    st = (ns.State and ns.State.Get and ns.State.Get()) or nil
  end
  return def.eval(st, data)
end

-- Helpers
local function Clamp(n, a, b)
  if n < a then return a end
  if n > b then return b end
  return n
end

local OPS = {
  lt  = { label = "<",  fn = function(a,b) return a <  b end },
  lte = { label = "<=", fn = function(a,b) return a <= b end },
  gt  = { label = ">",  fn = function(a,b) return a >  b end },
  gte = { label = ">=", fn = function(a,b) return a >= b end },
  eq  = { label = "=",  fn = function(a,b) return a == b end },
}
local OP_VALUES = { lt="<", lte="<=", gt=">", gte=">=", eq="=" }

local function InitPctData(data)
  data = data or {}
  if not data.op then data.op = "lt" end
  if data.pct == nil then data.pct = 35 end
  data.pct = Clamp(tonumber(data.pct) or 35, 0, 100)
  return data
end

local function BuildPctOptions(getData, setData, label)
  return {
    op = {
      type = "select",
      name = "Operator",
      values = OP_VALUES,
      order = 1,
      get = function() return (getData().op or "lt") end,
      set = function(_, v) local d=getData(); d.op=v; setData(d) end,
    },
    pct = {
      type = "range",
      name = label or "Percent",
      min = 0, max = 100, step = 1,
      order = 2,
      get = function() return (tonumber(getData().pct) or 0) end,
      set = function(_, v) local d=getData(); d.pct=v; setData(d) end,
    },
  }
end

local function EvalPct(value, data)
  data = data or {}
  local op = OPS[data.op or "lt"] or OPS.lt
  local pct = tonumber(data.pct) or 0
  return op.fn(value or 0, pct)
end

local function InitNumberData(data, defaultValue)
  data = data or {}
  if not data.op then data.op = "gte" end
  if data.value == nil then data.value = defaultValue or 1 end
  data.value = tonumber(data.value) or (defaultValue or 1)
  return data
end

local function BuildNumberOptions(getData, setData, label, minV, maxV, stepV)
  return {
    op = {
      type = "select",
      name = "Operator",
      values = OP_VALUES,
      order = 1,
      get = function() return (getData().op or "gte") end,
      set = function(_, v) local d=getData(); d.op=v; setData(d) end,
    },
    value = {
      type = "range",
      name = label or "Value",
      min = minV or 0, max = maxV or 40, step = stepV or 1,
      order = 2,
      get = function() return tonumber(getData().value) or 0 end,
      set = function(_, v) local d=getData(); d.value=v; setData(d) end,
    },
  }
end

local function EvalNumber(value, data)
  data = data or {}
  local op = OPS[data.op or "gte"] or OPS.gte
  local v = tonumber(data.value) or 0
  return op.fn(tonumber(value) or 0, v)
end

-- ------------------------------------------------------------
-- Conditions (existing CAEVS condition set)
-- ------------------------------------------------------------

CAEVS.conditions.always = {
  label = "Always",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function() return true end,
}

CAEVS.conditions.inInstance = {
  label = "In Instance",
  init = function(data)
    data = data or {}
    if data.instanceType == nil then data.instanceType = "any" end
    return data
  end,
  buildOptions = function(getData, setData)
    return {
      instanceType = {
        type = "select",
        name = "Type",
        order = 1,
        values = {
          any      = "Any",
          party    = "Dungeon (party)",
          raid     = "Raid",
          pvp      = "Battleground (pvp)",
          arena    = "Arena",
          scenario = "Scenario",
        },
        get = function()
          local d = getData()
          return d.instanceType or "any"
        end,
        set = function(_, v)
          local d = getData()
          d.instanceType = v
          setData(d)
        end,
      },
      note = {
        type = "description",
        name = "Any ignores instanceType and only checks that you're in an instance.",
        order = 99,
      },
    }
  end,
  eval = function(state, data)
    if not state or state.inInstance ~= true then return false end
    data = data or {}
    local t = data.instanceType or "any"
    if t == "any" then return true end
    return (state.instanceType or "none") == t
  end,
}

CAEVS.conditions.combat = {
  label = "In Combat",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.combat == true end,
}

CAEVS.conditions.hasTarget = {
  label = "Has Target",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.hasTarget == true end,
}

CAEVS.conditions.targetHostile = {
  label = "Target is Hostile",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.targetHostile == true end,
}

CAEVS.conditions.targetFriendly = {
  label = "Target is Friendly",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.targetFriendly == true end,
}

CAEVS.conditions.inGroup = {
  label = "In Group",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.inGroup == true end,
}

CAEVS.conditions.inRaid = {
  label = "In Raid",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.inRaid == true end,
}

CAEVS.conditions.groupSize = {
  label = "Group Size",
  init = function(data) return InitNumberData(data, 2) end,
  buildOptions = function(getData, setData)
    return BuildNumberOptions(getData, setData, "Members", 0, 40, 1)
  end,
  eval = function(state, data)
    return state and EvalNumber(state.groupSize or 0, data)
  end,
}

CAEVS.conditions.role = {
  label = "Player Role",
  init = function(data)
    data = data or {}
    if not data.role then data.role = "DAMAGER" end
    return data
  end,
  buildOptions = function(getData, setData)
    return {
      role = {
        type = "select",
        name = "Role",
        order = 1,
        values = {
          TANK = "Tank",
          HEALER = "Healer",
          DAMAGER = "DPS",
          NONE = "None/Unknown",
        },
        get = function() return getData().role or "DAMAGER" end,
        set = function(_, v) local d=getData(); d.role=v; setData(d) end,
      },
    }
  end,
  eval = function(state, data)
    if not state then return false end
    data = data or {}
    return (state.role or "NONE") == (data.role or "DAMAGER")
  end,
}

CAEVS.conditions.playerHealthPct = {
  label = "Player Health %",
  init = InitPctData,
  buildOptions = function(getData, setData) return BuildPctOptions(getData, setData, "Health %") end,
  eval = function(state, data) return state and EvalPct(state.playerHealthPct or 0, data) end,
}

CAEVS.conditions.playerPowerPct = {
  label = "Player Power %",
  init = InitPctData,
  buildOptions = function(getData, setData) return BuildPctOptions(getData, setData, "Power %") end,
  eval = function(state, data) return state and EvalPct(state.playerPowerPct or 0, data) end,
}

CAEVS.conditions.targetHealthPct = {
  label = "Target Health %",
  init = InitPctData,
  buildOptions = function(getData, setData) return BuildPctOptions(getData, setData, "Target Health %") end,
  eval = function(state, data)
    if not state or state.hasTarget ~= true then return false end
    return EvalPct(state.targetHealthPct or 0, data)
  end,
}

CAEVS.conditions.targetBossOrElite = {
  label = "Target is Boss/Elite",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state)
    if not state or state.hasTarget ~= true then return false end
    local c = state.targetClassification or "normal"
    return (c == "worldboss" or c == "rareelite" or c == "elite")
  end,
}

CAEVS.conditions.mounted = {
  label = "Mounted",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.mounted == true end,
}

CAEVS.conditions.dead = {
  label = "Player Dead/Ghost",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.dead == true end,
}

CAEVS.conditions.hasFocus = {
  label = "Has Focus",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.hasFocus == true end,
}

CAEVS.conditions.hasMouseover = {
  label = "Has Mouseover",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.hasMouseover == true end,
}

CAEVS.conditions.stealthed = {
  label = "Stealthed",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.stealthed == true end,
}

CAEVS.conditions.vehicle = {
  label = "In Vehicle",
  init = function(data) return data or {} end,
  buildOptions = function() return {} end,
  eval = function(state) return state and state.vehicle == true end,
}

CAEVS.conditions.threat = {
  label = "Threat Level",
  init = function(data) return InitNumberData(data, 2) end,
  buildOptions = function(getData, setData)
    return BuildNumberOptions(getData, setData, "Threat (0-3)", 0, 3, 1)
  end,
  eval = function(state, data)
    return state and EvalNumber(state.threat or 0, data)
  end,
}

CAEVS.conditions.talentGroup = {
  label = "Talent Group",
  init = function(data)
    data = data or {}
    if data.group == nil then data.group = 1 end
    data.group = tonumber(data.group) or 1
    if data.group ~= 2 then data.group = 1 end
    return data
  end,
  buildOptions = function(getData, setData)
    return {
      group = {
        type = "select",
        name = "Group",
        order = 1,
        values = {
          [1] = "1 (Primary)",
          [2] = "2 (Secondary)",
        },
        get = function()
          local d = getData()
          return tonumber(d.group) or 1
        end,
        set = function(_, v)
          local d = getData()
          d.group = tonumber(v) or 1
          setData(d)
        end,
      },
      note = {
        type = "description",
        name = "On clients without dual spec, Talent Group is always treated as 1.",
        order = 99,
      },
    }
  end,
  eval = function(state, data)
    data = data or {}
    local want = tonumber(data.group) or 1
    local have = (state and state.talentGroup) or 1
    return have == want
  end,
}

CAEVS.conditions.inCity = {
  name = "In City",
  init = function(data)
    data = data or {}
    if data.mode ~= "hub" and data.mode ~= "resting" then
      data.mode = "hub"
    end
    return data
  end,
  buildOptions = function(get, set)
    return {
      mode = {
        type = "select",
        name = "Type",
        order = 1,
        values = {
          hub = "Major hubs (mapID)",
          resting = "Resting area (inn/city)",
        },
        get = function()
          local d = get() or {}
          return d.mode or "hub"
        end,
        set = function(_, v)
          local d = get() or {}
          d.mode = v
          set(d)
        end,
      },
    }
  end,
  eval = function(data)
    data = data or {}
    local mode = data.mode or "hub"

    if mode == "resting" then
      return IsResting() == true
    end

    -- hub mode (mapID allowlist)
    if not (C_Map and C_Map.GetBestMapForUnit) then
      return false
    end

    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return false end

    -- Major hubs / cities across Era + TBC + MoP
    return (mapID == 84)  -- Stormwind
        or (mapID == 85)  -- Orgrimmar
        or (mapID == 87)  -- Ironforge
        or (mapID == 88)  -- Thunder Bluff
        or (mapID == 89)  -- Darnassus
        or (mapID == 90)  -- Undercity
        or (mapID == 103) -- The Exodar
        or (mapID == 110) -- Silvermoon City
        or (mapID == 111) -- Shattrath City
        or (mapID == 391) or (mapID == 392) -- Shrine of Two Moons (micro)
        or (mapID == 393) or (mapID == 394) -- Shrine of Seven Stars (micro)
        -- optional hubs:
        or (mapID == 125) or (mapID == 126) -- Dalaran (city/underbelly)
  end,
}