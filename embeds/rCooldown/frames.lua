-- Roth_UI/embeds/rCooldown/frames.lua
-- Renderer for rCooldown (dynamic overflow pool, countdown text)
-- Supports layoutMode:
--  - static: fixed positions by slot index (holes allowed)
--  - dynamic: first-come first-shown packing (no holes)

local addon, ns = ...
local RC = ns.rCooldown
if not RC then return end

local Model = RC.Model

RC.Frames = RC.Frames or {}
local Frames = RC.Frames

Frames._icons = Frames._icons or {}

local function GetGlobal()
  local cfg = RC:GetCfg()
  return cfg and cfg.global or nil
end

local function GetPlayerClass()
  local _, class = UnitClass("player")
  return class or "UNKNOWN"
end

-- ------------------------------------------------------------
-- Formatting
-- ------------------------------------------------------------
local function FormatTime(t)
  if not t or t <= 0 then return "" end
  if t < 60 then
    return tostring(math.floor(t + 0.5))
  end
  local m = math.floor(t / 60)
  local s = math.floor(t % 60)
  if s < 10 then
    return tostring(m) .. ":0" .. tostring(s)
  end
  return tostring(m) .. ":" .. tostring(s)
end

-- ------------------------------------------------------------
-- Icon pool
-- ------------------------------------------------------------
local function CreateIcon(parent, size)
  local f = CreateFrame("Frame", nil, parent)
  f:SetSize(size, size)

  f.icon = f:CreateTexture(nil, "ARTWORK")
  -- don't SetAllPoints; skin will inset + crop
  ns.SkinIconMinimal(f, f.icon, { inset = 2, bgAlpha = 0.55, crop = 0.07 })

  f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
  f.cooldown:SetAllPoints()

  f.text = f:CreateFontString(nil, "OVERLAY")
  f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
  f.text:SetJustifyH("CENTER")
  f.text:SetJustifyV("MIDDLE")
  f.text:SetFont(ns.Media.Font(ns.db.profile.textFont), 12)
  f.text:SetText("")

  -- Reminder glow (red, static) using Roth glow texture
  f.reminderBorder = f._rothGlow
  f.reminderBorder:SetVertexColor(1, 0.1, 0.1, 1)
  f.reminderBorder:SetAlpha(0.9)
  f.reminderBorder:Hide()

  -- Ready glow (gold, animated flash) - separate instance
  f.readyBorder = f:CreateTexture(nil, "ARTWORK", nil, 4)
  local pad = math.max(3, math.floor(size * 0.12 + 0.5))
  f.readyBorder:ClearAllPoints()
  f.readyBorder:SetPoint("TOPLEFT", f, "TOPLEFT", -pad, pad)
  f.readyBorder:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", pad, -pad)
  f.readyBorder:SetTexture("Interface\\AddOns\\Roth_UI\\media\\simplesquare_glow")
  f.readyBorder:SetBlendMode("ADD")
  f.readyBorder:SetAlpha(0.25)
  f.readyBorder:SetVertexColor(1.0, 0.72, 0.18, 1)
  f.readyBorder:Hide()

  f.readyFlash = f.readyBorder:CreateAnimationGroup()
  f.readyFlash:SetLooping("REPEAT")

  local a1 = f.readyFlash:CreateAnimation("Alpha")
  a1:SetOrder(1)
  a1:SetFromAlpha(0.15)
  a1:SetToAlpha(1.00)
  a1:SetDuration(0.22)
  a1:SetSmoothing("OUT")

  local a2 = f.readyFlash:CreateAnimation("Alpha")
  a2:SetOrder(2)
  a2:SetFromAlpha(1.00)
  a2:SetToAlpha(0.15)
  a2:SetDuration(0.38)
  a2:SetSmoothing("IN")

  local s1 = f.readyFlash:CreateAnimation("Scale")
  s1:SetOrder(1)
  s1:SetScale(1.06, 1.06)
  s1:SetDuration(0.22)
  s1:SetSmoothing("OUT")

  local s2 = f.readyFlash:CreateAnimation("Scale")
  s2:SetOrder(2)
  s2:SetScale(0.9434, 0.9434)
  s2:SetDuration(0.38)
  s2:SetSmoothing("IN")

  f.readyFlash:SetScript("OnPlay", function()
    f.readyBorder:Show()
  end)
  f.readyFlash:SetScript("OnStop", function()
    f.readyBorder:SetAlpha(0.0)
    f.readyBorder:Hide()
  end)

  f:Hide()
  return f
end

function Frames:AcquireIcon(index)
  if self._icons[index] then
    return self._icons[index]
  end

  local g = GetGlobal()
  local size = (g and g.iconSize) or 36

  local icon = CreateIcon(self.parent, size)
  self._icons[index] = icon
  return icon
end

-- ------------------------------------------------------------
-- Layout
-- ------------------------------------------------------------
local function PlaceIcon(icon, index, iconSize, spacing, bar1Cap, bar2Cap)
  local row, col
  if index <= bar1Cap then
    row = 1
    col = index
  elseif index <= (bar1Cap + bar2Cap) then
    row = 2
    col = index - bar1Cap
  else
    row = 3
    col = index - (bar1Cap + bar2Cap)
  end

  icon:ClearAllPoints()
  icon:SetPoint(
    "TOPLEFT",
    icon:GetParent(),
    "TOPLEFT",
    (col - 1) * (iconSize + spacing),
    -(row - 1) * (iconSize + spacing)
  )
end

-- ------------------------------------------------------------
-- Init
-- ------------------------------------------------------------
function Frames:Init()
  local g = GetGlobal()
  if not g then return end

  self.parent = RC.frame

  self.iconSize = (g.iconSize) or 36
  self.spacing = (g.iconSpacing) or 6

  local fontPath = nil
  if ns.LSM and ns.LSM.Fetch then
    fontPath = ns.LSM:Fetch("font", "RothFont")
  end
  if not fontPath then
    fontPath = STANDARD_TEXT_FONT
  end

  self.fontPath = fontPath
  self.fontSize = (g.fontSize) or 14
  self.fontFlags = "OUTLINE"

  self:AcquireIcon(1)
  self._icons[1].text:SetFont(self.fontPath, self.fontSize, self.fontFlags)
  self._icons[1]._fontSet = true

  local width = (6 * self.iconSize) + (5 * self.spacing)
  local height = (3 * self.iconSize) + (2 * self.spacing)
  self.parent:SetSize(width, height)
end

-- ------------------------------------------------------------
-- Render
-- ------------------------------------------------------------
local function ResetIcon(icon)
  icon.reminderBorder:Hide()
  if icon.readyFlash:IsPlaying() then icon.readyFlash:Stop() end
  icon.readyBorder:Hide()
  icon.text:SetText("")
end

local function RenderSlotToIcon(slot, icon)
  -- texture
  if slot.entry.type == "spell" then
    icon.icon:SetTexture(GetSpellTexture(slot.entry.id))
  elseif slot.entry.type == "item" then
    icon.icon:SetTexture(GetItemIcon(slot.entry.id))
  end

  -- cooldown swipe
  if slot.cdDuration and slot.cdDuration > 0 and slot.cdStart and slot.cdStart > 0 then
    icon.cooldown:SetCooldown(slot.cdStart, slot.cdDuration)
  else
    icon.cooldown:Clear()
  end

  -- countdown text only while on cooldown
  if slot.onCD and slot.remaining and slot.remaining > 0 then
    icon.text:SetText(FormatTime(slot.remaining))
  else
    icon.text:SetText("")
  end

  -- state visuals (set color every render; avoids pooled icons going white)
  if slot.state == "REMINDER" then
    icon.reminderBorder:SetVertexColor(1, 0.1, 0.1, 1)
    icon.reminderBorder:SetAlpha(0.9)
    icon.reminderBorder:Show()

  elseif slot.state == "READYFLASH" then
    icon.readyBorder:SetVertexColor(1, 0.82, 0.12, 1)
    -- Alpha is driven by the animation, but ensure it's not stuck at 0 from prior stop
    icon.readyBorder:SetAlpha(0.15)
    icon.readyBorder:Show()
    icon.readyFlash:Play()
  end
end

function Frames:Refresh()
  local g = GetGlobal()
  if not g then return end

  self.iconSize = (g.iconSize) or self.iconSize or 36
  self.spacing = (g.iconSpacing) or self.spacing or 6
  self.fontSize = (g.fontSize) or self.fontSize or 14

  local layoutMode = g.layoutMode or "static"

  local class = GetPlayerClass()
  local slots = Model:GetSlotsForClass(class)
  if not slots then
    for i = 1, #self._icons do
      local ic = self._icons[i]
      ResetIcon(ic)
      ic:Hide()
    end
    return
  end

  local bar1Cap = tonumber(g.bar1Cap) or 6
  local bar2Cap = tonumber(g.bar2Cap) or 6
  local iconSize = self.iconSize
  local spacing = self.spacing

  -- Build render list based on layout mode
  local renderSlots = nil
  local renderCount = 0

  if layoutMode == "dynamic" then
    renderSlots = {}
    for i = 1, #slots do
      local s = slots[i]
      if s and s.visible and s.state ~= "HIDDEN" then
        renderCount = renderCount + 1
        renderSlots[renderCount] = s
      end
    end
  else
    -- static
    renderSlots = slots
    renderCount = #slots
  end

  -- Ensure pool size matches renderCount
  for i = 1, renderCount do
    local icon = self:AcquireIcon(i)
    if icon.text and not icon._fontSet then
      icon.text:SetFont(self.fontPath or STANDARD_TEXT_FONT, self.fontSize or 14, self.fontFlags or "OUTLINE")
      icon._fontSet = true
    end
    PlaceIcon(icon, i, iconSize, spacing, bar1Cap, bar2Cap)
  end

  -- Hide extra icons from previous state
  for i = renderCount + 1, #self._icons do
    local icon = self._icons[i]
    if icon then
      ResetIcon(icon)
      icon:Hide()
    end
  end

  -- Render
  if layoutMode == "dynamic" then
    for i = 1, renderCount do
      local slot = renderSlots[i]
      local icon = self._icons[i]
      ResetIcon(icon)
      icon:Show()
      RenderSlotToIcon(slot, icon)
    end
  else
    -- static: holes allowed
    for i = 1, renderCount do
      local slot = renderSlots[i]
      local icon = self._icons[i]
      ResetIcon(icon)

      if slot and slot.visible and slot.state ~= "HIDDEN" then
        icon:Show()
        RenderSlotToIcon(slot, icon)
      else
        icon:Hide()
      end
    end
  end

  -- Resize parent
  local usedCount = (layoutMode == "dynamic") and renderCount or #slots

  local overflowCount = 0
  if usedCount > (bar1Cap + bar2Cap) then
    overflowCount = usedCount - (bar1Cap + bar2Cap)
  end

  local maxCols = bar1Cap
  if bar2Cap > maxCols then maxCols = bar2Cap end
  if overflowCount > maxCols then maxCols = overflowCount end
  if maxCols < 1 then maxCols = 1 end

  local width = (maxCols * iconSize) + ((maxCols - 1) * spacing)
  local height = (3 * iconSize) + (2 * spacing)
  self.parent:SetSize(width, height)
end