local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")
local fonts = AceGUIWidgetLSMlists.font

-- Font options
local fonts = {
  type = "group",
  name = "Fonts",
  order = 1,
  args = {
    headerFont = {
      type = "select",
      order = 1,
      name = "Header Font",
      dialogControl = 'LSM30_Font',
      desc = "Select the font you'd like to use for large displays, like character names, titles and headers",
      values = fonts, -- this table needs to be a list of keys found in the sharedmedia type you want
      get = function()
        return Roth_UI.db.profile.headerFont -- variable that is my current selection
      end,
      set = function(self,key)
        print("setting")
        Roth_UI.db.profile.headerFont = key -- saves our new selection the the current one
      end,
    },
    headerScale = {
      type = "range",
      order = 2,
      name = "Header Font Scale",
      desc = "Header Font Scale relative to WoW defaults",
      min = 0.5,
      max = 2.5,
      softMin = 0.75,
      softMax = 1.5,
      step = 0.01,
      bigStep = 0.05,
      get = function()
        return Roth_UI.db.profile.headerScale
      end,
      set = function(self, key)
        Roth_UI.db.profile.headerScale = key
      end,
    },
    textFont = {
      type = "select",
      order = 3,
      name = "Text Font",
      dialogControl = 'LSM30_Font',
      desc = "Select the font you'd like to use for detail information, like class strings, quest text and cooldowns",
      values = fonts, -- this table needs to be a list of keys found in the sharedmedia type you want
      get = function()
        return Roth_UI.db.profile.textFont -- variable that is my current selection
      end,
      set = function(self,key)
        Roth_UI.db.profile.textFont = key -- saves our new selection the the current one
      end,
    },
    textScale = {
      type = "range",
      order = 4,
      name = "Text Font Scale",
      desc = "Text Font Scale relative to WoW defaults",
      min = 0.5,
      max = 2.5,
      softMin = 0.75,
      softMax = 1.5,
      step = 0.01,
      bigStep = 0.05,
      get = function()
        return Roth_UI.db.profile.textScale
      end,
      set = function(self, key)
        Roth_UI.db.profile.textScale = key
      end,
    },
    chat = {
      type = "select",
      order = 5,
      name = "Chat Font",
      dialogControl = 'LSM30_Font',
      desc = "Select the font you'd like to use for chat",
      values = AceGUIWidgetLSMlists.font, -- this table needs to be a list of keys found in the sharedmedia type you want
      get = function()
        return Roth_UI.db.profile.chatFont -- variable that is my current selection
      end,
      set = function(self,key)
        Roth_UI.db.profile.chatFont = key -- saves our new selection the the current one
      end,
    },
    chatScale = {
      type = "range",
      order = 6,
      name = "Chat Font Scale",
      desc = "Chat Font Scale relative to WoW defaults",
      min = 0.5,
      max = 2.5,
      softMin = 0.75,
      softMax = 1.5,
      step = 0.01,
      bigStep = 0.05,
      get = function()
        return Roth_UI.db.profile.chatScale
      end,
      set = function(self, key)
        Roth_UI.db.profile.chatScale = key
      end,
    },
  }
}

-- Users likely wouldn't want to have different fonts for different characters.
local profileDefaults = {
  headerFont = "Expressway",
  headerScale = 1.0,
  textFont = "Expressway",
  textScale = 1.0,
  chatFont = "Expressway",
  chatScale = 1.0,
}

Roth_UI:AddConfig("fonts", fonts, profileDefaults)
