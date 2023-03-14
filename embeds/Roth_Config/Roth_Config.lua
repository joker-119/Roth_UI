local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")
local fonts = AceGUIWidgetLSMlists.font
local order = 1
local options = {
  type = "group",
  args = {}
}

local defaults = {
  profile = {},
  char = {}
}

--- Method to add module configuration into the Roth UI config block.
--  This method should not be invoked after LoadConfig has been called.
--  @param key The option key to add the local options to the options table.
--  @param newOptions The new options to add
--  @param profileDefaults Any defaults to be added at the profile level.
--  @param characterDefaults Any defaults to be added at the character level.
function Roth_UI:AddConfig(key, newOptions, profileDefaults, characterDefaults)
  newOptions.order = order
  if profileDefaults then
    for k,v in pairs(profileDefaults) do defaults.profile[k] = v end
  end
  if characterDefaults then
    for k,v in pairs(characterDefaults) do defaults.char[k] = v end
  end
  options.args[key] = newOptions
  order = order + 1
end

--- Method to both load configuration from the SavedVariables and initialize the options window.
function Roth_UI:LoadConfig()
  Roth_UI.db = LibStub("AceDB-3.0"):New("Roth_UI_DB", defaults)
  Roth_UI.db.RegisterCallback(Roth_UI, "OnProfileChanged", function()
    ReloadUI()
  end)
  options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(Roth_UI.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("Roth_Config", options, {"roth_config"})
  -- TODO Need to have this open up via slash command
  local OpenFunc = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Roth_Config", "Roth UI")
  -- This is to handle the situation where a reload happens...want to make sure we restart at order 1
  order = 1
  Roth_UI.cfg.font = LSM:Fetch("font", Roth_UI.db.profile.chatFont)
end
