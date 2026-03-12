-- Roth_UI/embeds/rCooldown/core.lua
-- rCooldown (Roth UI)
-- Fixed-slot cooldown tracking with CAEVS + State aware per-entry conditions.
-- Integrated with Roth_UI init + config systems + drag system.

local addon, ns = ...
ns.rCooldown = ns.rCooldown or {}
local RC = ns.rCooldown

local Visibility = ns.Visibility
local Expr       = ns.Expr -- core/conditions/expr.lua

RC.ELEMENT_KEY   = "rCooldownTracking"
RC.ELEMENT_NAME  = "Cooldown Tracking"
RC.ELEMENT_GROUP = "Cooldown Tracking"

-- ---------------------------------------------------------------------
-- Defaults (also in config.lua defaults.profile.embeds.rCooldown)
-- ---------------------------------------------------------------------
local FALLBACK_DEFAULTS = {
  enabled = true,

  -- drag position lives at embeds.rCooldown.pos
  pos = {
    a1 = "CENTER",
    af = "UIParent",
    a2 = "CENTER",
    x  = 0,
    y  = -200,
  },

  global = {
    bar1Cap = 6,
    bar2Cap = 6,
    overflowCap = 0,

    updateInterval = 0.10,
    readyFlashPersistence = 2.0,
    readyHideDelay = 3.0,

    defaultReminderFlashTime = 3.0,
    defaultReadyFlash = true,
    defaultPersistence = false,
    defaultHideWhenReady = true,

    -- renderer QoL
    iconSize = 36,
    iconSpacing = 6,
    fontSize = 14,

    -- model QoL
    ignoreGCD = false,
  },

  class = {},
}

local function CopyDefaults(dst, src)
  for k, v in pairs(src) do
    if type(v) == "table" then
      if type(dst[k]) ~= "table" then dst[k] = {} end
      CopyDefaults(dst[k], v)
    else
      if dst[k] == nil then dst[k] = v end
    end
  end
end

local function PlayerClass()
  local _, class = UnitClass("player")
  return class or "UNKNOWN"
end

-- ---------------------------------------------------------------------
-- Config access
-- ---------------------------------------------------------------------
local function EnsureDefaults()
  ns.cfg = ns.cfg or {}
  ns.cfg.embeds = ns.cfg.embeds or {}
  ns.cfg.embeds.rCooldown = ns.cfg.embeds.rCooldown or {}
  CopyDefaults(ns.cfg.embeds.rCooldown, FALLBACK_DEFAULTS)

  if Roth_UI and Roth_UI.db and Roth_UI.db.profile then
    Roth_UI.db.profile.embeds = Roth_UI.db.profile.embeds or {}
    Roth_UI.db.profile.embeds.rCooldown = Roth_UI.db.profile.embeds.rCooldown or {}
    CopyDefaults(Roth_UI.db.profile.embeds.rCooldown, FALLBACK_DEFAULTS)
  end
end

function RC:GetCfg()
  if Roth_UI and Roth_UI.db and Roth_UI.db.profile and Roth_UI.db.profile.embeds and Roth_UI.db.profile.embeds.rCooldown then
    return Roth_UI.db.profile.embeds.rCooldown
  end
  return ns.cfg and ns.cfg.embeds and ns.cfg.embeds.rCooldown
end

function RC:GetGlobal()
  local cfg = self:GetCfg()
  return cfg and cfg.global or nil
end

function RC:GetClassDB(class)
  local cfg = self:GetCfg()
  if not cfg then return nil end
  cfg.class = cfg.class or {}
  class = class or PlayerClass()
  cfg.class[class] = cfg.class[class] or { order = {}, entries = {} }
  cfg.class[class].order = cfg.class[class].order or {}
  cfg.class[class].entries = cfg.class[class].entries or {}
  return cfg.class[class]
end

-- ---------------------------------------------------------------------
-- Root frame + drag integration
-- ---------------------------------------------------------------------
RC.frame = RC.frame or CreateFrame("Frame", "RothUI_rCooldownFrame", UIParent)
RC.frame:Hide()

local function ApplyPosition()
  local cfg = RC:GetCfg()
  if not cfg then return end

  cfg.pos = cfg.pos or {}
  local p = cfg.pos

  local a1 = p.a1 or "CENTER"
  local af = p.af or "UIParent"
  local a2 = p.a2 or "CENTER"
  local x  = p.x or 0
  local y  = p.y or 0

  local anchor = _G[af] or UIParent

  RC.frame:ClearAllPoints()
  RC.frame:SetPoint(a1, anchor, a2, x, y)
end

local function ApplyDrag()
  -- Tie into Roth unlock/lock system (SHIFT drag overlay)
  if ns.func and ns.func.applyDragFunctionality then
    local cfg = RC:GetCfg()
    if cfg then
      -- IMPORTANT: applyDragFunctionality saves into f.cfg.pos
      RC.frame.cfg = cfg
      cfg.pos = cfg.pos or {}
    end
    ns.func.applyDragFunctionality(RC.frame)

    -- Optional: when unlocked, ensure the footprint stays draggable
    -- (frame is already sized by Frames.lua, so no special casing needed here)
  end
end

-- ---------------------------------------------------------------------
-- CAEVS visibility
-- ---------------------------------------------------------------------
function RC:RegisterVisibility()
  if not Visibility or not Visibility.Register then return end
  Visibility.Register(self.ELEMENT_KEY, self.frame, {
    name  = self.ELEMENT_NAME,
    group = self.ELEMENT_GROUP,
    props = { "shown" },
  })
end

-- ---------------------------------------------------------------------
-- Dirty / update pipeline
-- ---------------------------------------------------------------------
RC._dirty = true
RC._lastTick = 0

function RC:MarkDirty()
  self._dirty = true
end

function RC:RequestUpdate()
  self:MarkDirty()
end

function RC:EvalShowWhen(tree)
  if Expr and Expr.Eval then
    return Expr.Eval(tree)
  end
  return true
end

function RC:RebuildModel()
  local cfg = self:GetCfg()
  if not cfg then return end

  local class = PlayerClass()
  self:GetClassDB(class)

  if self.Availability and self.Availability.Refresh then
    self.Availability:Refresh()
  end

  if self.Model and self.Model.BuildSlots then
    self.Model:BuildSlots(class)
  end
end

function RC:Tick(elapsed)
  local cfg = self:GetCfg()
  local g = cfg and cfg.global
  if not cfg or not g or cfg.enabled == false then
    return
  end

  self._lastTick = self._lastTick + elapsed
  if self._lastTick < (g.updateInterval or 0.10) then
    return
  end
  self._lastTick = 0

  if self._dirty then
    self._dirty = false
    self:RebuildModel()
  end

  if self.Model and self.Model.Tick then
    self.Model:Tick()
  end

  if self.Frames and self.Frames.Refresh then
    self.Frames:Refresh()
  end
end

RC.frame:SetScript("OnUpdate", function(_, elapsed)
  RC:Tick(elapsed)
end)

-- ---------------------------------------------------------------------
-- Events
-- ---------------------------------------------------------------------
RC.events = RC.events or CreateFrame("Frame")
RC.events:Hide()

local function OnEvent(_, event)
  if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
    RC:MarkDirty()
    return
  end

  if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_EQUIPMENT_CHANGED" then
    RC:MarkDirty()
    return
  end

  if event == "SPELL_UPDATE_COOLDOWN" or event == "BAG_UPDATE_COOLDOWN" then
    RC:MarkDirty()
    return
  end

  if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" or event == "ZONE_CHANGED_NEW_AREA" then
    RC:MarkDirty()
    return
  end
end

RC.events:SetScript("OnEvent", OnEvent)

local function RegisterEvents()
  RC.events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  RC.events:RegisterEvent("PLAYER_REGEN_DISABLED")
  RC.events:RegisterEvent("PLAYER_REGEN_ENABLED")

  RC.events:RegisterEvent("SPELLS_CHANGED")
  RC.events:RegisterEvent("PLAYER_TALENT_UPDATE")

  RC.events:RegisterEvent("BAG_UPDATE_DELAYED")
  RC.events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")

  RC.events:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  RC.events:RegisterEvent("BAG_UPDATE_COOLDOWN")
end

-- ---------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------
local function Init()
  EnsureDefaults()

  ApplyPosition()
  ApplyDrag()

  if RC.Availability and RC.Availability.Init then RC.Availability:Init() end
  if RC.Model and RC.Model.Init then RC.Model:Init() end
  if RC.Frames and RC.Frames.Init then RC.Frames:Init() end
  if RC.UI and RC.UI.Init then RC.UI:Init() end

  RegisterEvents()

  -- IMPORTANT: Show FIRST so Visibility captures baseline shown=true.
  RC.frame:Show()
  RC:RegisterVisibility()
  -- Do NOT force Show after this; CAEVS owns shown/hidden.

  RC:MarkDirty()
end

ns:RegisterInit(Init)