--get the addon namespace
local addon, ns = ...


---------------------------------------------
-- Variables
---------------------------------------------

local mediapath = "Interface\\AddOns\\Roth_UI\\media\\"
local cfg = ns.cfg
  
---------------------------------------------
-- Config
---------------------------------------------
cfg.backdrop = { bgFile = mediapath.."Tooltip_Background", edgeFile = mediapath.."Tooltip_Border",  tiled = false, edgeSize = 10, insets = {left=8, right=8, top=8, bottom=8} }
	
---------------------------------------------
-- Functions
---------------------------------------------

local MenuSetup = function() end
	--Skin the Game Menu
--	GameMenuFrame:SetBackdrop(cfg.backdrop)
	
	--Skin the Character Frame
