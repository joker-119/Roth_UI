
-- rObjectiveTracker: core
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local addon, ns = ...
local cfg = ns.cfg
L.addonName       = A
L.dragFrames      = {}
L.addonColor      = "00FF00AA"
L.addonShortcut   = "rot"



-----------------------------
-- Init
-----------------------------

--ObjectiveTrackerFrame
ObjectiveTrackerFrame:SetScale(cfg.tracker.scale)
ObjectiveTrackerFrame:ClearAllPoints()
ObjectiveTrackerFrame:SetPoint(unpack(cfg.tracker.point))

--drag frame
rLib:CreateDragResizeFrame(ObjectiveTrackerFrame, L.dragFrames, -2, true)

--create slash commands
rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)