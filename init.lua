local addonName, ns = ...
_G.Roth_UI = ns -- make global so other files see the same object
PlayerFrame:UnregisterAllEvents()
PlayerFrame:Hide()

-- all your init stuff
local LSM = LibStub("LibSharedMedia-3.0")
local mediaCallbacks = {}
local initCallbacks = {}
local configLoaded = false

LSM.RegisterCallback(ns, "LibSharedMedia_Registered", function(name, mediaType, key)
  if configLoaded then
    for _, callback in pairs(mediaCallbacks) do
      callback(name, mediaType, key)
    end
  end
end)

function ns.RegisterInit(nameOrFunc, maybeFunc)
    local name, func

    if type(nameOrFunc) == "function" then
        func = nameOrFunc
        local info = debug.getinfo(func, "Sl") -- get definition site
        local src = (type(info.short_src) == "string" and info.short_src) or "?"
        local line = tonumber(info.linedefined) or 0
        name = ("%s:%d"):format(src:match("AddOns/.+") or src, line)
    else
        name = tostring(nameOrFunc) -- force string in case someone passed a table
        func = maybeFunc
    end

    local wrapped = function()
        local ok, err = xpcall(func, debugstack)
        if not ok then
            error(("Init callback failed:\n%s"):format(err))
        end
    end

    table.insert(initCallbacks, { name = name, func = wrapped })
end


function ns:Init()
    local errors = {}

    for _, cb in ipairs(initCallbacks) do
        local ok, err = xpcall(cb.func, debugstack)
        if not ok then
            table.insert(errors, ("Init callback failed:\n%s"):format( err))
        end
    end

    -- After running everything, dump errors (if any) through Blizzard’s handler
    if #errors > 0 then
        for _, msg in ipairs(errors) do
            geterrorhandler()(msg)
        end
    end

    wipe(initCallbacks)
end

function Roth_UI:CheckClientVersion(version)
    if WOW_PROJECT_ID ~= version then return false
    else return true
    end
end

function ns:ListenForMediaChange(callback)
  table.insert(mediaCallbacks, callback)
end
