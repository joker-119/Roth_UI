local ADDON, Addon = ...
local addonName, Roth_UI = ...
local addon, ns = ...
local cfg = ns.cfg
local LSM = LibStub("LibSharedMedia-3.0")

local headerFont = LSM:Fetch("font", "")
local textFont = LSM:Fetch("font", "")
local chatFont = LSM:Fetch("font", "")
local headerScale = 1
local textScale = 1
local chatScale = 1

if not cfg.embeds.RothFont then return end

------------------------------------------------------------------------
if cfg.font == STANDARD_TEXT_FONT then return end
local function SetFont(obj, font, size, style, r, g, b, sr, sg, sb, sox, soy)
	if not obj then return end -- TODO: prune things that don't exist anymore
	local fontFace = nil
	local fontScale = 1
	if font == "text" then
		fontFace = textFont
		fontScale = textScale
	elseif font == "header" then
		fontFace = headerFont
		fontScale = headerScale
	elseif font == "chat" then
		fontFace = chatFont
		fontScale = chatScale
	else
		print("Unknown font", obj, font, size, style, r, g, b, sr, sg, sb, sox, soy)
	end
	if fontScale == nil then
		fontScale = 1
	end
	obj:SetFont(fontFace, floor(size * fontScale), style)
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
	SetFont(Tooltip_Med,                        "header", 13)
	SetFont(Tooltip_Small,                      "text", 12)
	SetFont(SystemFont_Shadow_Small,            "text", 11) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Small2,           "text", 11) -- SharedFonts.xml
	SetFont(SystemFont_Small,                   "text", 12) -- SharedFonts.xml
	SetFont(SystemFont_Small2,                  "text", 12) -- SharedFonts.xml
	SetFont(SystemFont_Tiny,                    "text", 11) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med1,             "text", 13) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med1_Outline,     "text", 12, "OUTLINE") -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Med3,             "header", 15)
	SetFont(NumberFont_Shadow_Med,              "text", 14)
	SetFont(NumberFont_Shadow_Small,            "text", 12)
	SetFont(NumberFont_GameNormal,              "text", 13) -- orig 10 -- inherited by WhiteNormalNumberFont, tekticles = 11
	SetFont(AchievementFont_Small,              "text", 12)
	SetFont(ChatBubbleFont,                     "text", 13)
	SetFont(FriendsFont_Large,                  "header", 15, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_Normal,                 "text", 13, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_Small,                  "text", 11, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(FriendsFont_UserText,               "text", 12, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(GameTooltipHeader,                  "header", 15, "OUTLINE") -- SharedFonts.xml
	SetFont(InvoiceFont_Med,                    "header", 13, nil, 0.15, 0.09, 0.04)
	SetFont(InvoiceFont_Small,                  "text", 11, nil, 0.15, 0.09, 0.04)
	SetFont(MailFont_Large,                     "header", 15, nil, 0.15, 0.09, 0.04, 0.54, 0.4, 0.1, 1, -1)
	SetFont(NumberFont_GameNormal,              "text", 10)
	SetFont(NumberFont_Normal_Med,              "text", 14)
	SetFont(NumberFont_Outline_Med,             "text", 15, "OUTLINE")
	SetFont(NumberFont_OutlineThick_Mono_Small, "text", 13, "OUTLINE")
	SetFont(ReputationDetailFont,               "text", 12, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(SpellFont_Small,                    "text", 11)
	SetFont(SystemFont_InverseShadow_Small,     "text", 11)
	SetFont(SystemFont_Med1,                    "text", 13) -- SharedFonts.xml
	SetFont(SystemFont_Med3,                    "header", 15)
	SetFont(SystemFont_Outline,                 "text", 13, "OUTLINE")
	SetFont(SystemFont_Outline_Small,           "text", 13, "OUTLINE")
	SetFont(SystemFont_Med2,                    "text", 14, nil, 0.15, 0.09, 0.04)
	SetFont(SystemFont_Shadow_Med2,             "text", 14) -- SharedFonts.xml
	SetFont(QuestFontNormalSmall,               "header", 13, nil, nil, nil, nil, 0.54, 0.4, 0.1) -- inherits GameFontBlack

	-- Base fonts in Fonts.xml
	SetFont(CoreAbilityFont,                      "header", 32)
	SetFont(DestinyFontHuge,                      "header", 32)
	SetFont(DestinyFontLarge,                     "header", 18)
	SetFont(Game18Font,                         "text", 18)
	SetFont(Game24Font,                         "text", 24) -- there are two of these, good job Blizzard
	SetFont(Game27Font,                         "header", 27)
	SetFont(Game30Font,                         "header", 30)
	SetFont(Game32Font,                         "header", 32)
	SetFont(GameFont_Gigantic,                    "header", 32, nil, nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(NumberFont_Outline_Huge,            "text", 30, "THICKOUTLINE", 30)
	SetFont(NumberFont_Outline_Large,           "text", 17, "OUTLINE")
	SetFont(QuestFont_Enormous,                   "header", 30)
	SetFont(QuestFont_Huge,                       "header", 19)
	SetFont(QuestFont_Large,                    "header", 16) -- SharedFonts.xml
	SetFont(QuestFont_Shadow_Huge,                "header", 19, nil, nil, nil, nil, 0.54, 0.4, 0.1)
	SetFont(QuestFont_Shadow_Small,             "text", 16)
	SetFont(QuestFont_Super_Huge,                 "header", 24)
	SetFont(QuestFont_Super_Huge_Outline,         "header", 24, "OUTLINE")
	SetFont(SplashHeaderFont,                     "header", 24)
	SetFont(SystemFont_Huge1,                   "header", 20)
	SetFont(SystemFont_Huge1_Outline,           "header", 20, "OUTLINE")
	SetFont(SystemFont_Large,                   "header", 17)
	SetFont(SystemFont_OutlineThick_Huge2,      "header", 22, "THICKOUTLINE")
	SetFont(SystemFont_OutlineThick_Huge4,  "header", 27, "THICKOUTLINE")
	SetFont(SystemFont_OutlineThick_WTF,    "header", 31, "THICKOUTLINE", nil, nil, nil, 0, 0, 0, 1, -1)
	SetFont(SystemFont_OutlineThick_WTF2,   "header", 36) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge1,              "header", 20) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge2,              "header", 24) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Huge3,              "header", 25) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large,            "header", 17) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large2,           "header", 19) -- SharedFonts.xml
	SetFont(SystemFont_Shadow_Large_Outline,    "header", 17, "OUTLINE") -- SharedFonts.xml

	SetFont(SystemFont_Shadow_Outline_Huge2,    "text", 22, "OUTLINE") -- SharedFonts.xml

	-- Derived fonts in FontStyles.xml
	SetFont(BossEmoteNormalHuge,  "header", 27, "THICKOUTLINE") -- inherits SystemFont_Shadow_Huge3
	SetFont(CombatTextFont,           "text", 26) -- inherits SystemFont_Shadow_Huge3
	SetFont(ErrorFont,                "text", 16, nil, 60) -- inherits GameFontNormalLarge
	SetFont(WorldMapTextFont,     "header", 31, "THICKOUTLINE", 40, nil, nil, 0, 0, 0, 1, -1) -- inherits SystemFont_OutlineThick_WTF

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
			f:SetFont("chat", size)
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
		f:SetFont("chat", size, outline)
	end
end)

hooksecurefunc("BattlePetToolTip_Show", function()
	BattlePetTooltip:SetHeight(BattlePetTooltip:GetHeight() + 12)
end)

hooksecurefunc("FloatingBattlePet_Show", function()
	FloatingBattlePetTooltip:SetHeight(FloatingBattlePetTooltip:GetHeight() + 12)
end)


--- We may be using fonts that haven't loaded yet, so listen for them.
Roth_UI:ListenForMediaChange(function(name, mediaType, key)
	if mediaType == "font" then
		headerFont = LSM:Fetch("font", Roth_UI.db.profile.headerFont)
		textFont = LSM:Fetch("font", Roth_UI.db.profile.textFont)
		chatFont = LSM:Fetch("font", Roth_UI.db.profile.chatFont)
		Addon:SetFonts()
	end
end)

--- Need to set chat fonts as soon as the addon has loaded.
Roth_UI:ListenForLoaded(function()
	headerFont = LSM:Fetch("font", Roth_UI.db.profile.headerFont)
	textFont = LSM:Fetch("font", Roth_UI.db.profile.textFont)
	chatFont = LSM:Fetch("font", Roth_UI.db.profile.chatFont)
	headerScale = ns.db.profile.headerScale
	textScale = ns.db.profile.textScale
	chatScale = ns.db.profile.chatScale
	Addon:SetFonts()

	UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT = 14
	CHAT_FONT_HEIGHTS = { 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24 }

	-- I have no idea why the channel list is getting fucked up
	-- but re-setting the font obj seems to fix it


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
	WorldMapFrameHomeButtonText:SetFontObject(GameFontNormal)

end)
