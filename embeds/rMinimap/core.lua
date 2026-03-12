-- rMinimap: unified Retail + Classic
-- Galaxy / zork / adapted

-----------------------------
-- Namespace
-----------------------------
local A, L = ...
local addon, ns = ...
local cfg

L = L or {}
L.addonName     = A or "rMinimap"
L.dragFrames    = L.dragFrames or {}
L.addonColor    = L.addonColor or "00FFAA00"
L.addonShortcut = L.addonShortcut or "rmm"

-----------------------------
-- Helper: apply mask
-----------------------------
local function RothUI_ApplyMinimapMask()
  if InCombatLockdown() then
    ns.Scheduler.After(0.2, RothUI_ApplyMinimapMask)
    return
  end
  if Minimap and ns.mediapath then
    Minimap:SetMaskTexture(ns.mediapath.."mask2")
  end
end

-----------------------------
-- Placement
-----------------------------
local function PlaceMinimapStuff()
  if InCombatLockdown() then
    ns.Scheduler.After(0.2, PlaceMinimapStuff)
    return
  end

  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    -- Retail: modern frames
    local idf = MinimapCluster and MinimapCluster.InstanceDifficulty
    if idf then
      idf:ClearAllPoints()
      idf:SetPoint("TOP", Minimap, "TOP", 0, -5)
    end

    if QueueStatusMinimapButton then
      QueueStatusMinimapButton:ClearAllPoints()
      QueueStatusMinimapButton:SetPoint("BOTTOMLEFT", Minimap, 0, 0)
      QueueStatusMinimapButton:SetAlpha(0.0)
      QueueStatusMinimapButton:EnableMouse(false)
    end

    if ExpansionLandingPageMinimapButton then
      ExpansionLandingPageMinimapButton:ClearAllPoints()
      ExpansionLandingPageMinimapButton:SetPoint("TOPRIGHT", Minimap, -4, -4)
      ExpansionLandingPageMinimapButton:SetScale(1)
    end

    if MailFrame then
      MailFrame:ClearAllPoints()
      MailFrame:SetPoint("BOTTOMRIGHT", Minimap, 0, 0)
    end
    if MiniMapMailIcon and ns.mediapath then
      MiniMapMailIcon:SetTexture(ns.mediapath.."mail")
    end

    if GameTimeFrame then
      GameTimeFrame:SetScale(0.6)
      GameTimeFrame:ClearAllPoints()
      GameTimeFrame:SetPoint("TOPRIGHT", Minimap, -18, -18)
      GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
      if ns.mediapath and GameTimeFrame.GetNormalTexture then
        local nt = GameTimeFrame:GetNormalTexture()
        if nt then nt:SetTexCoord(0,1,0,1) end
        GameTimeFrame:SetNormalTexture(ns.mediapath.."calendar")
      end
    end
  else
    -- Classic: older frames
    if MiniMapMailFrame then
      MiniMapMailFrame:ClearAllPoints()
      MiniMapMailFrame:SetPoint("BOTTOMRIGHT", Minimap, 0, 0)
      if MiniMapMailIcon and ns.mediapath then
        MiniMapMailIcon:SetTexture(ns.mediapath.."mail")
      end
      if MiniMapMailBorder then
        MiniMapMailBorder:SetTexture("Interface\\Calendar\\EventNotificationGlow")
        MiniMapMailBorder:SetBlendMode("ADD")
        MiniMapMailBorder:SetAlpha(0.5)
      end
    end

    if MiniMapLFGFrame then
      MiniMapLFGFrame:SetParent(Minimap)
      MiniMapLFGFrame:ClearAllPoints()
      MiniMapLFGFrame:SetPoint("BOTTOMLEFT", Minimap, 0, 0)
      MiniMapLFGFrame:Hide()
    end
  end

  RothUI_ApplyMinimapMask()
end

local function ForceMinimapRefresh()
  if not Minimap or not ns.mediapath then return end

  -- Re-apply shape
  Minimap:SetMaskTexture(ns.mediapath.."mask2")

  -- In Classic, also re-apply size correction
  if not Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    Minimap:SetSize(190,190)
  end

  -- Nudge redraw
  Minimap:SetZoom(Minimap:GetZoom())
end

-----------------------------
-- Init
-----------------------------
local function Init()
  cfg = ns.cfg.embeds.rMinimap
  if not cfg.enabled then return end

  -----------------------------
  -- Hide clutter
  -----------------------------
  if MinimapBackdrop then MinimapBackdrop:Hide() end
  if MinimapCompassTexture then MinimapCompassTexture:Hide() end
  if MinimapBorder then MinimapBorder:Hide() end
  if Minimap.ZoomIn then Minimap.ZoomIn:Hide() end
  if Minimap.ZoomOut then Minimap.ZoomOut:Hide() end
  if MinimapCluster and MinimapCluster.BorderTop then MinimapCluster.BorderTop:Hide() end
  if MinimapZoneText then MinimapZoneText:Hide() end
  if MinimapNorthTag then MinimapNorthTag:SetAlpha(0) end
  if MiniMapWorldMapButton then MiniMapWorldMapButton:Hide() end
  if MinimapBorderTop then MinimapBorderTop:Hide() end

  -----------------------------
  -- Scale / anchor
  -----------------------------
  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    Minimap:SetScale(cfg.scale)
    Minimap:SetAlpha(cfg.alpha)
    Minimap:SetPoint(cfg.pos.a1, cfg.pos.x, cfg.pos.y)
  else
    MinimapCluster:SetScale(cfg.scale or cfg.scale)
    MinimapCluster:ClearAllPoints()
    MinimapCluster:SetPoint(unpack(cfg.point or {cfg.pos.a1, UIParent, cfg.pos.a2, cfg.pos.x, cfg.pos.y}))
    Minimap:SetAlpha(cfg.alpha)
  end

  -----------------------------
  -- Optional textures (Retail only)
  -----------------------------
  if Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) then
    local bg = Minimap:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints(Minimap)
    if ns.mediapath then bg:SetTexture(ns.mediapath.."minimap_bg") end
    bg:SetAlpha(0.9)

    local ring = Minimap:CreateTexture(nil, "OVERLAY", nil, 7)
    ring:SetAllPoints(Minimap)
    if ns.mediapath then ring:SetTexture(ns.mediapath.."minimap_ring") end
    ring:SetBlendMode("ADD")
  end

  -----------------------------
  -- Placement via events
  -----------------------------
  local f = CreateFrame("Frame")
  f:RegisterEvent("PLAYER_LOGIN")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  f:RegisterEvent("PLAYER_REGEN_ENABLED")
  f:SetScript("OnEvent", function()
    ns.Scheduler.NextFrame(PlaceMinimapStuff)
  end)
  
  local refreshFrame = CreateFrame("Frame")
  refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
  refreshFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  refreshFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
  refreshFrame:RegisterEvent("ZONE_CHANGED")
  refreshFrame:RegisterEvent("PLAYER_LOGIN")
  refreshFrame:SetScript("OnEvent", function()
    ns.Scheduler.After(0.3, ForceMinimapRefresh)
  end)

  -----------------------------
  -- Mousewheel zoom
  -----------------------------
  Minimap:EnableMouseWheel(true)
  Minimap:SetScript("OnMouseWheel", function(self, direction)
    if direction > 0 then Minimap_ZoomIn() else Minimap_ZoomOut() end
  end)

  -----------------------------
  -- Classic-only clock/game time setup
  -----------------------------
     
    if TimeManagerClockButton then
      TimeManagerClockButton:GetRegions():Hide()
      TimeManagerClockButton:ClearAllPoints()
      TimeManagerClockButton:SetPoint("BOTTOM", 0, 5)
      TimeManagerClockTicker:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
      TimeManagerClockTicker:SetTextColor(0.8, 0.8, 0.6, 1)
    end
    if GameTimeFrame then
      GameTimeFrame:SetParent(Minimap)
      GameTimeFrame:SetScale(0.6)
      GameTimeFrame:ClearAllPoints()
      GameTimeFrame:SetPoint("TOPRIGHT", Minimap, -18, -18)
    end

    -- Hover fade (Classic feature)
    local function Show()
      if GameTimeFrame then
        GameTimeFrame:SetAlpha(0.9)
      end
      if TimeManagerClockButton then
        TimeManagerClockButton:SetAlpha(0.9)
      end
      if MiniMapLFGFrame then MiniMapLFGFrame:SetAlpha(0.9) end
      if MiniMapInstanceDifficulty then MiniMapInstanceDifficulty:SetAlpha(0.9) end
    end
    local lasttime = 0
    local function Hide()
      if Minimap:IsMouseOver() then return end
      if time() == lasttime then return end
      if GameTimeFrame then
        GameTimeFrame:SetAlpha(0)
      end
      if TimeManagerClockButton then
        TimeManagerClockButton:SetAlpha(0)
      end
      if MiniMapLFGFrame then MiniMapLFGFrame:SetAlpha(0) end
    end
    local function SetTimer()
      lasttime = time()
      ns.Scheduler.After(1.5, Hide)
    end
    Minimap:SetScript("OnEnter", Show)
    Minimap:SetScript("OnLeave", SetTimer)
    rLib:RegisterCallback("PLAYER_ENTERING_WORLD", Hide)
    Hide(Minimap)
    local Visibility = ns.Visibility
    
    Visibility.Register("minimap", Minimap, {
      name  = "Minimap",
      -- group omitted on purpose (ungrouped element)
    
      props = { "shown", "alpha", "scale" },
      rules = {
        {
          when = function(s)
            return s.inInstance == true and s.instanceType == "party"
          end,
          set = {
            shown = false,
            -- alpha = 0.5,
            -- scale = 0.9,
          },
        },
      },
    })
  end

  -----------------------------
  -- Drag & slash
  -----------------------------
  if rLib and rLib.CreateDragFrame then
    rLib:CreateDragFrame(MinimapCluster or Minimap, L.dragFrames, -2, true)
  end
  if rLib and rLib.CreateSlashCmd then
    rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)
  end


Roth_UI:RegisterInit(Init)

local config = {}

Roth_UI:AddConfig("embeds.rMinimap", config, "Minimap", Init, true)
