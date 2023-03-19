  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg
  --get some values from the namespace
  local cfg = gcfg.bars.bags
  local dragFrameList = ns.dragFrameList

  -----------------------------
  -- FUNCTIONS
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
if not cfg.enable then return end

  --micro menu button objects
  local BAG_BUTTONS = {
    'MainMenuBarBackpackButton',
    'CharacterBag0Slot',
    'CharacterBag1Slot',
    'CharacterBag2Slot',
    'CharacterBag3Slot',
    'CharacterReagentBag0Slot'
  }
  local buttonList = {}

  --check the buttons in the BAG_BUTTONS table
  for _, buttonName in pairs(BAG_BUTTONS) do
    local button = _G[buttonName]
    if button then
      --if not button:IsShown() then print(buttonName.." is not shown") end
      tinsert(buttonList, button)
    end
  end

  local NUM_BAG_BUTTONS = # buttonList
  local buttonWidth = MainMenuBarBackpackButton:GetWidth()
  local buttonHeight = MainMenuBarBackpackButton:GetHeight()
  local gap = -3

  --create the frame to hold the buttons
  local frame = CreateFrame("Frame", "rABS_BagFrame", UIParent, "SecureHandlerStateTemplate")
  frame:SetWidth(NUM_BAG_BUTTONS*buttonWidth + (NUM_BAG_BUTTONS-1)*gap + 2*cfg.padding)
  frame:SetHeight(buttonHeight + 2*cfg.padding)
  frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x,cfg.pos.y)
  frame:SetScale(cfg.scale)

  --move the buttons into position and reparent them
  local count = 1
  for _, button in pairs(buttonList) do
    button:SetParent(frame)
    button:ClearAllPoints();
    button:SetPoint("LEFT", (buttonWidth + cfg.padding) * count, 0)
    count = count + 1
  end
  MainMenuBarBackpackButton:ClearAllPoints();
  MainMenuBarBackpackButton:SetPoint("RIGHT", -cfg.padding, 0)

  if not cfg.show then --wait...you no see me? :(
    frame:SetParent(ns.pastebin)
    return
  end

  --show/hide the frame on a given state driver
  RegisterStateDriver(frame, "visibility", "[petbattle] hide; show")

  --create drag frame and drag functionality
  if cfg.userplaced.enable then
    rLib:CreateDragFrame(frame, dragFrameList, -2 , false) --frame, dragFrameList, inset, clamp
  end

  --create the mouseover functionality
  if cfg.mouseover.enable then
    rButtonBarFader(frame, buttonList, cfg.mouseover.fadeIn, cfg.mouseover.fadeOut) --frame, buttonList, fadeIn, fadeOut
  end
