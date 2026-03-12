
-- rObjectiveTracker: core
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local addon, ns = ...
local cfg
L.addonName       = A
L.dragFrames      = {}
L.addonColor      = "00FF00AA"
L.addonShortcut   = "rot"
local objectiveFrame

-----------------------------
-- Init
-----------------------------

-- rObjectiveTracker hardening
local function ApplyTrackerLayout()
  if InCombatLockdown() then
    ns.Scheduler.After(0.2, ApplyTrackerLayout)
    return
  end
  objectiveFrame:ClearAllPoints()
  objectiveFrame:SetPoint(cfg.pos.a1, cfg.pos.af, cfg.pos.a2, cfg.pos.x, cfg.pos.y)
  objectiveFrame:SetSize(cfg.width, cfg.height)
  -- Only set scale if it actually changed (avoid needless relayout)
  local cur = objectiveFrame:GetScale() or 1
  if math.abs(cur - (cfg.scale or 1)) > 1e-3 then
    objectiveFrame:SetScale(cfg.scale or 1)
  end
end

local function Init()
cfg = ns.cfg.embeds.rObjectiveTracker
if not cfg.enabled then return end
    if Roth_UI:CheckClientVersion(WOW_PROJECT_CLASSIC) then
        objectiveFrame = QuestWatchFrame
    elseif Roth_UI:CheckClientVersion(WOW_PROJECT_MISTS_CLASSIC) then
        objectiveFrame = WatchFrame
    else
        objectiveFrame = ObjectiveTrackerFrame
    end
    ApplyTrackerLayout()
end

Roth_UI:RegisterInit(Init)


--drag frame
rLib:CreateDragResizeFrame(objectiveFrame, L.dragFrames, -2, true)

--create slash commands
rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)

Roth_UI:AddConfig("embeds.rObjectiveTracker", {}, "Objective Tracker", Init)