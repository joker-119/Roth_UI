
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

  local num = 10
  local NUM_POSSESS_SLOTS = 10
  local buttonList = {}

  --make a frame that fits the size of all microbuttons
  local frame = CreateFrame("Frame", "rABS_StanceBar", UIParent, "SecureHandlerStateTemplate")
  frame:SetWidth(num*cfg.buttons.size + (num-1)*cfg.buttons.margin + 2*cfg.padding)
  frame:SetHeight(cfg.buttons.size + 2*cfg.padding)
  frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x,cfg.pos.y)
  frame:SetScale(cfg.scale)

  --STANCE BAR

  --move the buttons into position and reparent them
  StanceBar:SetParent(frame)
  StanceBar:EnableMouse(false)

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
