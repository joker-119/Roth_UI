
  ---------------------------------------------
  --  Roth UI
  ---------------------------------------------

  --  A Diablo themed unitframe layout for oUF 1.6.x
  --  Galaxy - 2016
  --  Version 1.9.15a
  ---------------------------------------------

  --get the addon namespace
  local addon, ns = ...
  local addonName, Roth_UI = ...
  local oUF = ns.oUF
  mediapath = "Interface\\AddOns\\Roth_UI\\media\\"

  --object container
  local cfg = {}
  ns.cfg = cfg
  local locale = GetLocale()
  ---------------------------------------------
  -- // CONFIG // --
  ---------------------------------------------

  ---------------------------------------------
  -- // Embeds // --
  ---------------------------------------------
  cfg.embeds = {
	rChat = true, -- Simple chat frame
	rActionBarStyler = true, -- Simple actionbar styler for Roth UI
	rButtonTemplate = true, -- Simple button skinning mod
	rMinimap = true, -- Simplistic square minimap
	rNamePlates = true, -- Diablo style Nameplates
	rInfoStrings = true, -- Information text displayed under Minimap
	rRaidManager = true, -- Replacement for blizzard's pull-out raid manager
	rTooltip = true, -- Diablo styled tooltips
	tullaRange = true, -- Creates Red/Blue overlay over icons that are not useable due to range or lack of resources
	Roth_ShinyBuffs = true, -- ShinyBuffs buff frame, edited for use with Roth UI
	rObjectiveTracker = true, -- Simple drag and resizeable Objective Tracker frame
	RothFont = true, -- makes game client use a font (as defined in config file) for all game text
  }
  ----------------------------------------
  -- colorswitcher define your color for healthbars here
  ----------------------------------------

  --color is in RGB (red (r), green (g), blue (b), alpha (a)), values are from 0 (dark color) to 1 (bright color). 1,1,1 = white / 0,0,0 = black / 1,0,0 = red etc
  cfg.colorswitcher = {
    bright              = { r = 1, g = 0, b = 0, a = 1, },          -- the bright color
    dark                = { r = 1, g = 0, b = 0, a = 0.1, },   -- the dark color
    classcolored        = true,  -- true   -> override the bright color with the unit specific color (class, faction, happiness, threat), if false uses the predefined color
    useBrightForeground = true,  -- true   -> use bright color in foreground and dark color in background
                                 -- false  -> use dark color in foreground and bright color in background
    threatColored       = true,  -- true/false -> enable threat coloring of the health plate for raidframes
  }

  --frames have a new highlight that fades on hp loss, if that is still not enough you can adjust a multiplier here
  cfg.highlightMultiplier = 0 --range 0-1

  ----------------------------------------
  --units
  ----------------------------------------

  cfg.units = {
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
        show = false,
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
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
		    TextSize = 11,
        hideDefault = true, --if you hide the Roth_UI castbar, should the Blizzard castbar be shown?
        latency = true,
        texture = (mediapath.."statusbar3"),
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
        show = false,
        scale = 0.5,
        color = {r = 1, g = 0, b = 1, },
        texture = (mediapath.."statusbar"),
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 0, y = 0 },
      },
      expbar = { --experience
        show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 9 },
          texture = (mediapath.."statusbar2"),
          scale = 1,
          color = {r = 0.8, g = 0, b = 0.8, },
          rested = {
            color = {r = 1, g = 0.7, b = 0, },
          },
      },
      repbar = { --reputation
        show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 20 },
          texture = (mediapath.."statusbar2"),
          scale = 1,
      },
	    ArtifactPower = {
		    show = true,
			  pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 15 },
			  texture = (mediapath.."statusbar2"),
			  scale = 1,
	    },
      art = {
        actionbarbackground = {
          show = true,
          pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 0 },
          scale = 1,
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
      pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = 0, y = -100 },
      health = {
	frequentUpdates = true,
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:hpval]",
		fontSize = 7,
		point = "RIGHT",
		x = 25,
		y = -30,
      },
	  healper = {
	frequentUpdates = true,
		tag = "[perphp]",
		fontSize = 10,
		point = "CENTER",
		x = 0,
		y = 0,
	  },
	  powper = {
	frequentUpdates = true,
		tag = "[perpp]%",
		fontSize = 7,
		point = "CENTER",
		x = 0,
		y = 0,
	  },
      power = {
	frequentUpdates = true,
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:ppval]",
		fontSize = 7,
		point = "LEFT",
		x = -25,
		y = -30,
      },
	  misc = {
		classFontSize = 13,
		NameFontSize = 16,
	  },
      auras = {
        show = true,
        size = 15,
        onlyShowPlayerBuffs = false,
        showStealableBuffs = true,
        onlyShowPlayerDebuffs = false,
        showDebuffType = true,
        desaturateDebuffs = false,
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
		TextSize = 11,
        texture = (mediapath.."statusbar3"),
        scale = 1/1.9, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 0, g = 0.5, b = 1, a = .7, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 1, },
          shieldbar = { r = 0.5, g = 0.5, b = 0.5, a = 1, }, --the castbar color while target casting a shielded spell
          shieldbg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },  --the castbar background color while target casting a shielded spell
        },
        pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = 0, y = -155 },
      },
      portrait = {
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 100, y = 0 },
        size = 150,
        show = false,
        use3D = true,
      },
      healprediction = {
        show = true,
        texture = (mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
      totalabsorb = {
        show = true,
        texture = (mediapath.."absorb_statusbar_overlay"),
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
      pos = { a1 = "TOP", a2 = "TOP", af = "UIParent", x = -238, y = -115 },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = false,
      },
      health = {
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (mediapath.."statusbar3"),
      },
      healprediction = {
        show = true,
        texture = (mediapath.."statusbar3"),
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
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (mediapath.."statusbar3"),
      },
      altpower = {
        show = false,
        scale = 0.5,
        color = {r = 1, g = 0, b = 1, },
        texture = (mediapath.."statusbar3"),
        pos = { a1 = "CENTER", a2 = "CENTER", af = "UIParent", x = 0, y = 0 },
      },
      portrait = {
        show = true,
        use3D = true,
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
        texture = (mediapath.."absorb_statusbar_overlay"),
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
      pos = { a1 = "RIGHT", a2 = "RIGHT", af = "UIParent", x = -30, y = 40 },
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
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (mediapath.."statusbar3"),
      },
      portrait = {
        show = true,
        use3D = true,
      },
      castbar = {
        show = false,
		TextSize = 11,
        texture = (mediapath.."statusbar3"),
        scale = 1/1.9, --divide 1 by current unit scale if you want to prevent scaling of the castbar based on unit scale
        color = {
          bar = { r = 1, g = 0.7, b = 0, a = 1, },
          bg = { r = 0.1, g = 0.1, b = 0.1, a = 0.7, },
        },
        pos = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 0, y = 420 },
      },
      healprediction = {
        show = true,
        texture = (mediapath.."statusbar128_3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
      totalabsorb = {
        show = true,
        texture = (mediapath.."absorb_statusbar_overlay"),
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
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (mediapath.."statusbar3"),
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
        texture = (mediapath.."statusbar128_3"),
        tag = "[diablo:misshp]",
      },
      power = {
        texture = (mediapath.."statusbar128_3"),
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
      pos = { a1 = "TOPLEFT", a2 = "TOPLEFT", af = "UIParent", x = 35, y = -40 },
      aurawatch = {
        show            = false,
        size            = 18,
      },
      auras = {
        show = true,
        size = 22,
        onlyShowPlayerDebuffs = false,
        showDebuffType = true,
        showBuffs = true,
        onlyShowPlayerBuffs = true,
		showBuffType = true,
		number = 12,
      },
      health = {
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",
		fontSize = 11,
		point = "RIGHT",
		x = -20,
		y = 0,
      },
      power = {
        texture = (mediapath.."statusbar3"),
      },
	  misc = {
		NameFontSize = 14
	  },
      portrait = {
        show = true,
        use3D = true,
		width = 100,
      },
      attributes = {
        visibility          = "custom [group:party,nogroup:raid] show;hide",  --show this header in party
        showPlayer          = true,     --make this true to show player in party
        showSolo            = false,    --make this true to show while solo (only works if solo is in visiblity aswell
        showParty           = true,     --make this true to show headerin party
        showRaid            = false,    --show in raid
      },
      healprediction = {
        show = true,
        texture = (mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.00,
      },
      totalabsorb = {
        show = true,
        texture = (mediapath.."absorb_statusbar_overlay"),
        color = {
          bar  = {r = 0.7, g = 1, b = 1, a = 0.9 },
        },
      },
    },

    --RAID
    raid = {
      show = true,
	  width = 128,
      height = 64,
      special = {
        chains = false, --should the raidframe include the chain textures?
      },
      alpha = {
        notinrange = 0.4,
      },
      scale = 1.2,
      pos = { a1 = "TOPLEFT", a2 = "TOPLEFT", af = "UIParent", x = 5, y = -5 },
      health = {
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:misshp]",   --tag for the second line
      },
      power = {
        texture = (mediapath.."statusbar3"),
      },
      aurawatch = {
        show            = true,
      },
      auras = {
        --put every single spellid here that you want to be tracked, be it buff or debuff doesn't matter
        --maximum number of icons displayed at a time = 1
        --this is for important boss mechanics only, this is not for tracking healing HOTs etc
        whitelist = {
          --test
          --6673,--test1, battle shout
          --72968,--test2
          --93805,--test3
          32407,
          --CATACLYSM RAIDS
          86622,
          --maloriak
          92980, --ice bomb
          77786, --red phase consuming flames
          --chimaeron
          89084 , --skull icon chimaeron <10k life
        },
        show            = false,
        disableCooldown = true,
        showBuffType    = false,
        showDebuffType  = false,
        size            = 12,
        num             = 5,
        spacing         = 3,
        pos = { a1 = "CENTER", x = 0, y = -9},
      },
      attributes = {
        visibility          = "custom [group:raid] show; hide",
        showPlayer          = true,  --make this true to show player in party
        showSolo            = true,  --make this true to show while solo (only works if solo is in visiblity aswell
        showParty           = true,  --make this true to show raid in party
        showRaid            = true,   --show in raid
        point               = "TOP",
        yOffset             = 15,
        xoffset             = 0,
        maxColumns          = 4,
        unitsPerColumn      = 10,
        columnSpacing       = -20,
        columnAnchorPoint   = "LEFT",
      },
      healprediction = {
        show = false,
        texture = (mediapath.."statusbar3"),
        color = {
          myself  = {r = 0, g = 1, b = 0, a = 1 },
          other   = {r = 0, g = 1, b = 0, a = 0.7 },
        },
        maxoverflow = 1.05,
      },
      totalabsorb = {
        show = true,
        texture = (mediapath.."absorb_statusbar_overlay"),
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
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:bosshp]%",
      },
      power = {
        texture = (mediapath.."statusbar3"),
        tag = "[diablo:bosspp]",
      },
    },

  }

  ----------------------------------------
  -- Action Bars
  ----------------------------------------
    cfg.bars = {
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
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
        fadeOut         = {time = 0.3, alpha = 0.4},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
      },
    },
    --STANCE- + POSSESSBAR
    stancebar = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = 0.78,
      padding         = 2, --frame padding
      buttons         = {
        size            = 26,
        margin          = 5,
      },
	  pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 60, y = -4  },
	  userplaced      = {
		enable        = true,
	  },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.4},
      },
      combat          = { --fade the bar in/out in combat/out of combat
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0.2},
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
      scale           = 0.7,
      padding         = 10, --frame padding
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = -120, y = 130 },
      userplaced      = {
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
    --BAGS
    bags = {
      enable          = true, --enable module
      show            = true, --true/false
      scale           = .7,
      padding         = 15, --frame padding
      pos             = { a1 = "BOTTOM", a2 = "BOTTOM", af = "UIParent", x = 190, y = 131 },
      userplaced      = {
        enable          = false,
      },
      mouseover       = {
        enable          = false,
        fadeIn          = {time = 0.4, alpha = 1},
        fadeOut         = {time = 0.3, alpha = 0},
      },
    },
  }

----------------------------------------
-- frame movement
----------------------------------------

--setting this to false will use the default frame positions, true allows moving
cfg.framesUserplaced = true

--setting this to true will lock the frames in place, false unlocks them
cfg.framesLocked = true

----------------------------------------
-- player specific data
----------------------------------------

--player stuff
cfg.playername  = UnitName("player")
cfg.playerclass = select(2,UnitClass("player"))
cfg.playercolor = RAID_CLASS_COLORS[cfg.playerclass]
cfg.playerspec = GetSpecialization()

----------------------------------------
-- Embeds
----------------------------------------
--rTooltip
cfg.rtooltip = {
	scale = 1.15,
	pos = { "BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 100 },
	cursorfocus = false,
}

--rObjectiveTracker
cfg.tracker = {
	scale = 1,
	point = { "TOPRIGHT", -190, -200},
	size = { 260, 450 },
}
   --rInfostrings
cfg.frame = {
	scale           = 0.95,
	pos             = { a1 = "TOP", af = Minimap, a2 = "BOTTOM", x = 0, y = -25 },
	userplaced      = true, --want to place the bar somewhere else?
}

cfg.showXpRep     = true --show xp or reputation as string
cfg.showMail      = false --show mail as text

--rChat
cfg.hideChatTabBackgrounds  = true
cfg.selectedTabColor        = {1,0.75,0}
cfg.selectedTabAlpha        = 1
cfg.notSelectedTabColor     = {0.5,0.5,0.5}
cfg.notSelectedTabAlpha     = 0.3

--rMinimap
cfg.minimap = {
	scale = 1,
	point = {"TOPRIGHT", 0, -18},
}


  ----------------------------------------
  -- other
  ----------------------------------------

cfg.powercolors = PowerBarColor
cfg.powercolors["MANA"] = { r = 0, g = 0.4, b = 1 }
--fix the oUF mana color
oUF.colors.power["MANA"] = {0, 0.4, 1}

--font
if locale == "enUS" or locale == "enGB" then
	cfg.font = (mediapath.."Cracked-Narrow.ttf")
	cfg.chat = {
		font = (mediapath.."Cracked-Narrow.ttf"),
	}
else
	cfg.font = STANDARD_TEXT_FONT
	cfg.chat = {
		font = STANDARD_TEXT_FONT,
	}
end

--backdrop
cfg.backdrop = {
	bgFile = (mediapath.."Tooltip_Background"),
	edgeFile = (mediapath.."Tooltip_Border"),
	tile = true,
	tileSize = 16,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
