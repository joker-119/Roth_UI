-- Roth_UI/core/visibility.lua
local addon, ns = ...
ns.Visibility = ns.Visibility or {}
local Visibility = ns.Visibility

local registry = {}

local PROP = {
  shown = {
    get = function(f) return f:IsShown() and true or false end,
    set = function(f, v) if v then f:Show() else f:Hide() end end,
  },
  alpha = {
    get = function(f) return f:GetAlpha() end,
    set = function(f, v) f:SetAlpha(v) end,
  },
  scale = {
    get = function(f) return f:GetScale() end,
    set = function(f, v) f:SetScale(v) end,
  },
}

local function CaptureBaseline(frame, props)
  local baseline = {}
  for _, p in ipairs(props) do
    local def = PROP[p]
    if def and def.get then
      baseline[p] = def.get(frame)
    end
  end
  return baseline
end

local function ApplyProps(entry, desired)
  local frame = entry.frame
  for _, p in ipairs(entry.props) do
    local def = PROP[p]
    if def and def.set then
      local v = desired[p]
      if v ~= nil and entry.lastApplied[p] ~= v then
        entry.lastApplied[p] = v
        def.set(frame, v)
      end
    end
  end
end

-- Condition evaluation
local function RuleMatches(state, rule)
  local conds = rule and rule.conditions

  -- IMPORTANT CHANGE:
  -- A rule with no conditions should NOT match.
  -- (Use explicit "Always" condition if you want unconditional behavior.)
  if not conds or #conds == 0 then
    return false
  end

  local defs = ns.CAEVS and ns.CAEVS.conditions or {}
  for i = 1, #conds do
    local c = conds[i]
    local def = c and defs[c.id]
    if not def or not def.eval then
      return false
    end

    local ok = def.eval(state, c.data or {})
    if c.negate then ok = not ok end
    if not ok then return false end
  end
  return true
end

local function GetDB()
  return ns.db and ns.db.profile and ns.db.profile.caevs
end

local function GetEffectiveRules(entry)
  local db = GetDB()
  if not db then
    return entry.rules or {}, nil
  end

  if db.enabled == false then
    return nil, false
  end

  local el = db.elements and db.elements[entry.key]
  if el and el.enabled == false then
    return nil, false
  end

  local combined = {}

  local elRules = el and el.rules
  if elRules and #elRules > 0 then
    for i = 1, #elRules do combined[#combined + 1] = elRules[i] end
  end

  if entry.group and db.groups and db.groups[entry.group] then
    local grp = db.groups[entry.group]
    if grp.enabled ~= false then
      local gRules = grp.rules
      if gRules and #gRules > 0 then
        for i = 1, #gRules do combined[#combined + 1] = gRules[i] end
      end
    end
  end

  -- Back-compat: if DB has no rules, fall back to entry.rules
  if #combined == 0 and entry.rules and #entry.rules > 0 then
    return entry.rules, true
  end

  return combined, true
end

function Visibility.Register(key, frame, opts)
  if not key or not frame then return end
  opts = opts or {}

  local props = opts.props or { "shown" }

  local entry = {
    key = key,
    frame = frame,
    name = opts.name or key,
    group = (opts.group and opts.group ~= "" and opts.group) or nil,

    props = props,
    baseline = CaptureBaseline(frame, props),
    lastApplied = {},

    rules = opts.rules or {}, -- legacy hardcoded (fallback)
  }

  registry[key] = entry

  if ns.CAEVSConfig and ns.CAEVSConfig.NotifyRegistryChanged then
    ns.CAEVSConfig.NotifyRegistryChanged()
  end

  Visibility.Evaluate(key)
end

function Visibility.Evaluate(key)
  local entry = registry[key]
  if not entry then return end

  local state = ns.State and ns.State.Get and ns.State.Get() or {}

  local desired = {}
  for _, p in ipairs(entry.props) do
    desired[p] = entry.baseline[p]
  end

  local rules, enabled = GetEffectiveRules(entry)
  if enabled ~= false and rules then
    for i = 1, #rules do
      local rule = rules[i]
      if RuleMatches(state, rule) then
        if rule.set then
          for k, v in pairs(rule.set) do
            desired[k] = v
          end
        end
        break
      end
    end
  end

  ApplyProps(entry, desired)
end

function Visibility.EvaluateAll()
  for key in pairs(registry) do
    Visibility.Evaluate(key)
  end
end

function Visibility.Rebase(key)
  local entry = registry[key]
  if not entry then return end
  entry.baseline = CaptureBaseline(entry.frame, entry.props)
  Visibility.Evaluate(key)
end

function Visibility.GetRegistry()
  local out = {}
  for key, entry in pairs(registry) do
    out[#out + 1] = { key = key, name = entry.name or key, group = entry.group, props = entry.props }
  end
  return out
end

function Visibility.GetSortedRegistry()
  local groups, ungrouped = {}, {}

  local list = Visibility.GetRegistry()
  table.sort(list, function(a, b)
    local ga, gb = a.group or "", b.group or ""
    if ga == gb then
      return (a.name or a.key) < (b.name or b.key)
    end
    return ga < gb
  end)

  for _, e in ipairs(list) do
    if e.group then
      groups[e.group] = groups[e.group] or {}
      table.insert(groups[e.group], e)
    else
      table.insert(ungrouped, e)
    end
  end

  return { groups = groups, ungrouped = ungrouped }
end