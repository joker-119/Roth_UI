
local parent, ns = ...
local oUF = ns.oUF

local Update = function(self, event, unit)
	if(unit ~= self.unit) then return end

	local qicon = self.RareIcon
	if(qicon.PreUpdate) then
		qicon:PreUpdate()
	end

	local class = UnitClassification(unit)
	local boss = false
	for i=1,5 do
	    if UnitExists("boss"..i) and UnitGUID(unit) == UnitGUID("boss"..i) then
	        boss = true
	        break
	    end
	end
	if class == "worldboss" or class == "rare" or class == "rareelite" or UnitLevel(unit) == -1 then
	    boss = true
	end
	if boss then
		qicon:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target_boss")
	elseif class == "elite" then
		qicon:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target_elite")
	elseif class == "normal" then
		qicon:SetTexture("Interface\\AddOns\\Roth_UI\\media\\target")
	end

	if(qicon.PostUpdate) then
		return qicon:PostUpdate(isQuestBoss)
	end
end

local Path = function(self, ...)
	return (self.RareIcon.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local qicon = self.RareIcon
	if(qicon) then
		qicon.__owner = self
		qicon.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)

		return true
	end
end

local Disable = function(self)
	if(self.RareIcon) then
		self.RareIcon:Hide()
		self:UnregisterEvent('UNIT_CLASSIFICATION_CHANGED', Path)
	end
end

oUF:AddElement('RareIcon', Path, Enable, Disable)
