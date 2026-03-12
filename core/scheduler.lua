-- core/scheduler.lua
local addon, ns = ...
ns.Scheduler = ns.Scheduler or {}
local Scheduler = ns.Scheduler

-- ------------------------------------------------------------
-- Internal: Safe call wrapper
-- ------------------------------------------------------------
local function SafeCall(fn, ...)
  if type(fn) ~= "function" then return end
  local ok, err = pcall(fn, ...)
  if not ok and err then
    -- Keep silent by default; route to your debug output if you have one.
    -- print("Roth_UI Scheduler error:", err)
  end
end

-- ------------------------------------------------------------
-- Backend selection: C_Timer if available, else fallback driver
-- ------------------------------------------------------------
local hasCTimer = type(C_Timer) == "table"
  and type(C_Timer.After) == "function"
  and type(C_Timer.NewTicker) == "function"

-- Fallback driver for clients/environments without C_Timer.*
local driverFrame
local pending = {}  -- list of { t = dueTime, fn = function, id = token }
local now = (type(GetTime) == "function") and GetTime or function() return 0 end

local function EnsureDriver()
  if driverFrame then return end
  driverFrame = CreateFrame("Frame")
  driverFrame:SetScript("OnUpdate", function(_, elapsed)
    local t = now()
    -- iterate backwards so we can remove safely
    for i = #pending, 1, -1 do
      local job = pending[i]
      if t >= job.t then
        table.remove(pending, i)
        SafeCall(job.fn)
      end
    end
    if #pending == 0 then
      driverFrame:SetScript("OnUpdate", nil)
      driverFrame:Hide()
    end
  end)
  driverFrame:Hide()
end

local function FallbackAfter(seconds, fn)
  EnsureDriver()
  local due = now() + (seconds or 0)
  local job = { t = due, fn = fn }
  pending[#pending + 1] = job
  driverFrame:Show()
  return job -- token
end

local function FallbackCancel(token)
  if not token then return end
  for i = #pending, 1, -1 do
    if pending[i] == token then
      table.remove(pending, i)
      break
    end
  end
end

-- ------------------------------------------------------------
-- Public API: After / NextFrame / Every
-- ------------------------------------------------------------

-- Run fn once after N seconds. Returns a cancel function when possible.
function Scheduler.After(seconds, fn)
  if hasCTimer then
    local cancelled = false
    C_Timer.After(seconds or 0, function()
      if cancelled then return end
      SafeCall(fn)
    end)
    return function() cancelled = true end
  else
    local token = FallbackAfter(seconds or 0, fn)
    return function() FallbackCancel(token) end
  end
end

-- Run on next frame (0 delay).
function Scheduler.NextFrame(fn)
  return Scheduler.After(0, fn)
end

-- Run repeatedly every interval seconds. Returns a cancel function.
function Scheduler.Every(interval, fn)
  interval = interval or 1
  if hasCTimer then
    local ticker = C_Timer.NewTicker(interval, function()
      SafeCall(fn)
    end)
    return function()
      if ticker and ticker.Cancel then ticker:Cancel() end
    end
  else
    local cancelled = false
    local function tick()
      if cancelled then return end
      SafeCall(fn)
      Scheduler.After(interval, tick)
    end
    local cancel = Scheduler.After(interval, tick)
    return function()
      cancelled = true
      if cancel then cancel() end
    end
  end
end

-- ------------------------------------------------------------
-- Keyed throttling / debouncing (CAEVS-friendly)
-- ------------------------------------------------------------
local throttleState = {} -- key -> { last = time, pending = bool, cancel = func }
local debounceState = {} -- key -> { cancel = func }

-- Throttle: first call runs immediately if interval elapsed;
-- otherwise coalesces into a single delayed run.
function Scheduler.Throttle(key, interval, fn)
  if not key then
    -- no key: treat as simple after(0) call
    return Scheduler.NextFrame(fn)
  end

  interval = interval or 0.1
  local st = throttleState[key]
  if not st then
    st = { last = 0, pending = false, cancel = nil }
    throttleState[key] = st
  end

  local t = now()
  local delta = t - (st.last or 0)

  if delta >= interval then
    st.last = t
    st.pending = false
    if st.cancel then st.cancel(); st.cancel = nil end
    SafeCall(fn)
    return
  end

  -- Already scheduled? Don't schedule again.
  if st.pending then return end

  st.pending = true
  local delay = interval - delta
  st.cancel = Scheduler.After(delay, function()
    st.pending = false
    st.last = now()
    st.cancel = nil
    SafeCall(fn)
  end)
end

-- Debounce: last call wins; runs only after delay has passed with no new calls.
function Scheduler.Debounce(key, delay, fn)
  if not key then
    return Scheduler.After(delay or 0, fn)
  end

  delay = delay or 0.2
  local st = debounceState[key]
  if not st then
    st = { cancel = nil }
    debounceState[key] = st
  end

  if st.cancel then st.cancel() end
  st.cancel = Scheduler.After(delay, function()
    st.cancel = nil
    SafeCall(fn)
  end)
end

-- Optional: clear state for a key (useful if modules are disabled)
function Scheduler.ClearKey(key)
  local t = throttleState[key]
  if t and t.cancel then t.cancel() end
  throttleState[key] = nil

  local d = debounceState[key]
  if d and d.cancel then d.cancel() end
  debounceState[key] = nil
end