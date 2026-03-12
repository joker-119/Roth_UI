
-- rButtonTemplate_Default: theme
-- zork, 2016

-- Default Button Theme for rButtonTemplate

-----------------------------
-- Variables
-----------------------------

local A, L = ...
local addon, ns = ...
local cfg = ns.cfg
if not cfg.embeds.rButtonTemplate then return end
-----------------------------
-- actionButtonConfig
-----------------------------

local actionButtonConfig = {}

--backdrop
actionButtonConfig.backdrop = {
  bgFile = mediapath.."backdrop",
  edgeFile = mediapath.."backdropBorder",
  tile = false,
  tileSize = 32,
  edgeSize = 5,
  insets = {
    left = 5,
    right = 5,
    top = 5,
    bottom = 5,
  },
  backgroundColor = {0.1,0.1,0.1,0.8},
  borderColor = {0,0,0,1},
  points = {
    {"TOPLEFT", -3, 3 },
    {"BOTTOMRIGHT", 3, -3 },
  },
}

--icon
actionButtonConfig.icon = {
  texCoord = {0.1,0.9,0.1,0.9},
  points = {
    {"TOPLEFT", 1, -1 },
    {"BOTTOMRIGHT", -1, 1 },
  },
}

--flyoutBorder
actionButtonConfig.flyoutBorder = {
  file = ""
}

--flyoutBorderShadow
actionButtonConfig.flyoutBorderShadow = {
  file = ""
}

--border
actionButtonConfig.border = {
  file = mediapath.."icon_border",
  points = {
    {"TOPLEFT", -2, 2 },
    {"BOTTOMRIGHT", 2, -2 },
  },
}

actionButtonConfig.checkedTexture = {
	file = mediapath.."gloss2",
	points = {
		{"TOPLEFT", -2, 2 },
		{ "BOTTOMRIGHT", 2, -2 },
	},
}

--normalTexture
actionButtonConfig.normalTexture = {
  file = mediapath.."icon_border",
  color = {0.5,0.5,0.5,0.6},
  points = {
    {"TOPLEFT", 0, 0 },
    {"BOTTOMRIGHT", 0, 0 },
  },
}

actionButtonConfig.pushedTexture = {
	file = mediapath.."pushed",
	points = {
		{ "TOPLEFT", -2, 2 },
		{ "BOTTOMRIGHT", 2, -2 },
	},
}

actionButtonConfig.highlightTexture = {
	file = mediapath.."icon_border",
	point = {
		{ "TOPLEFT", -2, 2 },
		{ "BOTTOMRIGHT", 2, -2 },
	},
}

--cooldown
if cfg.bars.showCooldown then
	actionButtonConfig.cooldown = {
		font = { STANDARD_TEXT_FONT, 15, "OUTLINE"},
		points = {
			{"TOPLEFT", 0, 0 },
			{"BOTTOMRIGHT", 0, 0 },
		},
		alpha = 1,
	}
else
	actionButtonConfig.cooldown = {
		alpha = 0,
	}
end

--name (macro name fontstring)
if cfg.bars.showName then
	actionButtonConfig.name = {
		font = { STANDARD_TEXT_FONT, 10, "OUTLINE"},
		points = {
			{"BOTTOMLEFT", 0, 0 },
			{"BOTTOMRIGHT", 0, 0 },
		},
		alpha = 1,
	}
else
	actionButtonConfig.name = {
		alpha = 0,
	}
end

--hotkey
if cfg.bars.showHotkey then
	actionButtonConfig.hotkey = {
		font = { STANDARD_TEXT_FONT, 11, "OUTLINE"},
		points = {
			{"TOPRIGHT", 0, 0 },
			{"TOPLEFT", 0, 0 },
		},
		alpha = 1,
	}
else
	actionButtonConfig.hotkey = {
		alpha = 0,
	}
end

--count
if cfg.bars.showStackCount then
	actionButtonConfig.count = {
		font = { STANDARD_TEXT_FONT, 11, "OUTLINE"},
		points = {
			{"BOTTOMRIGHT", 0, 0 },
		},
		alpha = 1,
	}
else
	actionButtonConfig.count = {
		alpha = 0,
	}
end

--rButtonTemplate:StyleAllActionButtons
rButtonTemplate:StyleAllActionButtons(actionButtonConfig)


-----------------------------
-- itemButtonConfig
-----------------------------

local itemButtonConfig = {}

itemButtonConfig.backdrop = actionButtonConfig.backdrop
itemButtonConfig.icon = actionButtonConfig.icon
itemButtonConfig.count = actionButtonConfig.count
itemButtonConfig.stock = actionButtonConfig.name
itemButtonConfig.border = actionButtonConfig.border
itemButtonConfig.highlightTexture = actionButtonConfig.highlightTexture
itemButtonConfig.normalTexture = actionButtonConfig.normalTexture

--rButtonTemplate:StyleItemButton
local itemButtons = { CharacterBag0Slot, CharacterBag1Slot, CharacterBag2Slot, CharacterBag3Slot }
for i, button in next, itemButtons do
  rButtonTemplate:StyleItemButton(button, itemButtonConfig)
end
for bag=0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
	for slot=1,C_Container.GetContainerNumSlots(bag) do
		local item = C_Container.GetContainerItemID(bag,slot);
		if (item) then
			local button = _G["ContainerFrame"..bag.."Item"..slot]
			rButtonTemplate:StyleItemButton(button, itemButtonConfig)
		end
	end
end

-----------------------------
-- extraButtonConfig
-----------------------------

local extraButtonConfig = actionButtonConfig
extraButtonConfig.buttonstyle = { file = "" }

--rButtonTemplate:StyleExtraActionButton
rButtonTemplate:StyleExtraActionButton(extraButtonConfig)

-----------------------------
-- auraButtonConfig
-----------------------------

local auraButtonConfig = {}

auraButtonConfig.backdrop = actionButtonConfig.backdrop
auraButtonConfig.icon = actionButtonConfig.icon
auraButtonConfig.border = actionButtonConfig.border
auraButtonConfig.border.texCoord = {0,1,0,1} --fix the settexcoord on debuff borders
auraButtonConfig.normalTexture = actionButtonConfig.normalTexture
auraButtonConfig.count = actionButtonConfig.count
auraButtonConfig.duration = actionButtonConfig.cooldown
auraButtonConfig.duration.points = {
                                     {"TOPRIGHT", 0, -3 },
                                     {"TOPLEFT", 0, -3 },
                                   }
auraButtonConfig.symbol = actionButtonConfig.name

--fix blizzard time abbrev
HOUR_ONELETTER_ABBR = "%dh"
DAY_ONELETTER_ABBR = "%dd"
MINUTE_ONELETTER_ABBR = "%dm"
SECOND_ONELETTER_ABBR = "%ds"

--rButtonTemplate:StyleAllAuraButtons
--rButtonTemplate:StyleAllAuraButtons(auraButtonConfig)
