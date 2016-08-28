--get the addon namespace
local addon, ns = ...


---------------------------------------------
-- Variables
---------------------------------------------

local mediapath = "Interface\\AddOns\\Roth_UI\\media\\"
local cfg = {}
  
---------------------------------------------
-- Config
---------------------------------------------
cfg.backdrop = { bgFile = mediapath.."Tooltip_Background", edgeFile = mediapath.."Tooltip_Border",  tiled = false, edgeSize = 10, insets = {left=8, right=8, top=8, bottom=8} }
cfg.font = (mediapath.."ufonts.com_devils-snare.ttf")
	
---------------------------------------------
-- Functions
---------------------------------------------

local MenuSetup = function() end
	GameMenuFrame:SetBackdrop(cfg.backdrop)
	PaperDollItemsFrame.Text:SetFont(cfg.font, 13, "THINOUTLINE")
		
for id, btn in pairs({GameMenuFrame:GetChildren()}) do
	btn.Left:SetTexture(nil);
	btn.Right:SetTexture(nil);
	btn.Middle:SetTexture(nil);
	--btn:SetHighlightTexture(nil);
	btn.Text:SetFont(cfg.font, 13, "THINOUTLINE")
	
	btn.Left.SetTexture = MenuSetup;
	btn.Right.SetTexture = MenuSetup;
	btn.Middle.SetTexture = MenuSetup;
end
  