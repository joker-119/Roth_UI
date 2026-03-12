---
--- Created by joker.
--- DateTime: 2/24/2026 8:07 PM
---
local addon, ns = ...

local function afterSet()
    ns.Scheduler.Debounce("bars_config_reload", 0.75, function()
    Roth_UI:TriggerReload()
    end)
end

Roth_UI:AddConfig("bars", {}, "Action Bars", afterSet, true)