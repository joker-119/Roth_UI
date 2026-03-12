-- Roth_UI/config/state_strip.lua
local addon, ns = ...

local function SSDB()
  local p = ns.db and ns.db.profile
  return p and (p.stateStrip or (p.embeds and p.embeds.stateStrip))
end

local function GetSS()
  return ns.StateStrip
end

local function Update()
  local SS = GetSS()
  if SS and SS.RequestUpdate then SS.RequestUpdate() end
end

local function AuraLabel(k)
  local n = tonumber(k)
  if n and GetSpellInfo then
    local name = GetSpellInfo(n)
    if name then return name .. " (" .. k .. ")" end
  end
  return tostring(k)
end

local function BuildAuraValues(bucket)
  local db = SSDB()
  local t = db and db.track and db.track[bucket]
  local vals = {}
  if not t then return vals end
  for k in pairs(t) do
    vals[k] = AuraLabel(k)
  end
  return vals
end

local function EnsureSelection(db, bucket)
  db._sel = db._sel or {}
  local t = db.track and db.track[bucket]
  if not t then return nil end

  if db._sel[bucket] and t[db._sel[bucket]] then
    return db._sel[bucket]
  end

  for k in pairs(t) do
    db._sel[bucket] = k
    return k
  end

  db._sel[bucket] = nil
  return nil
end

local opts = {
  _header = { type="header", name="State Strip", order=0 },

  testing = {
    type = "group",
    name = "Testing",
    inline = true,
    order = 1,
    args = {
      testAll = {
        type = "execute",
        name = "Test: All (auto clears)",
        order = 1,
        func = function()
          local SS = GetSS()
          if SS and SS.SetTestMode then SS.SetTestMode("all") end
        end,
      },
      testClear = {
        type = "execute",
        name = "Test: Clear",
        order = 2,
        func = function()
          local SS = GetSS()
          if SS and SS.SetTestMode then SS.SetTestMode("clear") end
        end,
      },
      refresh = {
        type = "execute",
        name = "Refresh Strip",
        order = 3,
        func = Update,
      },
    },
  },

  signals = {
    type = "group",
    name = "Signals",
    order = 2,
    inline = true,
    args = {
      missingGrace = {
        type="range",
        name="Missing-buff grace (sec)",
        desc="Suppress missing tracked-buff alerts for a few seconds after zoning/loading.",
        order=1, min=0, max=30, step=1,
        get=function()
          local db=SSDB(); return db and (db.missingGraceSeconds or 0) or 0
        end,
        set=function(_, v)
          local db=SSDB(); if not db then return end
          db.missingGraceSeconds = v
          Update()
        end,
      },

      debuffTypes = {
        type="toggle",
        name="Debuff type alerts (Magic/Curse/Poison/Disease)",
        order=2,
        get=function() local db=SSDB(); return db and db.signals and db.signals.debuffTypes end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.debuffTypes=v; Update() end,
      },

      durabilityLow = {
        type="toggle",
        name="Low durability",
        order=3,
        get=function() local db=SSDB(); return db and db.signals and db.signals.durabilityLow end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.durabilityLow=v; Update() end,
      },
      durabilityPct = {
        type="range",
        name="Durability threshold (%)",
        order=4, min=1, max=50, step=1,
        get=function() local db=SSDB(); return db and (db.durabilityPct or 20) or 20 end,
        set=function(_, v) local db=SSDB(); if not db then return end db.durabilityPct=v; Update() end,
      },

      weaponEnchant = {
        type="toggle",
        name="Missing weapon enchant",
        order=5,
        get=function() local db=SSDB(); return db and db.signals and db.signals.weaponEnchant end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.weaponEnchant=v; Update() end,
      },
      weaponEnchantOOC = {
        type="toggle",
        name="Weapon enchant: only out of combat",
        order=6,
        get=function() local db=SSDB(); return db and db.signals and db.signals.weaponEnchantOOCOnly end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.weaponEnchantOOCOnly=v; Update() end,
      },

      maxResource = {
        type="toggle",
        name="Max resource warning (non-mana)",
        desc="Warn when your primary non-mana resource is high (useful for Rage/Energy classes).",
        order=7,
        get=function() local db=SSDB(); return db and db.signals and db.signals.maxResource end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.maxResource=v; Update() end,
      },
      maxResourcePct = {
        type="range",
        name="Max resource threshold (%)",
        desc="Triggers at or above this percent. Range: 80–100.",
        order=8, min=80, max=100, step=1,
        get=function() local db=SSDB(); return db and (db.maxResourcePct or 90) or 90 end,
        set=function(_, v) local db=SSDB(); if not db then return end db.maxResourcePct=v; Update() end,
      },

      missingBuffs = {
        type="toggle",
        name="Missing tracked-buff alerts",
        desc="This only triggers for buffs you explicitly mark as 'Alert when missing' in Track → Buffs.",
        order=9,
        get=function() local db=SSDB(); return db and db.signals and db.signals.missingBuffs end,
        set=function(_, v) local db=SSDB(); if not db then return end db.signals.missingBuffs=v; Update() end,
      },
    },
  },

  debuffType = {
    type = "group",
    name = "Debuff Types",
    order = 3,
    inline = true,
    args = {
      magic   = { type="toggle", name="Magic",   order=1, get=function() local db=SSDB(); return db and db.debuffType and db.debuffType.magic end,   set=function(_,v) local db=SSDB(); if not db then return end db.debuffType.magic=v;   Update() end },
      curse   = { type="toggle", name="Curse",   order=2, get=function() local db=SSDB(); return db and db.debuffType and db.debuffType.curse end,   set=function(_,v) local db=SSDB(); if not db then return end db.debuffType.curse=v;   Update() end },
      poison  = { type="toggle", name="Poison",  order=3, get=function() local db=SSDB(); return db and db.debuffType and db.debuffType.poison end,  set=function(_,v) local db=SSDB(); if not db then return end db.debuffType.poison=v;  Update() end },
      disease = { type="toggle", name="Disease", order=4, get=function() local db=SSDB(); return db and db.debuffType and db.debuffType.disease end, set=function(_,v) local db=SSDB(); if not db then return end db.debuffType.disease=v; Update() end },
    },
  },

  track = {
    type = "group",
    name = "Track",
    order = 10,
    inline = false,
    args = {
      buffs = {
        type = "group",
        name = "Buffs",
        order = 1,
        inline = false,
        args = {
          add = {
            type="input",
            name="Add buff (spellID or name)",
            order=1,
            width="full",
            get=function() return "" end,
            set=function(_, v)
              if not v or v == "" then return end
              local SS = GetSS()
              if SS and SS.AddTracked then SS.AddTracked("buffs", v) end
            end,
          },

          select = {
            type="select",
            name="Buff",
            order=2,
            values=function() return BuildAuraValues("buffs") end,
            get=function()
              local db=SSDB(); if not db then return nil end
              return EnsureSelection(db, "buffs")
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              db._sel = db._sel or {}
              db._sel.buffs = v
            end,
          },

          enabled = {
            type="toggle",
            name="Enabled",
            order=3,
            get=function()
              local db=SSDB(); if not db then return false end
              local k=EnsureSelection(db,"buffs"); if not k then return false end
              local e=db.track.buffs[k]
              return e and e.enabled ~= false
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"buffs"); if not k then return end
              db.track.buffs[k].enabled = v
              Update()
            end,
          },

          alertMissing = {
            type="toggle",
            name="Alert when missing",
            desc="If enabled, the State Strip will show this buff when it is not active on you.",
            order=4,
            get=function()
              local db=SSDB(); if not db then return false end
              local k=EnsureSelection(db,"buffs"); if not k then return false end
              local e=db.track.buffs[k]
              return e and e.alertMissing == true
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"buffs"); if not k then return end
              db.track.buffs[k].alertMissing = v
              Update()
            end,
          },

          showFull = {
            type="toggle",
            name="Show for full duration",
            order=5,
            get=function()
              local db=SSDB(); if not db then return false end
              local k=EnsureSelection(db,"buffs"); if not k then return false end
              return db.track.buffs[k] and db.track.buffs[k].showFull == true
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"buffs"); if not k then return end
              db.track.buffs[k].showFull = v
              Update()
            end,
          },

          threshold = {
            type="range",
            name="Expiring threshold (sec)",
            desc="If Show for full duration is OFF: show when remaining <= threshold. 0 uses the global expiring threshold.",
            order=6,
            min=0, max=180, step=1,
            get=function()
              local db=SSDB(); if not db then return 0 end
              local k=EnsureSelection(db,"buffs"); if not k then return 0 end
              return tonumber(db.track.buffs[k] and db.track.buffs[k].threshold) or 0
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"buffs"); if not k then return end
              db.track.buffs[k].threshold = v
              Update()
            end,
          },

          remove = {
            type="execute",
            name="Remove selected buff",
            order=7,
            func=function()
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"buffs"); if not k then return end
              local SS = GetSS()
              if SS and SS.RemoveTracked then SS.RemoveTracked("buffs", k) end
              EnsureSelection(db, "buffs")
              Update()
            end,
          },
        },
      },

      debuffs = {
        type = "group",
        name = "Debuffs",
        order = 2,
        inline = false,
        args = {
          add = {
            type="input",
            name="Add debuff (spellID or name)",
            order=1,
            width="full",
            get=function() return "" end,
            set=function(_, v)
              if not v or v == "" then return end
              local SS = GetSS()
              if SS and SS.AddTracked then SS.AddTracked("debuffs", v) end
            end,
          },

          select = {
            type="select",
            name="Debuff",
            order=2,
            values=function() return BuildAuraValues("debuffs") end,
            get=function()
              local db=SSDB(); if not db then return nil end
              return EnsureSelection(db, "debuffs")
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              db._sel = db._sel or {}
              db._sel.debuffs = v
            end,
          },

          enabled = {
            type="toggle",
            name="Enabled",
            order=3,
            get=function()
              local db=SSDB(); if not db then return false end
              local k=EnsureSelection(db,"debuffs"); if not k then return false end
              local e=db.track.debuffs[k]
              return e and e.enabled ~= false
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"debuffs"); if not k then return end
              db.track.debuffs[k].enabled = v
              Update()
            end,
          },

          showAlways = {
            type="toggle",
            name="Show always",
            desc="If enabled, show this debuff for its full duration. If disabled, threshold > 0 can restrict it to expiring-soon.",
            order=4,
            get=function()
              local db=SSDB(); if not db then return false end
              local k=EnsureSelection(db,"debuffs"); if not k then return false end
              return db.track.debuffs[k] and db.track.debuffs[k].showFull == true
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"debuffs"); if not k then return end
              db.track.debuffs[k].showFull = v
              Update()
            end,
          },

          threshold = {
            type="range",
            name="Expiring threshold (sec)",
            desc="0 = default (usually always show). If > 0 and Show always is OFF: show when remaining <= threshold.",
            order=5,
            min=0, max=180, step=1,
            get=function()
              local db=SSDB(); if not db then return 0 end
              local k=EnsureSelection(db,"debuffs"); if not k then return 0 end
              return tonumber(db.track.debuffs[k] and db.track.debuffs[k].threshold) or 0
            end,
            set=function(_, v)
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"debuffs"); if not k then return end
              db.track.debuffs[k].threshold = v
              Update()
            end,
          },

          remove = {
            type="execute",
            name="Remove selected debuff",
            order=6,
            func=function()
              local db=SSDB(); if not db then return end
              local k=EnsureSelection(db,"debuffs"); if not k then return end
              local SS = GetSS()
              if SS and SS.RemoveTracked then SS.RemoveTracked("debuffs", k) end
              EnsureSelection(db, "debuffs")
              Update()
            end,
          },
        },
      },
    },
  },
}

ns:AddConfig("stateStrip", opts, "State Strip", Update, true)