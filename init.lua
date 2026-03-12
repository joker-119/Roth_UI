local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")

local mediaCallbacks = {}
local loadedCallbacks = {}
local configLoaded = false

local LoadedHandler = CreateFrame("Frame")
LoadedHandler:RegisterEvent("ADDON_LOADED")
LoadedHandler:SetScript("OnEvent", function(self, event, name)
  if name == "Roth_UI" then
    Roth_UI:LoadConfig()
    configLoaded = true
    for index, callback in pairs(loadedCallbacks) do
      callback()
    end
  end
end)

--- Callback to get notifications when addons loaded later than us have added shared media.
LSM.RegisterCallback(Roth_UI, "LibSharedMedia_Registered", function(name, mediaType, key)
  if configLoaded then
    for index, callback in pairs(mediaCallbacks) do
      callback(name, mediaType, key)
    end
  end
end)


--- Allows a callback to be registered for when LibSharedMedia registers new content
function Roth_UI:ListenForMediaChange(callback)
  table.insert(mediaCallbacks, callback)
end

function Roth_UI:ListenForLoaded(callback)
  table.insert(loadedCallbacks, callback)
end
