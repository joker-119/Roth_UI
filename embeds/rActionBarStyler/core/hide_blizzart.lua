
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg

  -----------------------------
  -- HIDE FRAMES
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
  --hide blizzard
  local pastebin = CreateFrame("Frame")
  pastebin:Hide()
  ns.pastebin = pastebin
  --hide main menu bar frames
  if gcfg.bars.bar1.enable then
    MainMenuBar:SetAlpha(0)
    ActionBarDownButton:SetAlpha(0)
    ActionBarUpButton:SetAlpha(0)
  end
  --hide override actionbar frames
  if gcfg.bars.overridebar.enable then
    OverrideActionBarExpBar:SetAlpha(0)
    OverrideActionBarHealthBar:SetAlpha(0)
    OverrideActionBarPowerBar:SetAlpha(0)
    OverrideActionBarPitchFrame:SetAlpha(0) --maybe we can use that frame later for pitchig and such
  end

  -----------------------------
  -- HIDE TEXTURES
  -----------------------------

  --remove some the default background textures
  StanceBarLeft:SetAlpha(0)
  StanceBarMiddle:SetAlpha(0)
  StanceBarRight:SetAlpha(0)
  SlidingActionBarTexture0:SetAlpha(0)
  SlidingActionBarTexture1:SetAlpha(0)
  PossessBackground1:SetAlpha(0)
  PossessBackground2:SetAlpha(0)

  if gcfg.bars.bar1.enable then
    MainMenuBarArtFrame.LeftEndCap:SetAlpha(0)
	MainMenuBarArtFrame.RightEndCap:SetAlpha(0)
	MainMenuBarArtFrameBackground.BackgroundSmall:SetAlpha(0)
	MainMenuBarArtFrameBackground.BackgroundLarge:SetAlpha(0)
  end

  --remove OverrideBar textures
  if gcfg.bars.overridebar.enable then
    local textureList =  {
      "_BG",
      "EndCapL",
      "EndCapR",
      "_Border",
      "Divider1",
      "Divider2",
      "Divider3",
      "ExitBG",
      "MicroBGL",
      "MicroBGR",
      "_MicroBGMid",
      "ButtonBGL",
      "ButtonBGR",
      "_ButtonBGMid",
    }

    for _,tex in pairs(textureList) do
      OverrideActionBar[tex]:SetAlpha(0)
    end
  end