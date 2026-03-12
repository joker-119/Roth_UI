
  local parent, ns = ...
  local oUF = ns.oUF or oUF
   
  -- TBC absorb-ish auras (not exhaustive, add as you like)
  -- Use spell IDs if possible; fall back to spell name if needed.
  local TBC_ABSORB_AURAS = {
    -- Priest
    [17] = true,      -- Power Word: Shield (ranked, but 17 is the spell ID root; classic can be weird here)
    -- Mage
    [11426] = true,   -- Ice Barrier
    [1463] = true,    -- Mana Shield
    [13033] = true,
    -- Warlock
    [7812] = true,    -- Sacrifice (Voidwalker shield)
    -- Druid (if you want “fake absorb-ish” even though it's a heal absorb in later eras)
    -- Paladin
    -- Shaman
  }
  
  local function HasAnyAbsorbAura(unit)
    -- TBC-era UnitAura signature: UnitAura(unit, index, "HELPFUL")
    for i = 1, 40 do
      local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, "HELPFUL")
      if not name then break end
  
      -- Prefer spellId if available; otherwise you can match by name
      if spellId and TBC_ABSORB_AURAS[spellId] then
        return true
      end
    end
    return false
  end
  
  local function Update(self, event, unit)
    if(self.unit ~= unit) then return end
    
    local ta = self.TotalAbsorb
    if(ta.PreUpdate) then ta:PreUpdate(unit) end
   
    local allAbsorbs = UnitGetTotalAbsorbs(unit) or 0
    
    local maxHealth = UnitHealthMax(unit)
    
    if HasAnyAbsorbAura(unit) and Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) or Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then
        allAbsorbs = maxHealth * 0.25
    end
    
    --absorb does now overlay the healthbar from right to left
   
    if allAbsorbs > maxHealth then
      allAbsorbs = maxHealth
    end
   
    ta:SetMinMaxValues(0, maxHealth)
    ta:SetValue(allAbsorbs)
    ta:Show()
   
    if(ta.PostUpdate) then
      return ta:PostUpdate(unit,allAbsorbs,maxHealth)
    end
  end
   
  local function Path(self, ...)
    return (self.TotalAbsorb.Override or Update) (self, ...)
  end
   
  local ForceUpdate = function(element)
    return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
  end
   
  local function Enable(self)
    local ta = self.TotalAbsorb
    if(ta) then
      ta.__owner = self
      ta.ForceUpdate = ForceUpdate
   
      if Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) or Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
          self:RegisterEvent('UNIT_AURA', Path)
      else 
          self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
          self:RegisterEvent('UNIT_MAXHEALTH', Path)
      end
   
      --if(ta and ta:IsObjectType'StatusBar' and not ta:GetStatusBarTexture()) then
        --ta:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
      --end
   
      return true
    end
  end
   
  local function Disable(self)
    local ta = self.TotalAbsorb
    if(ta) then
      if Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) or Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
                self:UnregisterEvent('UNIT_AURA', Path)
            else 
                self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
                self:UnregisterEvent('UNIT_MAXHEALTH', Path)
            end
    end
  end
   
  oUF:AddElement('TotalAbsorb', Path, Enable, Disable)
