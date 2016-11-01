--get the addon namespace
local addon, ns = ...
local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")

local headerFont = LSM:Fetch("font", "")
local headerScale = 1

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
	GameMenuFrame:SetBackdrop(cfg.backdrop)

	--Skin the Character Frame

local function InitializeMenu()
	for id, btn in pairs({GameMenuFrame:GetChildren()}) do
		btn.Left:SetTexture(nil);
		btn.Right:SetTexture(nil);
		btn.Middle:SetTexture(nil);
		--btn:SetHighlightTexture(nil);
		btn.Text:SetFont(headerFont, floor(13 * headerScale), "THINOUTLINE")

		btn.Left.SetTexture = MenuSetup;
		btn.Right.SetTexture = MenuSetup;
		btn.Middle.SetTexture = MenuSetup;
	end
end


Roth_UI:ListenForLoaded(function()
	headerFont = LSM:Fetch("font", Roth_UI.db.profile.headerFont)
	headerScale = Roth_UI.db.profile.headerScale
	InitializeMenu()
end)

Roth_UI:ListenForMediaChange(function(name, mediaType, key)
	headerFont = LSM:Fetch("font", Roth_UI.db.profile.headerFont)
	InitializeMenu()
end)
