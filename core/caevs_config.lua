-- Roth_UI/core/caevs_config.lua
local addon, ns = ...
ns.CAEVSConfig = ns.CAEVSConfig or {}
local CAEVSConfig = ns.CAEVSConfig

local SECTION_NAME = "Context Visibility"
local AceConfigRegistry = LibStub and LibStub("AceConfigRegistry-3.0", true)
local Scheduler = ns.Scheduler
local BuildTree

local opts = {}

local function WipeTable(t) for k in pairs(t) do t[k] = nil end end

local function Ensure(tbl, key, default)
  if tbl[key] == nil then tbl[key] = default end
  return tbl[key]
end

local function EnsureDB()
  if not (ns.db and ns.db.profile) then return end
  ns.db.profile.caevs = ns.db.profile.caevs or { enabled = true, groups = {}, elements = {} }
  ns.db.profile.caevs.groups = ns.db.profile.caevs.groups or {}
  ns.db.profile.caevs.elements = ns.db.profile.caevs.elements or {}
end

local function Notify()
    BuildTree()
  if AceConfigRegistry then AceConfigRegistry:NotifyChange("Roth_UI") end
end

local function ApplyNow()
  if Scheduler and Scheduler.Throttle then
    Scheduler.Throttle("caevs_apply", 0.05, function()
      if ns.Visibility and ns.Visibility.EvaluateAll then ns.Visibility.EvaluateAll() end
    end)
  else
    if ns.Visibility and ns.Visibility.EvaluateAll then ns.Visibility.EvaluateAll() end
  end
end

local function Move(t, i, dir)
  local j = i + dir
  if j < 1 or j > #t then return end
  t[i], t[j] = t[j], t[i]
end

-- Tri-state shown select
local SHOWN_VALUES = { none="(no change)", show="Show", hide="Hide" }
local function GetShownKey(rule)
  local v = rule.set and rule.set.shown
  if v == nil then return "none" end
  if v == true then return "show" end
  return "hide"
end
local function SetShownKey(rule, key)
  rule.set = rule.set or {}
  if key == "none" then rule.set.shown = nil
  elseif key == "show" then rule.set.shown = true
  elseif key == "hide" then rule.set.shown = false end
end

-- Condition registry helpers
local function GetConditionDefs()
  return (ns.CAEVS and ns.CAEVS.conditions) or {}
end

local function BuildConditionValues()
  local defs = GetConditionDefs()
  local values = {}
  for id, def in pairs(defs) do
    values[id] = def.label or id
  end
  return values
end

local function PickDefaultConditionId()
  local defs = GetConditionDefs()
  for id in pairs(defs) do
    return id
  end
  return nil
end

local function InitCondition(id)
  local defs = GetConditionDefs()
  local def = defs[id]
  local c = { id = id, negate = false, data = {} }
  if def and def.init then
    c.data = def.init(c.data) or c.data
  end
  return c
end

local function InjectConditionsEditor(ruleArgs, rule, baseOrder)
  baseOrder = baseOrder or 0

  rule.conditions = rule.conditions or {}
  local conds = rule.conditions

  ruleArgs._cond_hdr = { type="header", name="Conditions (AND / NOT)", order = baseOrder + 0 }

  ruleArgs._cond_add = {
    type = "execute",
    name = "Add Condition",
    order = baseOrder + 1,
    disabled = function()
      local values = BuildConditionValues()
      return next(values) == nil
    end,
    func = function()
      local id = PickDefaultConditionId()
      if not id then return end
      conds[#conds + 1] = InitCondition(id)
      ApplyNow()
      Notify()
    end,
  }

  local o = baseOrder + 10

  for i = 1, #conds do
    local idx = i            -- ✅ freeze index for closures
    local c = conds[idx]
    local cKey = "_cond_" .. idx

    ruleArgs[cKey] = {
      type = "group",
      name = "Condition " .. idx,
      inline = true,
      order = o + idx,
      args = {},
    }

    local a = ruleArgs[cKey].args

    a.up = {
      type="execute", name="Up", width="half", order=1,
      disabled = function() return idx == 1 end,
      func = function()
        Move(conds, idx, -1)
        ApplyNow()
        Notify()
      end,
    }
    a.down = {
      type="execute", name="Down", width="half", order=2,
      disabled = function() return idx == #conds end,
      func = function()
        Move(conds, idx, 1)
        ApplyNow()
        Notify()
      end,
    }
    a.del = {
      type="execute", name="Delete", confirm=true, order=3,
      func = function()
        table.remove(conds, idx)
        ApplyNow()
        Notify()
      end,
    }

    a.id = {
      type = "select",
      name = "Type",
      values = function() return BuildConditionValues() end, -- ✅ live values
      order = 10,
      get = function() return c.id end,
      set = function(_, v)
        c.id = v
        c.data = {}
        local defs = GetConditionDefs()
        local def = defs[v]
        if def and def.init then
          c.data = def.init(c.data) or c.data
        end
        ApplyNow()
        Notify()
      end,
    }

    a.negate = {
      type = "toggle",
      name = "NOT",
      order = 11,
      get = function() return c.negate == true end,
      set = function(_, v) c.negate = v and true or false; ApplyNow() end,
    }

    -- condition-specific fields
    local defs = GetConditionDefs()
    local def = defs[c.id]
    if def and def.buildOptions then
      local function getData() return c.data or {} end
      local function setData(d) c.data = d or {}; ApplyNow() end
      local extra = def.buildOptions(getData, setData) or {}

      -- insert deterministically by order (AceConfig doesn’t guarantee pairs() order)
      local keys = {}
      for k in pairs(extra) do keys[#keys+1] = k end
      table.sort(keys)

      local startOrder = 20
      for _, k in ipairs(keys) do
        local opt = extra[k]
        if opt.order == nil then opt.order = startOrder end
        startOrder = startOrder + 1
        a["x_" .. k] = opt
      end
    end
  end
end

local function InjectRulesEditor(targetArgs, getRules, baseOrder)
  baseOrder = baseOrder or 0

  targetArgs._hdr_rules = { type="header", name="Rules", order = baseOrder + 0 }
  targetArgs._rules_info = { type="description", name="First match wins. Rules are evaluated top-to-bottom.", order = baseOrder + 1 }

  targetArgs._rules_add = {
    type = "execute",
    name = "Add Rule",
    order = baseOrder + 2,
    func = function()
      local rules = getRules(true)
      rules[#rules + 1] = { conditions = {}, set = {} }
      ApplyNow()
      Notify()
    end,
  }

  local rules = getRules(false) or {}
  local base = baseOrder + 10

  for i = 1, #rules do
    local idx = i           -- ✅ freeze index for closures
    local rule = rules[idx]
    local rKey = "_rule_" .. idx

    targetArgs[rKey] = {
      type = "group",
      name = "Rule " .. idx,
      inline = true,
      order = base + idx,
      args = {
        up = {
          type="execute", name="Up", width="half", order=1,
          disabled = function() return idx == 1 end,
          func = function() Move(rules, idx, -1); ApplyNow(); Notify() end,
        },
        down = {
          type="execute", name="Down", width="half", order=2,
          disabled = function() return idx == #rules end,
          func = function() Move(rules, idx, 1); ApplyNow(); Notify() end,
        },
        del = {
          type="execute", name="Delete", confirm=true, order=3,
          func = function() table.remove(rules, idx); ApplyNow(); Notify() end,
        },

        hdrA = { type="header", name="Actions", order=9 },

        shown = {
          type="select", name="Visibility", values=SHOWN_VALUES, order=10,
          get = function() return GetShownKey(rule) end,
          set = function(_, v) SetShownKey(rule, v); ApplyNow() end,
        },

        alphaEnable = {
          type="toggle", name="Override Alpha", order=11,
          get = function() return rule.set and rule.set.alpha ~= nil end,
          set = function(_, v)
            rule.set = rule.set or {}
            if not v then rule.set.alpha=nil else rule.set.alpha = rule.set.alpha or 1 end
            ApplyNow()
          end,
        },
        alpha = {
          type="range", name="Alpha", min=0, max=1, step=0.01, order=12,
          disabled = function() return not (rule.set and rule.set.alpha ~= nil) end,
          get = function() return (rule.set and rule.set.alpha) or 1 end,
          set = function(_, v) rule.set = rule.set or {}; rule.set.alpha=v; ApplyNow() end,
        },

        scaleEnable = {
          type="toggle", name="Override Scale", order=13,
          get = function() return rule.set and rule.set.scale ~= nil end,
          set = function(_, v)
            rule.set = rule.set or {}
            if not v then rule.set.scale=nil else rule.set.scale = rule.set.scale or 1 end
            ApplyNow()
          end,
        },
        scale = {
          type="range", name="Scale", min=0.5, max=2, step=0.01, order=14,
          disabled = function() return not (rule.set and rule.set.scale ~= nil) end,
          get = function() return (rule.set and rule.set.scale) or 1 end,
          set = function(_, v) rule.set = rule.set or {}; rule.set.scale=v; ApplyNow() end,
        },
      },
    }

    InjectConditionsEditor(targetArgs[rKey].args, rule, 30)
  end
end

BuildTree = function()
  EnsureDB()
  WipeTable(opts)

  opts.enabled = {
    type="toggle",
    name="Enable Context Visibility",
    order=0,
    get=function() return ns.db.profile.caevs.enabled ~= false end,
    set=function(_, v) ns.db.profile.caevs.enabled = v; ApplyNow() end,
  }

  if not ns.Visibility or not ns.Visibility.GetSortedRegistry then
    opts.notice = { type="description", name="CAEVS registry not available yet.", order=1 }
    return
  end

  local tree = ns.Visibility.GetSortedRegistry()
  local groups = tree.groups
  local ungrouped = tree.ungrouped
  local order = 10

  local function AddElementNode(parentArgs, e, nodeOrder)
    parentArgs[e.key] = { type="group", name=e.name or e.key, order=nodeOrder, args={} }
    local args = parentArgs[e.key].args

    args.enabled = {
      type="toggle",
      name="Enabled",
      order=0,
      get=function()
        local el = Ensure(ns.db.profile.caevs.elements, e.key, {})
        return el.enabled ~= false
      end,
      set=function(_, v)
        local el = Ensure(ns.db.profile.caevs.elements, e.key, {})
        el.enabled = v and true or false
        ApplyNow()
      end,
    }

    args.sep = { type="header", name="", order=1 }

    InjectRulesEditor(args, function(create)
      local el = Ensure(ns.db.profile.caevs.elements, e.key, {})
      if create then el.rules = el.rules or {} end
      return el.rules
    end, 2)
  end

  -- Ungrouped
  for _, e in ipairs(ungrouped) do
    AddElementNode(opts, e, order)
    order = order + 1
  end

  -- Groups
  local groupNames = {}
  for g in pairs(groups) do groupNames[#groupNames+1] = g end
  table.sort(groupNames)

  for _, g in ipairs(groupNames) do
    local elems = groups[g]
    if #elems == 1 then
      AddElementNode(opts, elems[1], order)
      order = order + 1
    else
      local gkey = "group_" .. g
      opts[gkey] = { type="group", name=g, order=order, args={} }
      order = order + 1
      local gargs = opts[gkey].args

      gargs.enabled = {
        type="toggle",
        name="Enabled (Group)",
        order=0,
        get=function()
          local grp = Ensure(ns.db.profile.caevs.groups, g, {})
          return grp.enabled ~= false
        end,
        set=function(_, v)
          local grp = Ensure(ns.db.profile.caevs.groups, g, {})
          grp.enabled = v and true or false
          ApplyNow()
        end,
      }
      gargs.sep = { type="header", name="", order=1 }

      InjectRulesEditor(gargs, function(create)
        local grp = Ensure(ns.db.profile.caevs.groups, g, {})
        if create then grp.rules = grp.rules or {} end
        return grp.rules
      end, 2)

      local childOrder = 50
      for _, e in ipairs(elems) do
        AddElementNode(gargs, e, childOrder)
        childOrder = childOrder + 1
      end
    end
  end
end

function CAEVSConfig.NotifyRegistryChanged()
  BuildTree()
  Notify()
end

function CAEVSConfig.Init()
  EnsureDB()
  BuildTree()
  if Roth_UI and Roth_UI.AddConfig then
    Roth_UI:AddConfig("caevs", opts, SECTION_NAME, function() end, false)
  end
end