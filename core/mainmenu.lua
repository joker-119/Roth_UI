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
	GameMenuFrame:SetBackdrop(cfg.backdrop)

	--Skin the Character Frame
		--SetFonts
		CharacterFrameTitleText:SetFont(cfg.font.base, 18, "THINOUTLINE")
		CharacterLevelText:SetFont(cfg.font.base, 14, "THINOUTLINE")
		CharacterFrameTab1Text:SetFont(cfg.font.base, 12, "THINOUTLINE")
		CharacterFrameTab2Text:SetFont(cfg.font.base, 12, "THINOUTLINE")
		CharacterFrameTab3Text:SetFont(cfg.font.base, 12, "THINOUTLINE")
		ObjectiveTrackerBlocksFrame.QuestHeader.Text:SetFont(cfg.font.base, 16, "THINOUTLINE")
		CharacterStatsPane.ItemLevelCategory.Title:SetFont(cfg.font.base, 16, "THINOUTLINE")
		CharacterStatsPane.ItemLevelFrame.Value:SetFont(cfg.font.base, 16, "THINOUTLINE")
		CharacterStatsPane.AttributesCategory.Title:SetFont(cfg.font.base, 16, "THINOUTLINE")
		CharacterStatsPane.EnhancementsCategory.Title:SetFont(cfg.font.base, 16, "THINOUTLINE")
		for id, child in pairs({CharacterStatsPane:GetChildren()}) do
			if child.Value then
				child.Value:SetFont(cfg.font.base, 12, "THINOUTLINE")
			end
		end

		--Spell Book
		SpellBookFrameTitleText:SetFont(cfg.font.base, 16, "THINOUTLINE")
		SpellButton1SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton2SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton3SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton4SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton5SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton6SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton7SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton8SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton9SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton10SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton11SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")
		SpellButton12SpellName:SetFont(cfg.font.base, 12, "THINOUTLINE")


for id, btn in pairs({GameMenuFrame:GetChildren()}) do
	btn.Left:SetTexture(nil);
	btn.Right:SetTexture(nil);
	btn.Middle:SetTexture(nil);
	--btn:SetHighlightTexture(nil);
	btn.Text:SetFont(cfg.font.base, 13, "THINOUTLINE")

	btn.Left.SetTexture = MenuSetup;
	btn.Right.SetTexture = MenuSetup;
	btn.Middle.SetTexture = MenuSetup;
end
