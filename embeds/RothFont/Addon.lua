local ADDON, Addon = ...
local addon, ns = ...
local cfg = ns.cfg

PhanxFontDB = {
	normal = "Lato",
	bold   = "Lato Black",
	scale  = 1,
}

local NORMAL       = cfg.font
local BOLD         = cfg.font
local BOLDITALIC   = BOLD
local ITALIC       = NORMAL
local NUMBER       = BOLD
local STANDARD     = cfg.chat.font

------------------------------------------------------------------------
if cfg.font == STANDARD_TEXT_FONT then return end
local function SetFont(obj, font, size, style, r, g, b, sr, sg, sb, sox, soy)
	if not obj then return end -- TODO: prune things that don't exist anymore
	obj:SetFont(font, floor(size * PhanxFontDB.scale + 0.5), style)
	if sr and sg and sb then
		obj:SetShadowColor(sr, sg, sb)
	end
	if sox and soy then
		obj:SetShadowOffset(sox, soy)
	end
	if r and g and b then
		obj:SetTextColor(r, g, b)
	elseif r then
		obj:SetAlpha(r)
	end
end

function Addon:SetFonts(event, addon)
	NORMAL     = NORMAL
	BOLD       = BOLD
	BOLDITALIC = BOLD
	ITALIC     = NORMAL
	NUMBER     = BOLD

	UNIT_NAME_FONT     = STANDARD_TEXT_FONT
	NAMEPLATE_FONT     = STANDARD_TEXT_FONT
	DAMAGE_TEXT_FONT   = NUMBER
	

	-- Base fonts in Fonts.xml
	SetFont(AchievementFont_Small,                BOLD, 12)
	SetFont(ChatBubbleFont,                     NORMAL, 13)
	SetFont(CoreAbilityFont,                      BOLD, 32)
	SetFont(DestinyFontHuge,                      BOLD, 32)
	SetFont(DestinyFontLarge,                     BOLD, 18)
	SetFont(FriendsFont_Large,                  NORMAL, 15, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_Normal,                 NORMAL, 13, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_Small,                  NORMAL, 11, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_UserText,               NUMBER, 12, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(Game18Font,                         NORMAL, 18)
	SetFont(Game24Font,                         NORMAL, 24) -- there are two of these, good job Blizzard
	SetFont(Game27Font,                         NORMAL, 27)
	SetFont(Game30Font,                         NORMAL, 30)
	SetFont(Game32Font,                         NORMAL, 32)
	SetFont(GameFont_Gigantic,                    BOLD, 32, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(GameTooltipHeader,                    BOLD, 15, "OUTLINE") -- SharedFonts.xml
	SetFont(InvoiceFont_Med,                    ITALIC, 13, nil, 0.15, 0.09, 0.04)
	SetFont(InvoiceFont_Small,                  ITALIC, 11, nil, 0.15, 0.09, 0.04)
	SetFont(MailFont_Large,                     ITALIC, 15, nil, 0.15, 0.09, 0.04, 0.54, 0.4, 0.1, 1, -1)
	SetFont(NumberFont_GameNormal,              NORMAL, 10)
	SetFont(NumberFont_Normal_Med,              NUMBER, 14)
	SetFont(NumberFont_Outline_Huge,            NUMBER, 30, "THICKOUTLINE", 30)
	SetFont(NumberFont_Outline_Large,           NUMBER, 17, "OUTLINE")
	SetFont(NumberFont_Outline_Med,             NUMBER, 15, "OUTLINE")
	SetFont(NumberFont_OutlineThick_Mono_Small, NUMBER, 13, "OUTLINE")
	SetFont(NumberFont_Shadow_Med,              NORMAL, 14)
	SetFont(NumberFont_Shadow_Small,            NORMAL, 12)
	SetFont(NumberFont_GameNormal,              NORMAL, 13) -- orig 10 -- inherited by WhiteNormalNumberFont, tekticles = 11
	SetFont(QuestFont_Enormous,                   BOLD, 30)
	SetFont(QuestFont_Huge,                       BOLD, 19)
	SetFont(QuestFont_Large,                    NORMAL, 16) -- SharedFonts.xml
	SetFont(QuestFont_Shadow_Huge,                BOLD, 19, nil, nil, nil, nil, 0.54, 0.4, 0.1)
	SetFont(QuestFont_Shadow_Small,             NORMAL, 16)
	SetFont(QuestFont_Super_Huge,                 BOLD, 24)
	SetFont(QuestFont_Super_Huge_Outline,         BOLD, 24, "OUTLINE")
	SetFont(ReputationDetailFont,                 BOLD, 12, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(SpellFont_Small,                      BOLD, 11)
	SetFont(SplashHeaderFont,                     BOLD, 24)
	SetFont(SystemFont_Huge1,                   NORMAL, 20)
	SetFont(SystemFont_Huge1_Outline,           NORMAL, 20, "OUTLINE")
	SetFont(SystemFont_InverseShadow_Small,       BOLD, 11)
	SetFont(SystemFont_Large,                   NORMAL, 17)
	SetFont(SystemFont_Med1,                    NORMAL, 13) -- SharedFonts.xml
	SetFont(SystemFont_Med2,                    ITALIC, 14, nil, 0.15, 0.09, 0.04)
	SetFont(SystemFont_Med3,                    NORMAL, 15)
	SetFont(SystemFont_Outline,                 NUMBER, 13, "OUTLINE")
	SetFont(SystemFont_Outline_Small,           NUMBER, 13, "OUTLINE")
	SetFont(SystemFont_OutlineThick_Huge2,      NORMAL, 22, "THICKOUTLINE")
	SetFont(SystemFont_OutlineThick_Huge4,  BOLDITALIC, 27, "THICKOUTLINE")
	SetFont(SystemFont_OutlineThick_WTF,    BOLDITALIC, 31, "THICKOUTLINE", nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(SystemFont_OutlineThick_WTF2,   BOLDITALIC, 36) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge1,              BOLD, 20) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge2,              BOLD, 24) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge3,              BOLD, 25) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large,            NORMAL, 17) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large2,           NORMAL, 19) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large_Outline,    NORMAL, 17, "OUTLINE") -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med1,             NORMAL, 13) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med1_Outline,     NORMAL, 12, "OUTLINE") -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med2,             NORMAL, 14) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med3,             NORMAL, 15)
	SetFont(SystemFont_Shadow_Outline_Huge2,    NORMAL, 22, "OUTLINE") -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Small,            NORMAL, 11) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Small2,           NORMAL, 11) -- SharedFonts.xml
	SetFont(SystemFont_Small,                   NORMAL, 12) -- SharedFonts.xml
	SetFont(SystemFont_Small2,                  NORMAL, 12) -- SharedFonts.xml
	SetFont(SystemFont_Tiny,                    NORMAL, 11) -- SharedFonts.xml
	SetFont(Tooltip_Med,                        NORMAL, 13)
	SetFont(Tooltip_Small,                        BOLD, 12)

	-- Derived fonts in FontStyles.xml
	SetFont(BossEmoteNormalHuge,  BOLDITALIC, 27, "THICKOUTLINE") -- inherits SystemFont_Shadow_Huge3
	SetFont(CombatTextFont,           NORMAL, 26) -- inherits SystemFont_Shadow_Huge3
	SetFont(ErrorFont,                ITALIC, 16, nil, 60) -- inherits GameFontNormalLarge
	SetFont(QuestFontNormalSmall,       BOLD, 13, nil, nil, nil, nil, 0.54, 0.4, 0.1) -- inherits GameFontBlack
	SetFont(WorldMapTextFont,     BOLDITALIC, 31, "THICKOUTLINE", 40, nil, nil, 0, 0, 0, 1, -1) -- inherits SystemFont_OutlineThick_WTF

	--[[ Fancy stuff!
	SetFont(ZoneTextFont,           BOLD, 31, "THICKOUTLINE") -- inherits SystemFont_OutlineThick_WTF
	SetFont(SubZoneTextFont,        BOLD, 27, "THICKOUTLINE") -- inherits SystemFont_OutlineThick_Huge4
	SetFont(PVPInfoTextFont,      NORMAL, 22, "THICKOUTLINE") -- inherits SystemFont_OutlineThick_Huge2
	]]

	-- Chat frames
	local _, size = ChatFrame1:GetFont()
	FCF_SetChatWindowFontSize(nil, ChatFrame1, size)
end

------------------------------------------------------------------------

local f = CreateFrame("Frame", "PhanxFont")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, addon)
	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	CHAT_FONT_HEIGHTS = { 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 }

	Addon:SetFonts()

	-- I have no idea why the channel list is getting fucked up
	-- but re-setting the font obj seems to fix it
	for i = 1, MAX_CHANNEL_BUTTONS do
		_G["ChannelButton"..i.."Text"]:SetFontObject(GameFontNormalSmallLeft)
	end

	for _, button in pairs(PaperDollTitlesPane.buttons) do
		button.text:SetFontObject(GameFontHighlightSmallLeft)
	end

	-- Fix help frame category buttons, NFI why they need fixing
	for i = 1, 6 do
		_G["HelpFrameButton"..i.."Text"]:SetFontObject(GameFontNormalMed3)
	end

	BattlePetTooltip.Name:SetFontObject(GameTooltipHeaderText)
	FloatingBattlePetTooltip.Name:SetFontObject(GameTooltipHeaderText)

	LFGListFrame.CategorySelection.CategoryButtons[1].Label:SetFontObject(GameFontNormal)
	WorldMapFrameNavBarHomeButtonText:SetFontObject(GameFontNormal)
end)

hooksecurefunc("FCF_SetChatWindowFontSize", function(self, frame, size)
	if not frame then
		frame = FCF_GetCurrentChatFrame()
	end
	if not size then
		size = self.value
	end

	-- Set all the other frames to the same size.
	for i = 1, 10 do
		local f = _G["ChatFrame"..i]
		if f then
			f:SetFont(STANDARD, size)
			SetChatWindowSize(i, size)
		end
	end

	-- Set the language override fonts to the same size.
	for _, f in pairs({
		ChatFontNormalKO,
		ChatFontNormalRU,
		ChatFontNormalZH,
	}) do
		local font, _, outline = f:GetFont()
		f:SetFont(font, size, outline)
	end
end)

hooksecurefunc("BattlePetToolTip_Show", function()
	BattlePetTooltip:SetHeight(BattlePetTooltip:GetHeight() + 12)
end)

hooksecurefunc("FloatingBattlePet_Show", function()
	FloatingBattlePetTooltip:SetHeight(FloatingBattlePetTooltip:GetHeight() + 12)
end)
