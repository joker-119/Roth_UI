--Roth UI globals
local addon, ns = ...
local oUF = ns.oUF or oUF
local cfg = ns.cfg
local db = ns.db
local func = ns.func

--TRP globals
local Utils, Events, Globals = TRP3_API.utils, TRP3_API.events, TRP3_API.globals;
local loc, CreateFrame, EMPTY = TRP3_API.locale.getText, CreateFrame, Globals.empty;
local isPlayerIC, isUnitIDKnown, getUnitIDCurrentProfile, hasProfile, isIDIgnored;
local getConfigValue, registerConfigKey, registerConfigHandler, setConfigValue = TRP3_API.configuration.getValue, TRP3_API.configuration.registerConfigKey, TRP3_API.configuration.registerHandler, TRP3_API.configuration.setValue;
local assert, pairs, tinsert, table, math, _G = assert, pairs, tinsert, table, math, _G;
local getUnitID, unitIDToInfo, companionIDToInfo = Utils.str.getUnitID, Utils.str.unitIDToInfo, Utils.str.companionIDToInfo;
local setTooltipForSameFrame, mainTooltip, refreshTooltip = TRP3_API.ui.tooltip.setTooltipForSameFrame, TRP3_MainTooltip, TRP3_RefreshTooltipForFrame;
local get = TRP3_API.profile.getData;
local setupFieldSet = TRP3_API.ui.frame.setupFieldPanel;
local originalGetTargetType, getCompanionFullID = TRP3_API.ui.misc.getTargetType, TRP3_API.ui.misc.getCompanionFullID;
local getCompanionRegisterProfile, getCompanionProfile, companionHasProfile, isCurrentMine;
local TYPE_CHARACTER = TRP3_API.ui.misc.TYPE_CHARACTER;
local TYPE_PET = TRP3_API.ui.misc.TYPE_PET;
local TYPE_BATTLE_PET = TRP3_API.ui.misc.TYPE_BATTLE_PET;
local TYPE_NPC = TRP3_API.ui.misc.TYPE_NPC;


if not (IsAddonLoaded("Totalrp3") and cfg.TRPIntegration) then return end

oUF.Tags.Methods["diablo:name"] = function(unit)
	local UnitID = getUnitID(unit)
	if currentTargetType == TYPE_CHARACTER then
		local info = getCharacterInfo(UnitID);
		local name, realm = unitIDToInfo(UnitID);
		if info.characteristics then
			local name = info.characteristics.FN or UnitName(unit) .. " " .. (info.characteristics.LN or "");
		end
	elseif currentTargetType == TYPE_PET or currentTargetType == TYPE_BATTLE_PET then
		local owner, companionID = companionIDToInfo(UnitID);
		local info = getCompanionInfo(owner, companionID).data or EMPTY;
			local name = info.NA or companionID;
	elseif currentTargetType == TYPE_NPC then
			local name = UnitName(unit);
	end
	return name
end
	
