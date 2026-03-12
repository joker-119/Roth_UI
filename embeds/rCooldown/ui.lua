-- Roth_UI/embeds/rCooldown/ui.lua
-- Config UI (AceConfig) for rCooldown using Roth_UI:AddConfig()
-- Includes per-entry condition builder (CAEVS + State) + QoL + item equipped-only

local addon, ns = ...
local RC = ns.rCooldown
if not RC then return end

RC.UI = RC.UI or {}
local UI = RC.UI

UI._selectedClass = UI._selectedClass or nil
UI._registered = UI._registered or false
UI._opts = UI._opts or nil

UI._filterKnownOnly = UI._filterKnownOnly or false

local CAEVS = ns.CAEVS
local State = ns.State
local AV = RC.Availability

-- ---------------------------
-- Helpers
-- ---------------------------
local function PlayerClass()
  local _, class = UnitClass("player")
  return class or "UNKNOWN"
end

local function EnsureSelectedClass()
  if not UI._selectedClass then
    UI._selectedClass = PlayerClass()
  end
end

local function GetCfg()
  return RC:GetCfg()
end

local function GetGlobal()
  local cfg = GetCfg()
  return cfg and cfg.global or nil
end

local function GetClassDB()
  EnsureSelectedClass()
  return RC:GetClassDB(UI._selectedClass)
end

local function EntryKey(entryType, id)
  return tostring(entryType) .. ":" .. tostring(id)
end

local function EntryLabel(entry)
  if not entry then return "?" end
  if entry.type == "spell" then
    local name = GetSpellInfo(entry.id)
    return name or ("SpellID " .. tostring(entry.id))
  elseif entry.type == "item" then
    local name = GetItemInfo(entry.id)
    return name or ("ItemID " .. tostring(entry.id))
  end
  return "Unknown"
end

local function HasEntryNow(entry)
  if not entry then return false end
  if AV and AV.CanDisplayEntry then
    return AV:CanDisplayEntry(entry) == true
  elseif AV and AV.HasEntry then
    return AV:HasEntry(entry) == true
  end
  return true
end

-- ---------------------------
-- Entry CRUD
-- ---------------------------
local function AddEntry(entryType, raw)
  local id = tonumber(raw)
  if not id or id <= 0 then return end

  local cfg = GetCfg()
  if not cfg then return end

  local g = cfg.global or {}
  local cdb = GetClassDB()
  if not cdb then return end

  local key = EntryKey(entryType, id)
  if cdb.entries[key] then return end

  cdb.entries[key] = {
    type = entryType,
    id = id,
    enabled = true,

    reminderFlashTime = g.defaultReminderFlashTime,
    readyFlash = g.defaultReadyFlash,
    persistence = g.defaultPersistence,
    hideWhenReady = g.defaultHideWhenReady,

    equippedOnly = false, -- items only

    showWhen = { op = "AND", args = {} },
  }

  table.insert(cdb.order, key)

  RC:RequestUpdate()
  UI:RebuildTracked()
end

local function RemoveEntry(key)
  local cdb = GetClassDB()
  if not cdb then return end

  cdb.entries[key] = nil
  for i = #cdb.order, 1, -1 do
    if cdb.order[i] == key then
      table.remove(cdb.order, i)
      break
    end
  end

  RC:RequestUpdate()
  UI:RebuildTracked()
end

local function MoveEntry(key, dir)
  local cdb = GetClassDB()
  if not cdb then return end

  local order = cdb.order or {}
  local idx
  for i = 1, #order do
    if order[i] == key then idx = i break end
  end
  if not idx then return end

  local newIdx = idx + dir
  if newIdx < 1 or newIdx > #order then return end

  order[idx], order[newIdx] = order[newIdx], order[idx]

  RC:RequestUpdate()
  UI:RebuildTracked()
end

-- ---------------------------
-- Condition AST helpers
-- ---------------------------
local function EnsureTree(entry)
  if entry.showWhen == nil or type(entry.showWhen) ~= "table" then
    entry.showWhen = { op = "AND", args = {} }
  end
  if entry.showWhen.op ~= "AND" and entry.showWhen.op ~= "OR" then
    entry.showWhen.op = "AND"
  end
  if type(entry.showWhen.args) ~= "table" then
    entry.showWhen.args = {}
  end
  return entry.showWhen
end

local STATE_CONDITIONS = {
  HealthLow = "Health Low",
  ManaLow   = "Mana Low",
}

local function DefaultStateValue(cond)
  if cond == "HealthLow" then return 35 end
  if cond == "ManaLow" then return 35 end
  return 35
end

local function AddConditionRow(entry, kind)
  local tree = EnsureTree(entry)
  kind = kind or "caevs"

  local row = { kind = kind, negate = false }

  if kind == "caevs" then
    local defaultKey = "combat"
    row.cond = defaultKey
    if CAEVS and CAEVS.InitConditionData then
      row.value = CAEVS:InitConditionData(defaultKey, {})
    else
      row.value = {}
    end
  else
    row.cond = "HealthLow"
    row.value = DefaultStateValue(row.cond)
  end

  table.insert(tree.args, row)
end

local function RemoveConditionRow(entry, idx)
  local tree = EnsureTree(entry)
  if idx < 1 or idx > #tree.args then return end
  table.remove(tree.args, idx)
end

local function MoveConditionRow(entry, idx, dir)
  local tree = EnsureTree(entry)
  local newIdx = idx + dir
  if newIdx < 1 or newIdx > #tree.args then return end
  tree.args[idx], tree.args[newIdx] = tree.args[newIdx], tree.args[idx]
end

-- ---------------------------
-- UI Rebuild
-- ---------------------------
function UI:RebuildTracked()
  if not self._opts or not self._opts.tracked or not self._opts.tracked.args then return end
  local trackedArgs = self._opts.tracked.args
  wipe(trackedArgs)

  local cdb = GetClassDB()
  if not cdb then
    trackedArgs.empty = { type = "description", name = "No class database available.", order = 1 }
    return
  end

  local order = cdb.order or {}
  local entries = cdb.entries or {}

  -- Precompute CAEVS dropdown values
  local caevsValues = (CAEVS and CAEVS.GetConditionList and CAEVS:GetConditionList()) or { combat = "In Combat" }

  -- Apply known-only filter for config display
  local displayKeys = {}
  for i = 1, #order do
    local key = order[i]
    local entry = entries[key]
    if entry then
      if not UI._filterKnownOnly or HasEntryNow(entry) then
        table.insert(displayKeys, key)
      end
    end
  end

  if #displayKeys == 0 then
    trackedArgs.empty = {
      type = "description",
      name = UI._filterKnownOnly and "No entries match the filter (you don't currently have/know any of them)." or "No tracked entries yet.",
      order = 1,
    }
    return
  end

  for dispIndex = 1, #displayKeys do
    local key = displayKeys[dispIndex]
    local entry = entries[key]
    if entry then
      EnsureTree(entry)
      local tree = entry.showWhen
      local rows = tree.args

      local condRowsArgs = {}
      if #rows == 0 then
        condRowsArgs.none = { type = "description", name = "No conditions. Allowed whenever you own/know it.", order = 0 }
      end

      for idx = 1, #rows do
        local row = rows[idx]

        local function GetRow()
          EnsureTree(entry)
          return entry.showWhen.args[idx]
        end

        local function SafeRow()
          local r = GetRow()
          if not r then return nil end
          if r.kind ~= "caevs" and r.kind ~= "state" then r.kind = "caevs" end
          r.negate = (r.negate == true)
          return r
        end

        local rowName
        if row.kind == "state" then
          rowName = STATE_CONDITIONS[row.cond] or (row.cond or "State")
        else
          rowName = caevsValues[row.cond] or (row.cond or "CAEVS")
        end

        local rowGroup = {
          type = "group",
          name = string.format("%02d. %s", idx, rowName),
          order = idx,
          inline = true,
          args = {
            kind = {
              type = "select",
              name = "Type",
              order = 1,
              width = "half",
              values = { caevs = "CAEVS", state = "State" },
              get = function()
                local r = SafeRow()
                return r and r.kind or "caevs"
              end,
              set = function(_, v)
                local r = SafeRow()
                if not r then return end
                r.kind = v
                r.negate = r.negate == true

                if v == "caevs" then
                  local defaultKey = "combat"
                  r.cond = defaultKey
                  if CAEVS and CAEVS.InitConditionData then
                    r.value = CAEVS:InitConditionData(defaultKey, {})
                  else
                    r.value = {}
                  end
                else
                  r.cond = "HealthLow"
                  r.value = DefaultStateValue(r.cond)
                end

                RC:RequestUpdate()
                UI:RebuildTracked()
              end,
            },

            negate = {
              type = "toggle",
              name = "NOT",
              order = 2,
              width = "half",
              get = function()
                local r = SafeRow()
                return r and r.negate == true
              end,
              set = function(_, v)
                local r = SafeRow()
                if not r then return end
                r.negate = v and true or false
                RC:RequestUpdate()
              end,
            },

            up = {
              type = "execute",
              name = "Up",
              order = 3,
              width = "half",
              disabled = function() return idx == 1 end,
              func = function()
                MoveConditionRow(entry, idx, -1)
                RC:RequestUpdate()
                UI:RebuildTracked()
              end,
            },

            down = {
              type = "execute",
              name = "Down",
              order = 4,
              width = "half",
              disabled = function() return idx == #rows end,
              func = function()
                MoveConditionRow(entry, idx, 1)
                RC:RequestUpdate()
                UI:RebuildTracked()
              end,
            },

            remove = {
              type = "execute",
              name = "Remove",
              order = 5,
              width = "full",
              confirm = true,
              confirmText = "Remove this condition row?",
              func = function()
                RemoveConditionRow(entry, idx)
                RC:RequestUpdate()
                UI:RebuildTracked()
              end,
            },

            spacer = { type = "description", name = " ", order = 6 },
          },
        }

        if row.kind == "caevs" then
          rowGroup.args.cond = {
            type = "select",
            name = "Condition",
            order = 7,
            values = caevsValues,
            get = function()
              local r = SafeRow()
              return r and r.cond or "combat"
            end,
            set = function(_, v)
              local r = SafeRow()
              if not r then return end
              r.cond = v
              if CAEVS and CAEVS.InitConditionData then
                r.value = CAEVS:InitConditionData(v, r.value)
              else
                r.value = r.value or {}
              end
              RC:RequestUpdate()
              UI:RebuildTracked()
            end,
          }

          if CAEVS and CAEVS.BuildConditionOptions then
            rowGroup.args.params = {
              type = "group",
              name = "Parameters",
              order = 8,
              inline = true,
              args = CAEVS:BuildConditionOptions(
                row.cond,
                function()
                  local r = SafeRow()
                  if not r then return {} end
                  r.value = r.value or {}
                  return r.value
                end,
                function(newData)
                  local r = SafeRow()
                  if not r then return end
                  r.value = newData or {}
                  RC:RequestUpdate()
                end
              ),
            }
          end
        else
          rowGroup.args.cond = {
            type = "select",
            name = "Condition",
            order = 7,
            values = STATE_CONDITIONS,
            get = function()
              local r = SafeRow()
              return r and r.cond or "HealthLow"
            end,
            set = function(_, v)
              local r = SafeRow()
              if not r then return end
              r.cond = v
              if r.value == nil then r.value = DefaultStateValue(v) end
              RC:RequestUpdate()
              UI:RebuildTracked()
            end,
          }

          rowGroup.args.threshold = {
            type = "range",
            name = "Threshold (%)",
            order = 8,
            min = 0, max = 100, step = 1,
            get = function()
              local r = SafeRow()
              if not r then return 35 end
              return tonumber(r.value) or DefaultStateValue(r.cond)
            end,
            set = function(_, v)
              local r = SafeRow()
              if not r then return end
              r.value = v
              RC:RequestUpdate()
            end,
          }
        end

        condRowsArgs["row" .. idx] = rowGroup
      end

      trackedArgs[key] = {
        type = "group",
        name = string.format("%02d. %s", dispIndex, EntryLabel(entry)),
        order = dispIndex,
        inline = false,
        args = {
          enabled = {
            type = "toggle",
            name = "Enabled",
            order = 1,
            width = "half",
            get = function() return entry.enabled ~= false end,
            set = function(_, v)
              entry.enabled = v and true or false
              RC:RequestUpdate()
            end,
          },
          up = {
            type = "execute",
            name = "Up",
            order = 2,
            width = "half",
            disabled = function() return dispIndex == 1 end,
            func = function() MoveEntry(key, -1) end,
          },
          down = {
            type = "execute",
            name = "Down",
            order = 3,
            width = "half",
            disabled = function() return dispIndex == #displayKeys end,
            func = function() MoveEntry(key, 1) end,
          },
          remove = {
            type = "execute",
            name = "Remove",
            order = 4,
            width = "half",
            confirm = true,
            confirmText = "Remove this tracked entry?",
            func = function() RemoveEntry(key) end,
          },

          spacer1 = { type = "description", name = " ", order = 5 },

          reminder = {
            type = "range",
            name = "Reminder Flash Time (seconds)",
            order = 6,
            min = 0, max = 60, step = 0.5,
            get = function() return tonumber(entry.reminderFlashTime) or 0 end,
            set = function(_, v)
              entry.reminderFlashTime = v
              RC:RequestUpdate()
            end,
          },
          readyFlash = {
            type = "toggle",
            name = "Ready Flash",
            order = 7,
            get = function() return entry.readyFlash ~= false end,
            set = function(_, v)
              entry.readyFlash = v and true or false
              RC:RequestUpdate()
            end,
          },
          persistence = {
            type = "toggle",
            name = "Persistence (keep visible when ready)",
            order = 8,
            get = function() return entry.persistence == true end,
            set = function(_, v)
              entry.persistence = v and true or false
              RC:RequestUpdate()
            end,
          },
          hideWhenReady = {
            type = "toggle",
            name = "Hide When Ready (show only on cooldown)",
            order = 9,
            get = function() return entry.hideWhenReady ~= false end,
            set = function(_, v)
              entry.hideWhenReady = v and true or false
              RC:RequestUpdate()
            end,
          },

          equippedOnly = {
            type = "toggle",
            name = "Equipped Only (items)",
            order = 10,
            hidden = function() return entry.type ~= "item" end,
            get = function() return entry.equippedOnly == true end,
            set = function(_, v)
              entry.equippedOnly = v and true or false
              RC:RequestUpdate()
              UI:RebuildTracked()
            end,
          },

          spacer2 = { type = "description", name = " ", order = 11 },

          showWhen = {
            type = "group",
            name = "Show When (Conditions)",
            order = 12,
            inline = false,
            args = {
              rootOp = {
                type = "select",
                name = "Match",
                order = 1,
                values = { AND = "All (AND)", OR = "Any (OR)" },
                get = function()
                  EnsureTree(entry)
                  return entry.showWhen.op or "AND"
                end,
                set = function(_, v)
                  EnsureTree(entry)
                  entry.showWhen.op = v
                  RC:RequestUpdate()
                end,
              },
              addCAEVS = {
                type = "execute",
                name = "Add CAEVS Condition",
                order = 2,
                func = function()
                  AddConditionRow(entry, "caevs")
                  RC:RequestUpdate()
                  UI:RebuildTracked()
                end,
              },
              addState = {
                type = "execute",
                name = "Add State Condition",
                order = 3,
                func = function()
                  AddConditionRow(entry, "state")
                  RC:RequestUpdate()
                  UI:RebuildTracked()
                end,
              },
              spacer = { type = "description", name = " ", order = 4 },

              rows = {
                type = "group",
                name = "Conditions",
                order = 5,
                inline = false,
                args = condRowsArgs,
              },
            },
          },
        },
      }
    end
  end
end

-- ---------------------------
-- Init / registration
-- ---------------------------
function UI:Init()
  if self._registered then return end
  if not Roth_UI or not Roth_UI.AddConfig then return end

  EnsureSelectedClass()

  -- AddConfig expects an args table only
  local opts = {
    global = {
      type = "group",
      name = "Global",
      inline = true,
      order = 1,
      args = {
        enabled = {
          type = "toggle",
          name = "Enable Cooldown Tracking",
          order = 1,
          get = function()
            local cfg = GetCfg()
            return cfg and cfg.enabled ~= false
          end,
          set = function(_, v)
            local cfg = GetCfg()
            if cfg then
              cfg.enabled = v and true or false
              RC:RequestUpdate()
            end
          end,
        },
        layoutMode = {
          type = "select",
          name = "Layout Mode",
          desc = "Static: fixed positions based on the list order. Dynamic: first-come first-shown (icons pack left-to-right with no holes).",
          order = 2.5,
          values = {
            static = "Static Slots (fixed positions)",
            dynamic = "Dynamic (first-come first-shown)",
          },
          get = function()
            local g = GetGlobal()
            return (g and g.layoutMode) or "static"
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.layoutMode = v
              RC:RequestUpdate()
            end
          end,
        },

        ignoreGCD = {
          type = "toggle",
          name = "Ignore GCD-Only Cooldowns",
          desc = "If enabled, very short cooldowns (<= ~1.6s) are treated as ready. Helps avoid icons appearing just from the global cooldown.",
          order = 2,
          get = function()
            local g = GetGlobal()
            return g and g.ignoreGCD == true
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.ignoreGCD = v and true or false
              RC:RequestUpdate()
            end
          end,
        },

        iconSize = {
          type = "range",
          name = "Icon Size",
          order = 3,
          min = 18, max = 64, step = 1,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.iconSize) or 36
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.iconSize = v
              RC:RequestUpdate()
            end
          end,
        },

        iconSpacing = {
          type = "range",
          name = "Icon Spacing",
          order = 4,
          min = 0, max = 20, step = 1,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.iconSpacing) or 6
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.iconSpacing = v
              RC:RequestUpdate()
            end
          end,
        },

        fontSize = {
          type = "range",
          name = "Cooldown Text Size",
          order = 5,
          min = 8, max = 24, step = 1,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.fontSize) or 14
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.fontSize = v
              RC:RequestUpdate()
            end
          end,
        },

        updateInterval = {
          type = "range",
          name = "Update Interval (seconds)",
          order = 6,
          min = 0.05, max = 0.5, step = 0.01,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.updateInterval) or 0.10
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.updateInterval = v
              RC:RequestUpdate()
            end
          end,
        },

        readyFlashPersistence = {
          type = "range",
          name = "Ready Flash Persistence (seconds)",
          order = 7,
          min = 0, max = 10, step = 0.25,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.readyFlashPersistence) or 2.0
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.readyFlashPersistence = v
              RC:RequestUpdate()
            end
          end,
        },

        readyHideDelay = {
          type = "range",
          name = "Ready Hide Delay (seconds)",
          order = 8,
          min = 0, max = 10, step = 0.25,
          get = function()
            local g = GetGlobal()
            return tonumber(g and g.readyHideDelay) or 3.0
          end,
          set = function(_, v)
            local g = GetGlobal()
            if g then
              g.readyHideDelay = v
              RC:RequestUpdate()
            end
          end,
        },
      },
    },

    classSelect = {
      type = "select",
      name = "Class List",
      order = 2,
      values = function()
        local out = {}
        local cfg = GetCfg()
        if cfg and cfg.class then
          for classToken in pairs(cfg.class) do
            out[classToken] = classToken
          end
        end
        out[PlayerClass()] = PlayerClass()
        return out
      end,
      get = function()
        EnsureSelectedClass()
        return UI._selectedClass
      end,
      set = function(_, v)
        UI._selectedClass = v
        RC:RequestUpdate()
        UI:RebuildTracked()
      end,
    },

    filterKnown = {
      type = "toggle",
      name = "Show only entries I have/know (filter)",
      order = 3,
      get = function() return UI._filterKnownOnly == true end,
      set = function(_, v)
        UI._filterKnownOnly = v and true or false
        UI:RebuildTracked()
      end,
    },

    add = {
      type = "group",
      name = "Add",
      inline = true,
      order = 4,
      args = {
        addSpell = {
          type = "input",
          name = "Add SpellID",
          order = 1,
          set = function(_, v) AddEntry("spell", v) end,
        },
        addItem = {
          type = "input",
          name = "Add ItemID",
          order = 2,
          set = function(_, v) AddEntry("item", v) end,
        },
      },
    },

    tracked = {
      type = "group",
      name = "Tracked",
      order = 5,
      args = {},
    },
  }

  self._opts = opts

  Roth_UI:AddConfig("embeds.rCooldown", opts, "Cooldown Tracking", function()
    RC:GetClassDB(PlayerClass())
  end)

  self:RebuildTracked()
  self._registered = true
end