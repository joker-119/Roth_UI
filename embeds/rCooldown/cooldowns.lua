-- Roth_UI/embeds/rCooldown/cooldowns.lua
-- Cooldown query wrappers for spells + items (Classic/TBC/MoP friendly)

local addon, ns = ...
local RC = ns.rCooldown
if not RC then return end

RC.Cooldowns = RC.Cooldowns or {}
local CD = RC.Cooldowns

local function Now()
  return GetTime()
end

local function Normalize(start, duration, enabled)
  start = tonumber(start) or 0
  duration = tonumber(duration) or 0
  enabled = tonumber(enabled) or 0

  local remaining = 0
  if enabled == 1 and start > 0 and duration > 0 then
    local t = (start + duration) - Now()
    if t > 0 then remaining = t end
  end

  return {
    start = start,
    duration = duration,
    enabled = enabled,
    remaining = remaining,
  }
end

-- ------------------------------------------------------------
-- Spells
-- ------------------------------------------------------------
function CD:GetSpellCooldown(spellID)
  if not spellID then
    return Normalize(0, 0, 0)
  end

  local start, duration, enabled = GetSpellCooldown(spellID)
  local out = Normalize(start, duration, enabled)

  -- Charges (guarded)
  if type(GetSpellCharges) == "function" then
    local charges, maxCharges, chargeStart, chargeDuration = GetSpellCharges(spellID)
    if charges ~= nil then
      out.charges = charges
      out.maxCharges = maxCharges
      out.chargeStart = chargeStart
      out.chargeDuration = chargeDuration
    end
  end

  -- Best-effort GCD hint:
  -- In Classic variants, GCD is typically ~1.5s (or 1.0s for some classes).
  -- We'll flag very short cooldowns as "likely gcd" so the model/frames can optionally ignore.
  if out.duration > 0 and out.duration <= 1.6 then
    out.isGCD = true
  else
    out.isGCD = false
  end

  return out
end

-- ------------------------------------------------------------
-- Items
-- ------------------------------------------------------------
function CD:GetItemCooldown(itemID)
  if not itemID then
    return Normalize(0, 0, 0)
  end

  local start, duration, enabled = GetItemCooldown(itemID)
  local out = Normalize(start, duration, enabled)
  out.isGCD = false
  return out
end

-- ------------------------------------------------------------
-- Unified dispatch
-- entry = { type="spell"/"item", id=number }
-- ------------------------------------------------------------
function CD:GetEntryCooldown(entry)
  if not entry or not entry.type then
    return Normalize(0, 0, 0)
  end
  if entry.type == "spell" then
    return self:GetSpellCooldown(entry.id)
  elseif entry.type == "item" then
    return self:GetItemCooldown(entry.id)
  end
  return Normalize(0, 0, 0)
end

function CD:IsOnCooldown(entry)
  local cd = self:GetEntryCooldown(entry)
  return (cd.remaining or 0) > 0, cd
end