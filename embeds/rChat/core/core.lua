
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
local addon, ns = ...
local cfg = ns.cfg
local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")
local chatFont = LSM:Fetch("font", "")
local chatScale = 1


if not cfg.embeds.rChat then return end

--new fadein func
FCF_FadeInChatFrame = function(self)
    self.hasBeenFaded = true
end

--new fadeout func
FCF_FadeOutChatFrame = function(self)
    self.hasBeenFaded = false
end

FCFTab_UpdateColors = function(self, selected)
    if (selected) then
        self:SetAlpha(cfg.selectedTabAlpha)
        self:GetFontString():SetTextColor(unpack(cfg.selectedTabColor))
        self.leftSelectedTexture:Show()
        self.middleSelectedTexture:Show()
        self.rightSelectedTexture:Show()
    else
        self:GetFontString():SetTextColor(unpack(cfg.notSelectedTabColor))
        self:SetAlpha(cfg.notSelectedTabAlpha)
        self.leftSelectedTexture:Hide()
        self.middleSelectedTexture:Hide()
        self.rightSelectedTexture:Hide()
    end
end


--add more chat font sizes
for i = 1, 23 do
    CHAT_FONT_HEIGHTS[i] = i+7
end

--hide the menu button

  -----------------------------
  -- FUNCTIONS
  -----------------------------

local function skinChat(self)
    local name = self:GetName()

    --chat frame resizing
    self:SetClampRectInsets(0, 0, 0, 0)
    self:SetMaxResize(UIParent:GetWidth(), UIParent:GetHeight())
    self:SetMinResize(100, 50)
    self:SetFrameStrata("HIGH")

    --chat fading
    --self:SetFading(false)

    --set font, outline and shadow for chat text
    self:SetFont(chatFont, floor(15 * chatScale), "THINOUTLINE")
    self:SetShadowOffset(1,-1)
    self:SetShadowColor(0,0,0,.5)

    --Skin Buttons
    ChatFrameMenuButton:SetNormalTexture(mediapath.."ChatButtons_36x36_ChatMenu")
    ChatFrameMenuButton:SetDisabledTexture(mediapath.."ChatButtons_36x36_ChatMenuDisabled", "BLEND")
    ChatFrameMenuButton:SetPushedTexture(mediapath.."ChatButtons_36x36_ChatMenuDisabled","BLEND")
    ChatFrameMenuButton:SetHighlightTexture(mediapath.."ChatButtons_36x36_ChatMenuHighlight", "BLEND")
    --[[_G[name.."ButtonFrameUpButton"]:SetNormalTexture(mediapath.."ChatButtons_36x36_Up")
    _G[name.."ButtonFrameUpButton"]:SetDisabledTexture(mediapath.."ChatButtons_36x36_UpDisabled", "BLEND")
    _G[name.."ButtonFrameUpButton"]:SetPushedTexture(mediapath.."ChatButtons_36x36_UpDisabled", "BLEND")
    _G[name.."ButtonFrameUpButton"]:SetHighlightTexture(mediapath.."ChatButtons_36x36_UpHighlight", "BLEND")
    _G[name.."ButtonFrameDownButton"]:SetNormalTexture(mediapath.."ChatButtons_36x36_Down")
    _G[name.."ButtonFrameDownButton"]:SetDisabledTexture(mediapath.."ChatButtons_36x36_DownDisabled", "BLEND")
    _G[name.."ButtonFrameDownButton"]:SetPushedTexture(mediapath.."ChatButtons_36x36_DownDisabled", "BLEND")
    _G[name.."ButtonFrameDownButton"]:SetHighlightTexture(mediapath.."ChatButtons_36x36_DownHighlight", "BLEND")
    _G[name.."ChatFrame.ScrollToBottomButton"]:SetNormalTexture(mediapath.."ChatButtons_36x36_Bottom")
    _G[name.."ChatFrameScrollToBottomButton"]:SetDisabledTexture(mediapath.."ChatButtons_36x36_BottomDisabled", "BLEND")
    _G[name.."ChatFrameScrollToBottomButton"]:SetPushedTexture(mediapath.."ChatButtons_36x36_BottomDisabled", "BLEND")
    _G[name.."ChatFrameScrollToBottomButton"]:SetHighlightTexture(mediapath.."ChatButtons_36x36_BottomHighlight", "BLEND")]]

    --editbox skinning
    _G[name.."EditBoxLeft"]:Hide()
    _G[name.."EditBoxMid"]:Hide()
    _G[name.."EditBoxRight"]:Hide()
    local eb = _G[name.."EditBox"]
    eb:SetAltArrowKeyMode(false)
    eb:ClearAllPoints()
    eb:SetPoint("BOTTOM",self,"TOP",0,22)
    eb:SetPoint("LEFT",self,-5,0)
    eb:SetPoint("RIGHT",self,10,0)

    --found this nice function, may need it sometime
    --ChatEdit_FocusActiveWindow --set focus on current active chatwindow editbox (nice lol)

    --chat tab skinning
    local tab = _G[name.."Tab"]
    local tabFs = tab:GetFontString()
    tabFs:SetFont(chatFont, floor(11 * chatScale), "THINOUTLINE")
    tabFs:SetShadowOffset(1,-1)
    tabFs:SetShadowColor(0,0,0,0.6)
    tabFs:SetTextColor(unpack(cfg.selectedTabColor))
    if cfg.hideChatTabBackgrounds then
        _G[name.."TabLeft"]:SetTexture(nil)
        _G[name.."TabMiddle"]:SetTexture(nil)
        _G[name.."TabRight"]:SetTexture(nil)
        _G[name.."TabSelectedLeft"]:SetTexture(nil)
        _G[name.."TabSelectedMiddle"]:SetTexture(nil)
        _G[name.."TabSelectedRight"]:SetTexture(nil)
        --_G[name.."TabGlow"]:SetTexture(nil) --do not hide this texture, it will glow when a whisper hits a hidden chat
        --_G[name.."TabHighlightLeft"]:SetTexture(nil)
        --_G[name.."TabHighlightMiddle"]:SetTexture(nil)
        --_G[name.."TabHighlightRight"]:SetTexture(nil)
    end
    tab:SetAlpha(cfg.selectedTabAlpha)

    self.skinApplied = true
end

--add emotes to scrolling text 
local function scrollingEmotes(self, event, message, sender, language, channelstring, target, ...)
	if not cfg.ScrollingEmotes then return end
	if event == "CHAT_MSG_EMOTE" or event == "CHAT_MSG_TEXT_EMOTE" then
			message = "|cffff4500"..(message).."|r"
			UIErrorsFrame:AddMessage(message)
	end
end


function Roth_UI:SkinChats()
    --hide the friend micro button
    QuickJoinToastButton:HookScript("OnShow", QuickJoinToastButton.Hide)
    QuickJoinToastButton:Hide()

    --don't cut the toastframe
    BNToastFrame:SetClampedToScreen(true)
    BNToastFrame:SetClampRectInsets(-15,15,15,-15)

    ChatFontNormal:SetFont(chatFont, floor(12 * chatScale), "THINOUTLINE")
    ChatFontNormal:SetShadowOffset(1,-1)
    ChatFontNormal:SetShadowColor(0,0,0,0.6)

    for i = 1, NUM_CHAT_WINDOWS do
        skinChat(_G["ChatFrame"..i])
    end
end
-----------------------------
-- CALL
-----------------------------

--skin temporary chats
hooksecurefunc("FCF_OpenTemporaryWindow", function()
    for _, chatFrameName in pairs(CHAT_FRAMES) do
        local frame = _G[chatFrameName]
        if (frame.isTemporary) then
            skinChat(frame)
        end
    end
end)

--combat log custom hider
local function fixStuffOnLogin()
	if cfg.HideCustomCombatLog then
    for i = 1, NUM_CHAT_WINDOWS do
        local name = "ChatFrame"..i
        local tab = _G[name.."Tab"]
        tab:SetAlpha(cfg.selectedTabAlpha)
    end
    CombatLogQuickButtonFrame_Custom:HookScript("OnShow", CombatLogQuickButtonFrame_Custom.Hide)
    CombatLogQuickButtonFrame_Custom:Hide()
    CombatLogQuickButtonFrame_Custom:SetHeight(0)
	else end
end

local a = CreateFrame("Frame")
a:RegisterEvent("PLAYER_LOGIN")
a:SetScript("OnEvent", fixStuffOnLogin)

local b = CreateFrame("Frame")
b:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
b:RegisterEvent("CHAT_MSG_EMOTE")
b:SetScript("OnEvent", scrollingEmotes)


Roth_UI:ListenForLoaded(function()
    chatFont = LSM:Fetch("font", Roth_UI.db.profile.chatFont)
    chatScale = Roth_UI.db.profile.chatScale
    Roth_UI:SkinChats()
end)

Roth_UI:ListenForMediaChange(function(name, mediaType, key)
    if mediaType == "font" and key == Roth_UI.db.profile.chatFont then
        chatFont = LSM:Fetch("font", Roth_UI.db.profile.chatFont)
        --chat skinning
        Roth_UI:SkinChats()
    end
end)
