---
--- Created by joker.
--- DateTime: 2/24/2026 6:27 PM
---
local addon, ns = ...
ns.Roles = ns.Roles or {}
local Roles = ns.Roles
        
function Roles.canDispelDebuff(type)
  	local class, _, _ = UnitClass("player")
  	if (type == 'Magic') then
  		return class == 'Shaman' or class == 'Paladin'
  	elseif (type == 'Curse') then
  		return class == 'Druid' or class == 'Mage' or class == 'Shaman'
  	elseif (type == 'Disease') then
  		return class == 'Monk' or class == 'Paladin' or class == 'Priest' or class == 'Shaman'
  	elseif (type == 'Poison') then
  		return class == 'Druid' or class == 'Monk' or class == 'Paladin' or class == 'Shaman'
  	else
  		return false
  	end
end