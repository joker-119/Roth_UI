-- Roth_UI/embeds/rCooldown/model.lua
-- Compacted-slot model: entries that cannot be displayed are removed from the slot list.

local addon, ns = ...
local RC = ns.rCooldown
if not RC then return end

local AV = RC.Availability
local CD = RC.Cooldowns

RC.Model = RC.Model or {}
local Model = RC.Model

Model._slots = Model._slots or {}
Model._runtime = Model._runtime or {}

local function Now()
  return GetTime()
end

local function GetRuntime(key)
  local rt = Model._runtime[key]
  if not rt then
    rt = { lastOnCD = false, lastReadyAt = 0, lingerUntil = 0 }
    Model._runtime[key] = rt
  end
  return rt
end

local function NewSlot(index, key, entry)
  return {
    index = index,
    key = key,
    entry = entry,

    visible = false,
    state = "HIDDEN",

    cdStart = 0,
    cdDuration = 0,
    cdEnabled = 0,

    remaining = 0,
    onCD = false,
  }
end

function Model:BuildSlots(class)
  local classDB = RC:GetClassDB(class)
  if not classDB then return end

  self._slots[class] = self._slots[class] or {}
  local slots = self._slots[class]
  wipe(slots)

  local order = classDB.order or {}
  local entries = classDB.entries or {}

  local outIndex = 0

  for i = 1, #order do
    local key = order[i]
    local entry = entries[key]
    if entry and AV and AV.CanDisplayEntry and AV:CanDisplayEntry(entry) then
      outIndex = outIndex + 1
      slots[outIndex] = NewSlot(outIndex, key, entry)
    end
  end
end

function Model:Tick()
  local cfg = RC:GetCfg()
  local g = cfg and cfg.global
  if not g then return end

  local _, class = UnitClass("player")
  class = class or "UNKNOWN"

  local slots = self._slots[class]
  if not slots then return end

  local now = Now()
  local readyFlashPersist = tonumber(g.readyFlashPersistence) or 2
  local readyHideDelay = tonumber(g.readyHideDelay) or 3
  local defaultReminder = tonumber(g.defaultReminderFlashTime) or 3
  local ignoreGCD = (g.ignoreGCD == true)

  for i = 1, #slots do
    local slot = slots[i]
    local entry = slot.entry
    local key = slot.key
    local rt = GetRuntime(key)

    slot.visible = false
    slot.state = "HIDDEN"
    slot.cdStart = 0
    slot.cdDuration = 0
    slot.cdEnabled = 0
    slot.remaining = 0
    slot.onCD = false

    local ok = true

    if not entry or entry.enabled == false then
      ok = false
    end

    -- NOTE: availability filtering (learned / equipped / owned) is handled in BuildSlots()
    -- Here we only handle conditions + cooldown + visual state.

    if ok and entry.showWhen ~= nil and RC:EvalShowWhen(entry.showWhen) ~= true then
      ok = false
    end

    if ok then
      local cd = CD:GetEntryCooldown(entry)

      if ignoreGCD and cd.isGCD == true and (cd.duration or 0) <= 1.6 then
        cd = { start = 0, duration = 0, enabled = 0, remaining = 0, isGCD = true }
      end

      local remaining = tonumber(cd.remaining) or 0
      local duration = tonumber(cd.duration) or 0
      local onCD = remaining > 0

      slot.cdStart = tonumber(cd.start) or 0
      slot.cdDuration = duration
      slot.cdEnabled = tonumber(cd.enabled) or 0
      slot.remaining = remaining
      slot.onCD = onCD

      if rt.lastOnCD and not onCD then
        rt.lastReadyAt = now
        rt.lingerUntil = now + readyHideDelay
      end
      rt.lastOnCD = onCD

      local reminderTime = entry.reminderFlashTime
      if reminderTime == nil then reminderTime = defaultReminder end
      reminderTime = tonumber(reminderTime) or 0

      local readyFlashAllowed = entry.readyFlash
      if readyFlashAllowed == nil then readyFlashAllowed = g.defaultReadyFlash end
      readyFlashAllowed = (readyFlashAllowed ~= false)

      local persistence = entry.persistence
      if persistence == nil then persistence = g.defaultPersistence end
      persistence = (persistence == true)

      local hideWhenReady = entry.hideWhenReady
      if hideWhenReady == nil then hideWhenReady = g.defaultHideWhenReady end
      hideWhenReady = (hideWhenReady ~= false)

      if onCD then
        slot.visible = true
        if reminderTime > 0 and remaining <= reminderTime then
          slot.state = "REMINDER"
        else
          slot.state = "COOLDOWN"
        end
      else
        local sinceReady = now - (rt.lastReadyAt or 0)

        if readyFlashAllowed and sinceReady <= readyFlashPersist then
          slot.visible = true
          slot.state = "READYFLASH"
        elseif persistence then
          slot.visible = true
          slot.state = "READY"
        else
          if hideWhenReady then
            if now <= (rt.lingerUntil or 0) then
              slot.visible = true
              slot.state = "READY"
            else
              slot.visible = false
              slot.state = "HIDDEN"
            end
          else
            slot.visible = true
            slot.state = "READY"
          end
        end
      end
    end
  end
end

function Model:GetSlotsForClass(class)
  return self._slots[class]
end

function Model:Init()
end