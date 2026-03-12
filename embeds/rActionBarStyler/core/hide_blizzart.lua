
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

  --hide override actionbar frames
  if gcfg.bars.overridebar.enable and not Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then
    OverrideActionBarExpBar:SetAlpha(0)
    OverrideActionBarHealthBar:SetAlpha(0)
    OverrideActionBarPowerBar:SetAlpha(0)
    OverrideActionBarPitchFrame:SetAlpha(0) --maybe we can use that frame later for pitchig and such
  end

  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    MainStatusTrackingBarContainer:Hide()
    SecondaryStatusTrackingBarContainer:Hide()
    StatusTrackingBarManager:Hide()
end
  -----------------------------
  -- HIDE TEXTURES
  -----------------------------

  --remove some the default background textures
  --StanceBarLeft:SetAlpha(0)
  --StanceBarMiddle:SetAlpha(0)
  --StanceBarRight:SetAlpha(0)
  --SlidingActionBarTexture0:SetAlpha(0)
  --SlidingActionBarTexture1:SetAlpha(0)
  --PossessBackground1:SetAlpha(0)
  --PossessBackground2:SetAlpha(0)

local function hide()
    ns.Scheduler.NextFrame(function()
        MainMenuBar:Hide()
    end)
end

  if gcfg.bars.bar1.enable then
      ns.Scheduler.NextFrame(function()
      if not Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
                MainMenuBarLeftEndCap:SetAlpha(0)
                MainMenuBarRightEndCap:SetAlpha(0)
                MainMenuBarTexture0:SetAlpha(0)
                MainMenuBarTexture1:SetAlpha(0)
                MainMenuBarTexture2:SetAlpha(0)
                MainMenuBarTexture3:SetAlpha(0)
                MainMenuBar:Hide()
                MainMenuBar:EnableMouse(false)
                if Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
                  MainStatusTrackingBarContainer:Hide()
                  SecondaryStatusTrackingBarContainer:Hide()
                  MainActionBar.ActionBarPageNumber:Hide()
                else
                  MainMenuExpBar:Hide()
                  ReputationWatchBar:Hide()
                  ActionBarDownButton:SetAlpha(0)
                  ActionBarUpButton:SetAlpha(0)
                end
              else
              MainActionBar.EndCaps:SetAlpha(0)
          end
          
          local f = CreateFrame("Frame")
          f:RegisterEvent("PLAYER_ENTERING_WORLD")
          f:SetScript("OnEvent", function()
            hide()
          end)
      end)
      
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
        if OverrideActionBar then
            OverrideActionBar[tex]:SetAlpha(0)
        end
    end
  end
