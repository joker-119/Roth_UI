
-- rMinimap: core
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local addon, ns = ...
local cfg = ns.cfg

L.addonName       = A
L.dragFrames      = {}
L.addonColor      = "00FFAA00"
L.addonShortcut   = "rmm"

if not cfg.embeds.rMinimap then return end
-----------------------------
-- Init
-----------------------------

--MinimapCluster
MinimapCluster:SetScale(cfg.minimap.scale)
MinimapCluster:ClearAllPoints()
MinimapCluster:SetPoint(unpack(cfg.minimap.point))

--Minimap
Minimap:SetMaskTexture(mediapath.."mask2")
Minimap:ClearAllPoints()
Minimap:SetPoint("CENTER")
Minimap:SetSize(190,190) --correct the cluster offset
local function SetAlpha()
	Minimap:SetAlpha(cfg.minimap.alpha)
end
C_Timer.After(5, SetAlpha)



--hide regions
MinimapBackdrop:Hide()
MinimapCompassTexture:Hide()
Minimap.ZoomIn:Hide()
Minimap.ZoomOut:Hide()
MinimapCluster.BorderTop:Hide()
MinimapZoneText:Hide()

--dungeon info
MinimapCluster.InstanceDifficulty:ClearAllPoints()
MinimapCluster.InstanceDifficulty:SetPoint("TOP",Minimap,"TOP",0,-5)
MinimapCluster.InstanceDifficulty:SetScale(0.8)

--QueueStatusMinimapButton (lfi)
QueueStatusFrame:SetParent(Minimap)
QueueStatusFrame:SetScale(1)
QueueStatusFrame:ClearAllPoints()
QueueStatusFrame:SetPoint("BOTTOMLEFT",Minimap,0,0)
QueueStatusFrame:Hide()

--garrison (DIEEEEEE!!!)
ExpansionLandingPageMinimapButton:SetParent(Minimap)
ExpansionLandingPageMinimapButton:SetScale(1)


--mail
MailFrame:ClearAllPoints()
MailFrame:SetPoint("BOTTOMRIGHT",Minimap,-0,0)
MiniMapMailIcon:SetTexture(mediapath.."mail")


--MiniMapTracking
MinimapCluster.Tracking:SetParent(Minimap)
MinimapCluster.Tracking:SetScale(1)
MinimapCluster.Tracking:ClearAllPoints()
MinimapCluster.Tracking:SetPoint("TOPLEFT",Minimap,5,-5)

--Blizzard_TimeManager
LoadAddOn("Blizzard_TimeManager")
--TimeManagerClockButton:GetRegions():Hide()
TimeManagerClockButton:ClearAllPoints()
TimeManagerClockButton:SetPoint("BOTTOM",0,5)
TimeManagerClockTicker:SetFont(STANDARD_TEXT_FONT,12,"OUTLINE")
TimeManagerClockTicker:SetTextColor(0.8,0.8,0.6,1)

--GameTimeFrame
GameTimeFrame:SetParent(Minimap)
GameTimeFrame:SetScale(0.6)
GameTimeFrame:ClearAllPoints()
GameTimeFrame:SetPoint("TOPRIGHT",Minimap,-18,-18)
GameTimeFrame:SetHitRectInsets(0, 0, 0, 0)
GameTimeFrame:GetNormalTexture():SetTexCoord(0,1,0,1)
GameTimeFrame:SetNormalTexture(mediapath.."calendar")

--zoom
Minimap:EnableMouseWheel()
local function Zoom(self, direction)
  if(direction > 0) then Minimap_ZoomIn()
  else Minimap_ZoomOut() end
end
Minimap:SetScript("OnMouseWheel", Zoom)

--onenter/show
local function Show()
  GameTimeFrame:SetAlpha(0.9)
  TimeManagerClockButton:SetAlpha(0.9)
  MinimapCluster.Tracking:SetAlpha(0.9)
  MinimapCluster.InstanceDifficulty:SetAlpha(0.9)
  ExpansionLandingPageMinimapButton:SetAlpha(0.9)
  QueueStatusFrame:SetAlpha(0.9)
end
Minimap:SetScript("OnEnter", Show)

--onleave/hide
local lasttime = 0
local function Hide()
  if Minimap:IsMouseOver() then return end
  if time() == lasttime then return end
  GameTimeFrame:SetAlpha(0)
  TimeManagerClockButton:SetAlpha(0)
  MinimapCluster.Tracking:SetAlpha(0)
  MinimapCluster.InstanceDifficulty:SetAlpha(0)
  ExpansionLandingPageMinimapButton:SetAlpha(0)
  QueueStatusFrame:SetAlpha(0)
end
local function SetTimer()
  lasttime = time()
  C_Timer.After(1.5, Hide)
end
Minimap:SetScript("OnLeave", SetTimer)
rLib:RegisterCallback("PLAYER_ENTERING_WORLD", Hide)
Hide(Minimap)

--drag frame
rLib:CreateDragFrame(MinimapCluster, L.dragFrames, -2, true)

--create slash commands
rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)
