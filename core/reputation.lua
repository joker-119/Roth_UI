---
--- Created by joker.
--- DateTime: 2/24/2026 6:27 PM
---
local addon, ns = ...
ns.Reputation = ns.Reputation or {}
local Reputation = ns.Reputation

function Reputation.GetFactionData()
  if not (C_Reputation and C_Reputation.GetWatchedFactionData) then
      if GetWatchedFactionInfo then
          return GetWatchedFactionInfo()
      end
    return nil
  end

  local d = C_Reputation.GetWatchedFactionData()
  if not d or not d.name then
    return nil
  end

  -- Reaction/standing index (1..8)
  local standing = d.reaction or d.standing or d.standingID

  -- Thresholds + current value
  -- (Retail uses currentReactionThreshold/nextReactionThreshold/currentStanding)
  local min = d.currentReactionThreshold or d.minValue or d.currentThreshold
  local max = d.nextReactionThreshold or d.maxValue or d.nextThreshold
  local value = d.currentStanding or d.value or d.standingValue

  -- If any are missing, bail gracefully
  if not (standing and min and max and value) then
    return d.name, standing, min or 0, max or 1, value or 0
  end

  return d.name, standing, min, max, value
end