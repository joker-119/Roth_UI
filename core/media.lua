-- core/media.lua
local addon, ns = ...
ns.Media = ns.Media or {}
local Media = ns.Media

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ------------------------------------------------------------
-- Media change bus (callbacks)
-- ------------------------------------------------------------
-- If you already have these in some other core file, keep only ONE copy.
ns._mediaCallbacks = ns._mediaCallbacks or {}

function ns:ListenForMediaChange(cb)
  if type(cb) ~= "function" then return end
  ns._mediaCallbacks[cb] = true

  -- Optional but recommended: call once immediately so modules can apply on load
  -- (prevents "font is default until first LSM event")
  local ok, err = pcall(cb)
  if not ok and err then
    -- Keep this silent or route to your debug printer if you have one
    -- print("Roth_UI media callback error:", err)
  end
end

function ns:UnlistenForMediaChange(cb)
  if not cb then return end
  ns._mediaCallbacks[cb] = nil
end

function ns:FireMediaChange()
  for cb in pairs(ns._mediaCallbacks) do
    local ok, err = pcall(cb)
    if not ok and err then
      -- print("Roth_UI media callback error:", err)
    end
  end
end

-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------
local function looksLikePath(s)
  return type(s) == "string" and (s:find("\\") or s:find("/") or s:find("%.ttf") or s:find("%.otf") or s:find("%.blp"))
end

local function safeFetch(kind, key)
  if not LSM or not key then return nil end
  -- 3rd arg 'silent' = true prevents LSM from spewing errors
  local v = LSM:Fetch(kind, key, true)
  if v and v ~= "" then return v end
  return nil
end

-- ------------------------------------------------------------
-- Public API
-- ------------------------------------------------------------

-- Media.Font("MyFontName", "FallbackFontName")
-- Also accepts a direct file path and returns it untouched.
function Media.Font(key, fallback)
  -- If a direct path is provided, accept it (useful for RothFont, embedded fonts, etc.)
  if looksLikePath(key) then
    return key
  end

  local font = safeFetch("font", key)
  if font then return font end

  if looksLikePath(fallback) then
    return fallback
  end

  local fb = safeFetch("font", fallback)
  if fb then return fb end

  -- Reasonable final fallback for all Classic branches
  return STANDARD_TEXT_FONT
end

-- Media.Texture("MyTextureName", "FallbackTextureName", "statusbar")
-- kind defaults to "statusbar" because most uses are bars, but you can pass:
-- "background", "border", "sound", etc. (whatever LSM supports)
-- Also accepts direct file paths.
function Media.Texture(key, fallback, kind)
  kind = kind or "statusbar"

  if looksLikePath(key) then
    return key
  end

  local tex = safeFetch(kind, key)
  if tex then return tex end

  if looksLikePath(fallback) then
    return fallback
  end

  local fb = safeFetch(kind, fallback)
  if fb then return fb end

  -- Final fallback (classic-safe statusbar)
  return "Interface\\TargetingFrame\\UI-StatusBar"
end

-- ------------------------------------------------------------
-- Hook LibSharedMedia events -> FireMediaChange
-- ------------------------------------------------------------
-- This is the "propagate cleanly" part: any time LSM registers a new media
-- asset or global changes, we notify all subscribers to re-apply fonts/textures.
if LSM and LSM.RegisterCallback then
  -- Different LSM versions fire slightly different callbacks; these cover the usual ones.
  local function onLSMChange()
    ns:FireMediaChange()
  end

  -- Fired when new media is registered (common in Classic UI packs)
  pcall(LSM.RegisterCallback, LSM, "LibSharedMedia_Registered", onLSMChange)
  -- Fired when defaults change
  pcall(LSM.RegisterCallback, LSM, "LibSharedMedia_SetGlobal", onLSMChange)
  -- Some versions use this name
  pcall(LSM.RegisterCallback, LSM, "LibSharedMedia_Register", onLSMChange)
end