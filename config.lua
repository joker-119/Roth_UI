-----------------------------------------
-- Roth UI Config (Merged)
-----------------------------------------

local addonName, ns = ...
local LSM = LibStub("LibSharedMedia-3.0")

---------------------------------------------
-- NS globals
---------------------------------------------
Roth_UI.mediapath = "Interface\\AddOns\\Roth_UI\\media\\"
local playerMeta = {}
local cached = {}

function playerMeta.__index(_, key)
    if key == "name" then
        if not cached.name then
            cached.name = UnitName("player")
        end
        
        return cached.name
        
    elseif key == "class" then
        if not cached.class then
            cached.class = select(2, UnitClass("player"))
        end
        
        return cached.class
        
    elseif key == "spec" then
        return GetSpecialization()
    end
end

Roth_UI.player = setmetatable({}, playerMeta)

---------------------------------------------
-- AceDB Defaults
---------------------------------------------
Roth_UI.defaults = {
    profile = {
        powercolors = PowerBarColor,
        embeds = {
            rChat = {
                enabled = true,
                hideChatTabBackgrounds = true,
                selectedTabColor        = {1,0.75,0,1},
                notSelectedTabColor     = {0.5,0.5,0.5,0.3},
                HideCustomCombatLog     = true,
                ScrollingEmotes         = false,
                showPlayerLevels        = true,
            },
            rActionBarStyler = { enabled = true },
            rButtonTemplate = { enabled = true },
            rMinimap = {
                enabled = true,
                scale = 1,
                alpha = 0.5,
                pos = { a1 = "TOPRIGHT", x = 0, y = 20},
            },
            rNamePlates = {
                enabled = true,
                showHealthValue = true,
                healthValueAsPercent = true,
                fontSize = 25,
                largeInterruptableCasts = true,
            },
            rInfoStrings = { 
                enabled = true,
                scale = 0.95,
                pos = { a1 = "TOP", af = Minimap, a2 = "BOTTOM", x = 0, y = -25 },
                showXpRep = false,
                showMail  = false,
                showTime  = true,
            },
            rRaidManager = { enabled = true },
            rTooltip = {
                enabled = true,
                scale = 1.15,
                pos = { a1 = "BOTTOMRIGHT", af = UIParent, a2 = "BOTTOMRIGHT", x = -10, y = 100 },
                cursorfocus = false,
                showCraftingInfo = true,
                backdrop = {
                    bgFile = (ns.mediapath.."Tooltip_Background"),
                    edgeFile = (ns.mediapath.."Tooltip_Border"),
                    tile = true,
                    tileSize = 16,
                    edgeSize = 16,
                    insets = { left = 4, right = 4, top = 4, bottom = 4 },
                },
            },
            rLFGFilter = {
                enabled = true,
                tank = false,
                healer = false,
                dps = false,
                only5manInference = true,
            },
            tullaRange = { enabled = true },
            Roth_ShinyBuffs = { enabled = false },
            rObjectiveTracker = {
                enabled = true,
                scale = 1,
                pos = { a1 = "TOPRIGHT", x = -190, y = -200 },
                height = 450,
                width = 250,
            },
            RothFont = { enabled = true },
            rCooldown = {
              enabled = true,
              pos = { a1="CENTER", af="UIParent", a2="CENTER", x=0, y=-200 },
              global = {
                bar1Cap = 6,
                bar2Cap = 6,
                overflowCap = 0, -- 0 = unlimited
            
                updateInterval = 0.10,
                readyFlashPersistence = 2.0,
                readyHideDelay = 3.0,
            
                defaultReminderFlashTime = 3.0,
                defaultReadyFlash = true,
                defaultPersistence = false,
                defaultHideWhenReady = true,
                iconSize = 36,
                iconSpacing = 6,
                fontSize = 14,
                ignoreGCD = false,
                layoutMode = "static",
              },
              class = {},
            },
        },
        colorswitcher = {
            bright              = { r = 1, g = 0, b = 0, a = 1 },
            dark                = { r = 1, g = 0, b = 0, a = 0.1 },
            classcolored        = true,
            useBrightForeground = true,
            threatColored       = true,
        },
        highlightMultiplier = 0,
        units = {}, -- Populated below
        bars = {},  -- Populated below
        framesUserplaced = true,
        framesLocked = true,
        stateStrip = {
          enabled = true,
        
          -- Layout / visuals
          iconSize = 20,
          spacing = 4,
          maxIcons = 8,
          hideWhenEmpty = true,
          activeAlpha = 1,
          inactiveAlpha = 0,
        
          -- Global timing
          expiringThreshold = 12,        -- seconds (used when a tracked buff threshold = 0)
          testAutoClear = true,
          testAutoClearSeconds = 10,     -- seconds
          missingGraceSeconds = 5,       -- seconds after zone/login before missing-buff alerts appear
        
          -- Threshold signals
          lowHealthPct = 35,             -- %
          lowManaPct = 15,               -- %
          durabilityPct = 20,            -- %
        
          -- Max resource warning (for non-mana users)
          maxResourcePct = 90,           -- % (config clamps 80-100)
        
          -- Position (optional; leave empty for your ApplyPosition default behavior)
          pos = {
            a1 = "BOTTOM",
            af = "UIParent",
            a2 = "BOTTOM",
            x = 0,
            y = 160,
          },
        
          -- Signals toggles
          signals = {
            trackedBuffs = true,         -- shows tracked buffs (expiring / showFull)
            trackedDebuffs = true,       -- shows tracked debuffs (always / expiring based on per-aura config)
            missingBuffs = true,         -- only for buffs with alertMissing=true
            debuffTypes = true,          -- Magic/Curse/Poison/Disease indicators (one per type)
            lowHealth = true,
            lowMana = true,
            durabilityLow = true,
            weaponEnchant = false,
            weaponEnchantOOCOnly = true,
            maxResource = false,
          },
        
          -- Debuff type toggles (only used if signals.debuffTypes is true)
          debuffType = {
            magic = true,
            curse = true,
            poison = true,
            disease = true,
          },
        
          -- Tracked auras
          -- Keys are either spellID strings ("12345") or normalized names (lowercase)
          -- Values are per-aura settings tables.
          track = {
            buffs = {
              -- Example:
              -- ["6774"] = { enabled = true, threshold = 5, showFull = false, alertMissing = true }, -- Slice and Dice example (spellID differs by era)
            },
            debuffs = {
              -- Example:
              -- ["118"] = { enabled = true, threshold = 0, showFull = true }, -- Polymorph (always show)
            },
          },
        
          -- Priority ordering (lower number = higher priority)
          -- String keys only (NO numeric arrays) to keep your config generator happy.
          priority = {
            cc = 10,               -- reserved (future)
            debuffTypes = 15,
            trackedDebuffs = 20,
            expiringBuffs = 30,
            missingBuffs = 40,
            durabilityLow = 45,
            lowHealth = 50,
            lowMana = 60,
            weaponEnchant = 70,
            maxResource = 80,
          },
        },
    },
}

---------------------------------------------
-- Populate defaults.profile.units from original cfg.units
---------------------------------------------
Roth_UI.defaults.profile.units = {
    -- PLAYER
    player = {
      show = true,
      size = 160,
      scale = 1,
      pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -264, y = 2 },
      health = {
        frequentUpdates = true,
        smooth = true,
      },
      power = {
        frequentUpdates = true,
        smooth = true,
      },
      absorb = {
        show = true,
        smooth = true,
      },
      healprediction = { --WIP
        show = true,
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.25,
      },
      swingtimer = {
        show = true,
        scale = 1,
        width = 240,
        height = 8,
        spacing = 4, -- vertical spacing between MH/OH bars
        texture = (ns.mediapath.."statusbar2"),
        bgAlpha = 0.30,
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 140 },

        -- Feature 1: paladin tick marker showing "0.4s before swing"
        paladinTickSeconds = 0.4,

        -- Feature 2: dual wield delta readout (ms) showing how far ahead MH is vs OH
        showDualWieldDelta = true,
        colorMode = "fixed",
        color = { r = 0.85, g = 0.75, b = 0.30, a = 1 },

        -- Paladin twist timing confirmation flash (independent of proc RNG)
        enableTwistFlash = true,
        twistFlashDuration = 0.18, -- seconds
        twistFlashAlpha = 0.85,    -- max alpha for the flash
      },
      icons = {
        pvp = {
          show = true,
          pos = { a1 = "CENTER", a2 = "CENTER", x = -95, y = 42 }, --position in relation to self object
        },
        combat = {
          show = true,
          pos = { a1 = "CENTER", a2 = "CENTER", x = 0, y = 86 }, --position in relation to self object
        },
        resting = {
          show = true,
          pos = { a1 = "CENTER", a2 = "CENTER", x = -72, y = 60 }, --position in relation to self object
        },
      },
      castbar = {
        show = true,
		fontSize = 11,
        hideDefault = true, --if you hide the Roth_UI castbar, should the Blizzard castbar be shown?
        latency = true,
        texture = (ns.mediapath.."statusbar3"),
        scale = 1/1, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 0, g = 0.5, b = 1, a = 0.8, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },
        },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 180.5 },
      },
      soulshards = { --class bar WARLOCK / AFFLICTION
        show = true,
        scale = 0.40,
        color = {r = 200/255, g = 0/255, b = 255/255, },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
      holypower = { --class bar PALADIN
        show = true,
        scale = 0.40,
        color = {r = 200/255, g = 135/255, b = 190/255, },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
      harmony = { --class bar MONK
        show = true,
        scale = 0.40,
        color = {r = 41/255, g = 209/255, b = 157/255, },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
      runes = { --class bar DK
        show = true,
        scale = 0.40,
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
      combobar = {
        show = true,
        scale = 0.40,
        color = {r = 0.9, g = 0.59, b = 0, },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
	  arcbar = {
        show = true,
        scale = 0.40,
        color = {r = 0.14, g = 0.56, b = .9, },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 650 },
        combat          = { --fade the bar in/out in combat/out of combat
          enable          = false,
          fadeIn          = {time = 0.4, alpha = 1},
          fadeOut         = {time = 0.3, alpha = 0.2},
        },
      },
      altpower = {
        show = true,
        scale = 1,
        texture = (ns.mediapath.."statusbar3"),
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 0, y = 0 },
      },
      expbar = { --experience
        show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 9 },
          texture = (ns.mediapath.."statusbar2"),
          scale = 1,
          color = {r = 0.8, g = 0, b = 0.8, },
          rested = {
            color = {r = 1, g = 0.7, b = 0, },
          },
      },
      repbar = { --reputation
        show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 20 },
          texture = (ns.mediapath.."statusbar2"),
          scale = 1,
      },
	  artifactpower = {
		show = true,
			pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 15 },
			texture = (ns.mediapath.."statusbar2"),
			scale = 1,
	  },
      art = {
        actionbarbackground = {
          show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 0 },
          scale = 1,
		  combatfade = true,
        },
        angel = {
          show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 265, y = 0 },
          scale = 1,
        },
        demon = {
          show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -270, y = 0 },
          scale = 1,
        },
        bottomline = {
          show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = -5 },
          scale = 1,
        },
      },
      portrait = {
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = -100, y = 0 },
        size = 150,
        show = false,
        use3D = true,
      },
    },

    -- TARGET
    target = {
      show = true,
      scale = 1.5,
	  width = 300,
      height = 64,
      pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = 0, y = -70 },
      health = {
	frequentUpdates = true,
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:hpval]",
		fontSize = 7,
		textPos = "RIGHT",
		x = 25,
		y = -30,
      },
	  healper = {
	frequentUpdates = true,
		tag = "[perphp]",
		fontSize = 10,
		textPos = "CENTER",
		x = 0,
		y = 0,
	  },
	  powper = {
	frequentUpdates = true,
		tag = "[perpp]%",
		fontSize = 7,
		textPos = "CENTER",
		x = 0,
		y = 0,
	  },
      power = {
	frequentUpdates = true,
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:ppval]",
		fontSize = 7,
		textPos = "LEFT",
		x = -25,
		y = -30,
      },
	  fontSize = {
		class = 13,
		name = 16,
	  },
      auras = {
        show = true,
        size = 15,
        onlyShowPlayerBuffs = false,
        showStealableBuffs = true,
        onlyShowPlayerDebuffs = true,
        showDebuffType = true,
        desaturateDebuffs = false,
        disableCooldownText = false,
        buffs = {
          pos = { a1 = "BOTTOMLEFT", a2 = "TOPRIGHT", x = 0, y = -15 },
          initialAnchor = "BOTTOMLEFT",
          growthx = "RIGHT",
          growthy = "UP",
        },
        debuffs = {
          pos = { a1 = "TOPLEFT", a2 = "BOTTOMRIGHT", x = 0, y = 15 },
          initialAnchor = "TOPLEFT",
          growthx = "RIGHT",
          growthy = "DOWN",
        },
      },
      castbar = {
        show = true,
		fontSize = 11,
        texture = (ns.mediapath.."statusbar3"),
        scale = 1/1.5, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 0, g = 0.5, b = 1, a = .7, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 1, },
          shieldbar = { r = 0.5, g = 0.5, b = 0.5, a = 1, }, --the castbar color while target casting a shielded spell
          shieldbg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },  --the castbar background color while target casting a shielded spell
        },
        pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = -10, y = -125 },
      },
      portrait = {
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 100, y = 0 },
        size = 150,
        show = false,
        use3D = true,
      },
      healprediction = {
        show = true,
        texture = (ns.mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
      totalabsorb = {
        show = true,
        texture = (ns.mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --TARGETTARGET
    targettarget = {
      show = true,
	  width = 150,
      height = 64,
      scale = 1.3,
      pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = -238, y = -80 },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = true,
      },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
      healprediction = {
        show = true,
        texture = (ns.mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
    },

    --PET
    pet = {
      show = true,
      scale = 0.85,
	  width = 128,
      height = 64,
      pos = { a1 = "RIGHT", a2 = "RIGHT", af = "UIParent", x = -30, y = -140 },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = false,
      },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
      altpower = {
        show = false,
        scale = 0.5,
        color = {r = 1, g = 0, b = 1, },
        texture = (ns.mediapath.."statusbar3"),
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 0, y = 0 },
      },
      portrait = {
        show = true,
        use3D = false,
      },
      castbar = {
        show = false,
        hideDefault = true, --if you hide the Roth_UI castbar, should the Blizzard castbar be shown?
        texture = "Interface\\AddOns\\Roth_UI\\media\\statusbar3",
        scale = 1/0.85, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 1, g = 0.7, b = 0, a = 1, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },
        },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 490 },
      },
      totalabsorb = {
        show = true,
        texture = (ns.mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --FOCUS
    focus = {
      show = true,
	  width = 128,
      height = 64,	  
      scale = 0.85,
      pos = { a1 = "CENTER", a2 = "BOTTOM", af = "UIParent", x = 0, y = 350 },
      aurawatch = {
        show            = false,
        size            = 20,
      },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = false,
        showBuffs = true,
        onlyShowPlayerBuffs = false,
        showBuffType = false,
      },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
      portrait = {
        show = true,
        use3D = false,
      },
      castbar = {
        show = false,
		fontSize = 11,
        texture = (ns.mediapath.."statusbar3"),
        scale = 1/1.9, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 1, g = 0.7, b = 0, a = 1, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },
        },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 420 },
      },
      healprediction = {
        show = true,
        texture = (ns.mediapath.."statusbar128_3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
      totalabsorb = {
        show = true,
        texture = (ns.mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --PETTARGET
    pettarget = {
      show = false,
	  width = 128,
      height = 64,
      scale = 0.85,
      pos = { a1 = "LEFT", a2 = "LEFT", af = "UIParent", x = 140, y = -140 },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = false,
      },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
      portrait = {
        show = true,
        use3D = true,
      },
    },

    --FOCUSTARGET
    focustarget = {
      show = false,
	  width = 128,
      height = 64,
      scale = 0.85,
      pos = { a1 = "LEFT", a2 = "LEFT", af = "UIParent", x = 140, y = 40 },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = false,
      },
      health = {
        texture = (ns.mediapath.."statusbar128_3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (ns.mediapath.."statusbar128_3"),
      },
      portrait = {
        show = true,
        use3D = true,
      },
    },

    --PARTY
    party = {
	  vertical = true,
      show = true,
      alpha = {
        notinrange = 0.5,
      },
      scale = 1.1,
	  vertwidth = 228,
      vertheight = 64,
	  width = 128,
      height = 64,
      pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = -335, y = 150 },
      aurawatch = {
        show            = true,
        size            = 18,
        pos = { a1 = "LEFT", x = 55, y = 8 },
        count = 7,
        onlyShowPresent = true,
        alpha = 0.75,
        spellIds = {
            PRIEST = {139, 17, 77489, 41635},
            PALADIN = {223306, 53563, 6940, 287280, 156910, 200025},
            SHAMAN = {61295},
            MONK = {119611, 124682},
            DRUID = {33763, 774, 8936, 102342, 48438, 155777},
	    EVOKER = {364343, 366155, 357170},
            ALL = {1},
        },
      },
      auras = {
        show = true,
        size = 12,
        onlyShowPlayerDebuffs = false,
        showDebuffType = true,
        showBuffs = false,
        onlyShowPlayerBuffs = true,
	showBuffType = true,
	number = 5,
	disableCooldownText = false,
	disableCooldown = false,
	onlyDispellable = true,
	whitelist = {},
	blacklist = {},
      },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
		fontSize = 11,
		textPos = "RIGHT",
		x = -20,
		y = 0,
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
	  fontSize = 14,
      portrait = {
        show = false,
        use3D = true,
		width = 85,
      },
      attributes = {
        visibility          = "custom [nogroup:party,nogroup:raid] show; [group:party,nogroup:raid] show; [group:raid] hide; show",  --show this header in party
        showPlayer          = true,     --make this true to show player in party
        showSolo            = true,    --make this true to show while solo (only works if solo is in visiblity aswell
        showParty           = true,    --make this true to show headerin party
        showRaid            = false,    --show in raid
	hideInArena         = false,     --hides the party frame while inside an arena
	VerticalAnchor       = "TOP",
	HorizontalAnchor     = "LEFT",
		
      },
      healprediction = {
        show = true,
        texture = (ns.mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.25,
      },
      totalabsorb = {
        show = true,
        texture = (ns.mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --RAID
    raid = {
      show = true,
      special = {
        chains = false, --should the raidframe include the chain textures?
      },
      alpha = {
        notinrange = 0.4,
      },
      scale = 1.3,
      pos = { a1 = "TOPLEFT", a2 = "TOPLEFT", af = "UIParent", x = 5, y = -5 },
      groupPos = {},
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:misshp]",   --tag for the second line
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
      },
      aurawatch = {
        show            = true,
        size            = 12,
        pos = { a1 = "CENTER", x = -30, y = 12.5 },
        count = 7,
        onlyShowPresent = true,
        alpha = 0.75,
        spellIds = {
            PRIEST = {139, 17, 77489, 41635},
            PALADIN = {223306, 53563, 6940, 287280, 156910, 200025},
            SHAMAN = {61295},
            MONK = {119611, 124682},
            DRUID = {33763, 774, 8936, 102342, 48438, 155777},
            ALL = {1},
        },
      },
      auras = {
        --put every single spellid here that you want to be tracked, be it buff or debuff doesn't matter
        whitelist = {
			223306, -- Bestow Faith
			53563, -- Beacon of Light
			6940, -- Blessing of Sacrifice
			287280, -- Glimmer of Light
			156910, -- Beacon of Faith
			200025, -- Beacon of Virtue
			313255, -- Slow
			774, -- Rejuv
			155777, -- germination
			8936, --regrowth
			33763, --lifebloom
			48438, -- wild growth
			335305, -- Barbed Shackles
        },
		blacklist = {
			--these are abilities that should definetly not be shown
			164545,
			164547,
			54149,
			},
        showBuffs       = false,
	showDebuffs     = true,
        disableCooldown = false,
	disableCooldownText = true,
        showBuffType    = true,
        onlyShowPlayer  = false,
        showDebuffType  = true,
	useCustomFilter = true,
        size            = 13,
        num             = 5,
        spacing         = 3,
		debuffPos = { a1 = "CENTER", x = 0, y = -23},
		buffPos = {a1 = "CENTER", x = 33, y = 0},
      },
      attributes = {
        visibility          = "custom [nogroup:party,nogroup:raid] show; [group:party] hide; [group:raid] show; hide",  --show this
        showPlayer          = true,  --make this true to show player in party
        showSolo            = false,  --make this true to show while solo (only works if solo is in visiblity aswell
        showParty           = false,  --make this true to show raid in party
        showRaid            = true,  --show in raid
        showInArena         = false, --shows this frame while in an arena
        pos               = "TOP",
        yOffset             = 15,
        xoffset             = 0,
        maxColumns          = 4,
        unitsPerColumn      = 10,
        columnSpacing       = -20,
        columnAnchorpos   = "LEFT",
      },
      healprediction = {
        show = false,
        texture = (ns.mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.05,
      },
      totalabsorb = {
        show = true,
        texture = (ns.mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --BOSSFRAMES
    boss = {
      show = true,
      scale = 1,
	  width = 128,
      height = 64,
      pos = { a1 = "TOP", a2 = "BOTTOM", af = "Minimap", x = 0, y = -80 },
      health = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:bosshp]%",
      },
      power = {
        texture = (ns.mediapath.."statusbar3"),
        tag = "[diablo:bosspp]",
      },
    },
}

---------------------------------------------
-- Populate defaults.profile.bars from original cfg.bars
---------------------------------------------
Roth_UI.defaults.profile.bars = {
    
    --General Button Settings
	showMacroName = true,
	showCooldown = true,
	showHotkey = false,
	showStackCount = true,
    --BAR 1
    bar1 = {
      enable          = true, --enable module
      uselayout2x6    = false,
      scale           = 1,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -1, y = 16 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --OVERRIDE BAR (vehicle ui)
    overridebar = { --the new vehicle and override bar
      enable          = true, --enable module
      scale           = 1,
      padding         = 2, --frame padding
      buttons         = {
        size            = 57,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -1, y = 16 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAR 2
    bar2 = {
      enable          = true, --enable module
      uselayout2x6    = false,
      scale           = 1,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -1, y = 42 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAR 3
    bar3 = {
      enable          = true, --enable module
      scale           = 1,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -1, y = 70 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAR 4
    bar4 = {
      enable          = true, --enable module
	  vert = false, --choosing this will make the bar stack vertically instead of horizontally
      combineBar4AndBar5  = true, --by choosing true both bar 4 and 5 will react to the same hover effect, thus true/false at the same time, settings for bar5 will be ignored
      scale           = 1.2,
      padding         = 10, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "RIGHT", a2 = "RIGHT", af = "UIParent", x = -0, y = 0 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAR 5
    bar5 = {
      enable          = true, --enable module
	  vert = true, --choosing this will make the bar stack vertically instead of horizontally
      scale           = 1.2,
      padding         = 10, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "RIGHT", a2 = "RIGHT", af = "UIParent", x = -36, y = 0 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 1},
      },
    },
    bar6 = {
      enable          = true, --enable module
	    vert            = false, --choosing this will make the bar stack vertically instead of horizontally
      scale           = 1.2,
      padding         = 10, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "RIGHT", a2 = "RIGHT", af = "UIParent", x = -36, y = 0 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --PETBAR
    petbar = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = 1.2,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -1, y = 180 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --STANCE- + POSSESSBAR
    stancebar = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = 0.6,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
	  pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 135, y = 172  },
	  userplaced      = {
		  enable          = true,
	  },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --EXTRABAR
    extrabar = {
      enable          = true, --enable module
      scale           = 0.82,
      padding         = 10, --frame padding
      buttons         = {
        size            = 36,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -210, y = 220 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
    },
    --VEHICLE EXIT (no vehicleui)
    leave_vehicle = {
      enable          = true, --enable module
      scale           = 1.2,
      padding         = 10, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 210, y = 135 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
    },
    --MICROMENU
    micromenu = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = 0.6,
      padding         = 0, --frame padding
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -155, y = 159 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = true,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAGS
    bags = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = .5,
      padding         = 15, --frame padding
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 365, y = 207 },
      userplaced      = {
        enable          = true,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
  }


  -- Create a proxy table for cfg
ns.cfg = {}
setmetatable(ns.cfg, {
    __index = function(_, key)
        -- Before DB init, pull from defaults
        if ns.db and ns.db.profile then
            return ns.db.profile[key]
        else
            return Roth_UI.defaults.profile[key]
        end
    end,
    __newindex = function(_, key, value)
        if ns.db and ns.db.profile then
            ns.db.profile[key] = value
        else
            Roth_UI.profile[key] = value
        end
    end
})

-- These hold pending options until LoadConfig() is called
local options = {
    type = "group",
    name = "Roth UI",
    args = {}
}

local order = 1

local migrations = {}
local function getNodeAndKey(root, path)
  local node = root
  local parts = { strsplit(".", path) }
  for i = 1, #parts-1 do
    local p = parts[i]
    node[p] = node[p] or {}
    node = node[p]
  end
  return node, parts[#parts]
end

local function migrateTable(db, migrationMap)
  for oldPath, newPath in pairs(migrationMap) do
    local oldParent, oldKey = getNodeAndKey(db, oldPath)
    local val = oldParent and oldParent[oldKey]
    if val ~= nil then
      local newParent, newKey = getNodeAndKey(db, newPath)
      if newParent then
        -- don’t overwrite if user already has new key
        if newParent[newKey] == nil then
          newParent[newKey] = val
        end
        oldParent[oldKey] = nil
      end
    end
  end
end

local function getNodeAtPath(root, path)
    local node = root
    for part in string.gmatch(path, "[^.]+") do
        node = node and node[part]
    end
    return node
end

local function makeGetter(path)
    return function()
        local node = Roth_UI.db.profile
        for part in string.gmatch(path, "[^.]+") do
            if not node then return nil end
            node = node[part]
        end
        return node
    end
end

local function makeSetter(path, afterSet)
    return function(_, value)
        local parts = {}
        for part in string.gmatch(path, "[^.]+") do
            table.insert(parts, part)
        end

        local node = Roth_UI.db.profile
        for i = 1, #parts - 1 do
            local key = parts[i]
            node[key] = node[key] or {}  -- ensure subtable exists
            node = node[key]
        end

        node[parts[#parts]] = value
        if afterSet then afterSet(value) end
    end
end

local function humanizeKey(key)
    -- Special case for bare "color"
    if key:lower() == "color" then
        return "Color"
    end

    -- Insert spaces before capitals: "selectedTabColor" → "selected Tab Color"
    local spaced = key:gsub("([a-z])([A-Z])", "%1 %2")

    -- Capitalize first letter of each word
    local words = {}
    for w in spaced:gmatch("%S+") do
        table.insert(words, w:sub(1,1):upper() .. w:sub(2))
    end
    return table.concat(words, " ")
end


Roth_UI.configPresets = {
    toggle = function(path, afterSet, keyName, needsReload)
        return {
            type  = "toggle",
            order = 1,
            name  = humanizeKey(keyName),
            get   = makeGetter(path),
            set   = function(_,val)
                makeSetter(path, afterSet)(nil, val) if needsReload and not val then Roth_UI:TriggerReload() end
            end
        }
    end,

    range = function(path, afterSet, keyName, min, max, step)
        return {
            type  = "range",
            order = 2,
            name  = humanizeKey(keyName),
            min   = min or 1,
            max   = max or 2000,
            step  = step or 1,
            get   = makeGetter(path),
            set   = makeSetter(path, afterSet),
        }
    end,

    color = function(path, afterSet, keyName)
        return {
            type = "color",
            order = 10,
            name = humanizeKey(keyName or "color"),
            hasAlpha = true,
            get = function()
                local t = makeGetter(path)()
                if type(t) == "table" then
                    if t[1] then
                        -- array-style {1,0,1,0.5}
                        return t[1], t[2], t[3], t[4] or 1
                    elseif t.r then
                        -- keyed-style {r=,g=,b=,a=}
                        return t.r, t.g, t.b, t.a or 1
                    end
                end
                return 1, 1, 1, 1
            end,
            set = function(_, r, g, b, a)
                local t = makeGetter(path)()
                if type(t) == "table" then
                    if t[1] then
                        -- preserve array style
                        makeSetter(path, afterSet)(nil, {r,g,b,a})
                    elseif t.r then
                        -- preserve keyed style
                        makeSetter(path, afterSet)(nil, {r=r, g=g, b=b, a=a})
                    else
                        -- default to array
                        makeSetter(path, afterSet)(nil, {r,g,b,a})
                    end
                else
                    -- nothing existed, default to array
                    makeSetter(path, afterSet)(nil, {r,g,b,a})
                end
            end,
        }
    end,
    
    pos = function(path, afterSet, keyName)
        return {
            type = "group",
            order = 4,
            name = (keyName and keyName:lower() == "pos") and "Position" or humanizeKey(keyName),
            inline = true,
            args = {
                a1 = {
                    type = "select", order = 1, name = "Anchor",
                    values = {
                        TOP = "Top", BOTTOM = "Bottom", LEFT = "Left", RIGHT = "Right",
                        CENTER = "Center",
                        TOPLEFT = "Top Left", TOPRIGHT = "Top Right",
                        BOTTOMLEFT = "Bottom Left", BOTTOMRIGHT = "Bottom Right",
                    },
                    get = makeGetter(path..".a1"),
                    set = makeSetter(path..".a1", afterSet),
                },
                x = {
                    type = "range", order = 2, name = "X Offset",
                    min = -2000, max = 2000, step = 1,
                    get = makeGetter(path..".x"),
                    set = makeSetter(path..".x", afterSet),
                },
                y = {
                    type = "range", order = 3, name = "Y Offset",
                    min = -2000, max = 2000, step = 1,
                    get = makeGetter(path..".y"),
                    set = makeSetter(path..".y", afterSet),
                },
            },
        }
    end,
    
    input = function(path, afterSet, keyName)
        return {
            type = "input",
            order = 5,
            name = humanizeKey(keyName),
            get = makeGetter(path),
            set = makeSetter(path, afterSet),
        }
    end,
    
    texture = function(path, afterSet, keyName, mediaType)
        mediaType = mediaType or "statusbar" -- fallback
        return {
            type = "select",
            dialogControl = "LSM30_"..(mediaType == "background" and "Background" or "Statusbar"),
            name = keyName,
            values = LSM:HashTable(mediaType),  -- available textures
            get = function()
                local key = makeGetter(path)()
                -- Ensure we always return the key, not the file path
                return key
            end,
            set = function(_, v)
                makeSetter(path, afterSet)(nil, v)
            end,
        }
    end,
}

local function generateOptions(path, defaultsNode, opts, afterSet, needsReload)
    for k, v in pairs(defaultsNode) do
        if not opts[k] then
            local fullPath = path .. "." .. k
            local prettyName = (k:lower() == "pos" and "Position") or humanizeKey(k)
            local lower = k:lower()

            if type(v) == "boolean" then
                opts[k] = Roth_UI.configPresets.toggle(fullPath, afterSet, k, needsReload)
                opts[k].name = prettyName

            elseif type(v) == "number" then
                -- number heuristics
                local min, max, step
                if lower:find("alpha") then
                    min, max, step = 0, 1, 0.01
                elseif lower:find("scale") then
                    min, max, step = 0.25, 2.5, 0.01
		elseif lower:find("size") then
		    min, max, step = 0.25, 200, 0.01
                elseif lower:find("fontsize") then
                    min, max, step = 6, 64, 1
                elseif lower:find("width") or lower:find("height") then
                    min, max, step = 10, 1000, 1
                else
                    min, max, step = 1, 100, 1
                end
                opts[k] = Roth_UI.configPresets.range(fullPath, afterSet, k, min, max, step)
                opts[k].name = prettyName

            elseif type(v) == "string" and LSM:Fetch("statusbar", v, true) then
                opts[k] = Roth_UI.configPresets.texture(fullPath, afterSet, prettyName, "statusbar")
            
            elseif type(v) == "string" and LSM:Fetch("background", v, true) then
                opts[k] = Roth_UI.configPresets.texture(fullPath, afterSet, prettyName, "background")
                
            elseif type(v) == "string" then
                opts[k] = Roth_UI.configPresets.input(fullPath, afterSet, k)
                opts[k].name = prettyName

            elseif type(v) == "table" then
                if (k == "whitelist" or k == "blacklist") and type(v[1]) == "number" then
                        opts[k] = {
                            type = "input",
                            name = prettyName,
                            desc = "Comma-separated SpellIDs",
                            get = function()
                                return table.concat(v, ", ")
                            end,
                            set = function(_, val)
                                local t = {}
                                for id in val:gmatch("%d+") do
                                    table.insert(t, tonumber(id))
                                end
                                fullPath[#fullPath][k] = t  -- replace value in config
                                afterSet()
                            end,
                        }
                        
                elseif type(v[1]) == "number" and not (v.r and v.g and v.b) then
                    -- SpellID array → make comma-separated input
                    opts[k] = {
                        type = "input",
                        name = prettyName,
                        desc = "Comma-separated SpellIDs",
                        get = function()
                            return table.concat(v, ", ")
                        end,
                        set = function(_, val)
                            local t = {}
                            for id in val:gmatch("%d+") do
                                table.insert(t, tonumber(id))
                            end
                            makeSetter(fullPath, afterSet)(nil, t)
                        end,
                    }
                elseif v.r and v.g and v.b then
                    -- Color table
                    opts[k] = Roth_UI.configPresets.color(fullPath, afterSet, k)
                    opts[k].name = prettyName

                elseif v.a1 and (v.x or v.y) then
                    opts[k] = Roth_UI.configPresets.pos(fullPath, afterSet, k)
                    opts[k].name = prettyName

                else
                    -- nested subgroup
                    opts[k] = {
                        type = "group",
                        name = prettyName,
                        inline = false,
                        args = {},
                    }
                    generateOptions(fullPath, v, opts[k].args, afterSet)
                end
            end
        end
    end
end


local topLevelKeys = {
    fonts = true,
    profile = true,
    caevs = true,
    stateStrip = true,
}

function Roth_UI:AddConfig(path, opts, name, initFunc, needsReload)

    if not options then
        options = {
            type = "group",
            name = "Roth UI",
            args = {},
        }
    end
    
    if not self.db then
        -- Queue until LoadConfig runs
        self._pendingConfigs = self._pendingConfigs or {}
        table.insert(self._pendingConfigs, {path=path, opts=opts, name=name, initFunc=initFunc})
        return
    end
    
    local parts = {}
    for part in string.gmatch(path, "[^.]+") do
        table.insert(parts, part)
    end

    local parentKey = parts[1]
    local parentName = humanizeKey(parentKey)

    local parent = options.args
    if not topLevelKeys[parentKey] then
        -- make sure parent group exists
        if not parent[parentKey] then
            parent[parentKey] = {
                type = "group",
                name = parentName,
                args = {},
            }
        end
        parent = parent[parentKey].args
    end

    -- childKey is always the full path string
    local childKey = table.concat(parts, ".")
    parent[childKey] = {
        type = "group",
        name = name or humanizeKey(parts[#parts]),
        args = opts,
    }
    
    -- Look into defaults to auto-generate
    local defaultsNode = getNodeAtPath(self.defaults.profile, path)
    if defaultsNode and type(defaultsNode) == "table" then
        generateOptions(path, defaultsNode, opts, initFunc, needsReload)
    end
end

local mediaFiles = {
    statusbar = {
        
    },
    background = {
        
    },
    border = {
        
    }
}

function Roth_UI:LoadConfig()
    -- Create DB
    ns.db = LibStub("AceDB-3.0"):New("Roth_UI_DB", Roth_UI.defaults, true)
    ns.CAEVSConfig.Init()
    ns.db:RegisterDefaults(ns.defaults)
    
    if migrations and next(migrations) then
        migrateTable(ns.db.profile, migrations)
    end
    
    -- Profile change callback
    ns.db.RegisterCallback(ns, "OnProfileChanged", function() ReloadUI() end)

    -- Add profile management to options
    options.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(ns.db)

    -- Register options with AceConfig
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Roth_UI", options, {"roth_ui", "rothconfig"})
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Roth_UI", "Roth UI")

    -- Flush queued children
    if self._pendingConfigs then
        for _, c in ipairs(self._pendingConfigs) do
            self:AddConfig(c.path, c.opts, c.name, c.initFunc)
        end
        self._pendingConfigs = nil
    end
    
    Roth_UI.db.RegisterCallback(Roth_UI, "OnProfileChanged", function()
        Roth_UI:TriggerReload()
    end)
    
    Roth_UI.db.RegisterCallback(Roth_UI, "OnProfileCopied", function()
        Roth_UI:TriggerReload()
    end)
    
    Roth_UI.db.RegisterCallback(Roth_UI, "OnProfileReset", function()
        Roth_UI:TriggerReload()
    end)
    -- Reset order counter in case of reload
    order = 1
    ns:Init()
end

StaticPopupDialogs["ROTHUI_RELOAD"] = {
        text = "Profile change detected. A reload is required to apply changes.",
        button1 = "Reload UI",
        button2 = "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
}

function Roth_UI:TriggerReload()
    StaticPopup_Show("ROTHUI_RELOAD")
end

--========================================
-- Call LoadConfig after ADDON_LOADED
--========================================
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
    if name == addonName then
        ns:LoadConfig()
    end
end)