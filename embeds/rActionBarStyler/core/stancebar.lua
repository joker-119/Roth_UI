
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg
  --get some values from the namespace
  local cfg = gcfg.bars.stancebar
  local dragFrameList = ns.dragFrameList

  -----------------------------
  -- FUNCTIONS
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
  if not cfg.enable then return end

  local num = NUM_STANCE_SLOTS or GetNumShapeshiftForms() or 0
  local buttonList = {}

local function GetButtonIconTexture(btn)
  -- Retail-ish
  if btn.icon and btn.icon.GetObjectType then return btn.icon end
  if btn.Icon and btn.Icon.GetObjectType then return btn.Icon end

  -- Classic stance buttons usually have an "Icon" region name
  local name = btn.GetName and btn:GetName()
  if name then
    local t = _G[name.."Icon"]
    if t and t.GetObjectType then return t end
  end

  return nil
end

local function SkinStanceButton(btn)
  if not btn or btn.__rothSkinned then return end

  local icon = GetButtonIconTexture(btn)
  if not icon then return end

  -- Remove Blizzard art that fights our look
  if btn.SetNormalTexture then btn:SetNormalTexture(nil) end
  if btn.SetPushedTexture then btn:SetPushedTexture(nil) end
  if btn.SetHighlightTexture then
    local ht = btn:GetHighlightTexture()
    if ht then ht:SetTexture(nil) end
  end
  if btn.SetCheckedTexture then
    local ct = btn:GetCheckedTexture()
    if ct then ct:SetTexture(nil) end
  end

  -- Apply Roth minimal socket skin
  ns.SkinIconMinimal(btn, icon, {
    inset = 3,      -- stance buttons tend to look better with a slightly thicker frame
    bgAlpha = 0.72, -- a bit darker to feel embedded
    crop = 0.07,
  })

  -- Optional: show selection state (stance active) with a subtle warm tint
  -- (this keeps it Diablo-ish without adding new art)
  btn:HookScript("OnUpdate", function(self)
    if not self._rothFrame then return end
    if self:GetChecked() then
      self._rothFrame:SetVertexColor(0.80, 0.72, 0.55, 1) -- warm/active
    else
      self._rothFrame:SetVertexColor(0.55, 0.50, 0.45, 1) -- dark metal default
    end
  end)

  btn.__rothSkinned = true
end

-- wrapper
local frame = CreateFrame("Frame", "rABS_StanceBar", UIParent, "SecureHandlerStateTemplate")
frame:SetSize(num*cfg.buttons.size + (num-1)*cfg.buttons.margin + 2*cfg.padding, cfg.buttons.size + 2*cfg.padding)
frame:SetScale(cfg.scale)

local function ResolveAnchor(af)
  if type(af) == "string" then
    return _G[af]
  end
  return af
end

local function GetStanceFrame()
  if not Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE)
    and not Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
    return StanceBarFrame
  else
    return StanceBar
  end
end

local function Layout()
  -- 1) position wrapper (after anchor exists)
  local rel = ResolveAnchor(cfg.pos.af) or UIParent
  frame:ClearAllPoints()
  frame:SetPoint(cfg.pos.a1, rel, cfg.pos.a2, cfg.pos.x, cfg.pos.y)

  -- 2) recompute stance count (it can change on cold login)
  local n = GetNumShapeshiftForms and GetNumShapeshiftForms() or NUM_STANCE_SLOTS or 0
  if n < 1 then n = num or 0 end

  frame:SetWidth(n * cfg.buttons.size + (n - 1) * cfg.buttons.margin + 2 * cfg.padding)
  frame:SetHeight(cfg.buttons.size + 2 * cfg.padding)

  -- 3) force stance frame to obey wrapper (Blizzard will try to reanchor it)
  local stanceFrame = GetStanceFrame()
  if not stanceFrame then return end

  stanceFrame:SetParent(frame)
  stanceFrame:EnableMouse(false)
  stanceFrame:ClearAllPoints()
  stanceFrame:SetAllPoints(frame)

  -- 4) re-place the buttons (Blizzard may have just moved them)
  for i = 1, n do
    local button = _G["StanceButton"..i]
    if button then
      SkinStanceButton(button)
      button:SetSize(cfg.buttons.size, cfg.buttons.size)
      button:ClearAllPoints()
      if i == 1 then
        button:SetPoint("BOTTOMLEFT", frame, cfg.padding, cfg.padding)
      else
        local prev = _G["StanceButton"..(i-1)]
        if prev then
          button:SetPoint("LEFT", prev, "RIGHT", cfg.buttons.margin, 0)
        end
      end
    end
  end
end

-- Run once after the world is live
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("UPDATE_SHAPESHIFT_FORMS") -- this is the one that usually “snaps” it back
ev:SetScript("OnEvent", function()
  -- defer one tick so Blizzard finishes its own layout pass first
  ns.Scheduler.NextFrame(Layout)
end)

-- initial (in case this file loads late)
ns.Scheduler.NextFrame(Layout)

  --STANCE BAR

  --move the buttons into position and reparent them
  local stanceFrame
  if not Roth_UI:CheckClientVersion(WOW_PROJECT_MAINLINE) and not Roth_UI:CheckClientVersion(WOW_PROJECT_BURNING_CRUSADE_CLASSIC) then
      stanceFrame = StanceBarFrame
  else
      stanceFrame = StanceBar
  end
  
  stanceFrame:SetParent(frame)
  stanceFrame:EnableMouse(false)

  for i=1, num do
    local button = _G["StanceButton"..i]
    table.insert(buttonList, button) --add the button object to the list
    button:SetSize(cfg.buttons.size, cfg.buttons.size)
    button:ClearAllPoints()
    if i == 1 then
      button:SetPoint("BOTTOMLEFT", frame, cfg.padding, cfg.padding)
    else
      local previous = _G["StanceButton"..i-1]
      button:SetPoint("LEFT", previous, "RIGHT", cfg.buttons.margin, 0)
    end
  end

  --POSSESS BAR

  --move the buttons into position and reparent them
  --PossessBarFrame:SetParent(frame)
  --PossessBarFrame:EnableMouse(false)

--  for i=1, NUM_POSSESS_SLOTS do
--    local button = _G["PossessButton"..i]
--    table.insert(buttonList, button) --add the button object to the list
--    button:SetSize(cfg.buttons.size, cfg.buttons.size)
--    button:ClearAllPoints()
--    if i == 1 then
--      button:SetPoint("BOTTOMLEFT", frame, cfg.padding, cfg.padding)
--    else
--      local previous = _G["PossessButton"..i-1]
--      button:SetPoint("LEFT", previous, "RIGHT", cfg.buttons.margin, 0)
--    end
  --end

  if not cfg.show then --wait...you no see me? :(
    frame:SetParent(ns.pastebin)
    return
  end

  --show/hide the frame on a given state driver
  RegisterStateDriver(frame, "visibility", "[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists] hide; show")

  --create drag frame and drag functionality
  if cfg.userplaced.enable then
    rLib:CreateDragFrame(frame, dragFrameList, -2 , true) --frame, dragFrameList, inset, clamp
  end

  --create the mouseover functionality
  if cfg.mouseover.enable then
    rButtonBarFader(frame, buttonList, cfg.mouseover.fadeIn, cfg.mouseover.fadeOut) --frame, buttonList, fadeIn, fadeOut
  end
