-- Roth_UI/core/conditions/expr.lua
local addon, ns = ...

ns.Expr = ns.Expr or {}
local Expr = ns.Expr

local function ToBool(v) return v and true or false end

local function EvalLeaf(node, ctx)
  if not node or type(node) ~= "table" then return false end
  local kind = node.kind
  local cond = node.cond
  local value = node.value
  local negate = node.negate == true

  local res = false

  if kind == "caevs" then
    if ns.CAEVS and ns.CAEVS.EvalCondition then
      res = ToBool(ns.CAEVS:EvalCondition(cond, value, ctx and ctx.state))
    end
  elseif kind == "state" then
    if ns.State and ns.State.Eval then
      res = ToBool(ns.State.Eval(cond, value))
    end
  end

  if negate then res = not res end
  return res
end

local function EvalNode(node, ctx)
  if node == nil then
    -- nil tree means "always true"
    return true
  end

  if type(node) ~= "table" then
    return false
  end

  -- Leaf node
  if node.kind then
    return EvalLeaf(node, ctx)
  end

  local op = node.op
  local args = node.args

  if op == "NOT" then
    if type(args) ~= "table" or #args < 1 then return true end
    return not EvalNode(args[1], ctx)
  end

  if op == "AND" then
    if type(args) ~= "table" or #args == 0 then return true end
    for i = 1, #args do
      if not EvalNode(args[i], ctx) then
        return false
      end
    end
    return true
  end

  if op == "OR" then
    if type(args) ~= "table" or #args == 0 then return false end
    for i = 1, #args do
      if EvalNode(args[i], ctx) then
        return true
      end
    end
    return false
  end

  -- Unknown node; fail closed
  return false
end

-- Public: evaluate expression tree
-- ctx = { state = ns.State.Get() } optional
function Expr.Eval(tree, ctx)
  if not ctx then
    ctx = {}
  end
  if not ctx.state and ns.State and ns.State.Get then
    ctx.state = ns.State.Get()
  end
  return EvalNode(tree, ctx)
end