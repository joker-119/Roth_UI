
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg
  --get some values from the namespace
  local cfg = gcfg.bars.bar1
  local dragFrameList = ns.dragFrameList

  -----------------------------
  -- FUNCTIONS
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
  if not cfg.enable then return end

  local num = NUM_ACTIONBAR_BUTTONS
  local buttonList = {}

  --create the frame to hold the buttons
  local frame = CreateFrame("Frame", "rAbs_MainMenuBar", UIParent, "SecureHandlerStateTemplate")
  if cfg.uselayout2x6 then
    frame:SetWidth(cfg.buttons.size*num/2 + (num/2-1)*cfg.buttons.margin + 2*cfg.padding)
    frame:SetHeight(cfg.buttons.size*num/6 + (num/6-1)*cfg.buttons.margin + 2*cfg.padding)
  else
    frame:SetWidth(num*cfg.buttons.size + (num-1)*cfg.buttons.margin + 2*cfg.padding)
    frame:SetHeight(cfg.buttons.size + 2*cfg.padding)
  end
  if cfg.uselayout2x6 then
    local cfg = gcfg.bars.bar1
    frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x+((cfg.buttons.size*num/2+cfg.buttons.margin*num/2)/2),cfg.pos.y)
  else
    frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x,cfg.pos.y)
  end
  frame:SetScale(cfg.scale)

  --move the buttons into position and reparent them
  MainMenuBar:SetParent(frame)
  MainMenuBar:EnableMouse(false)
  --MainMenuBar.Background.TopEdge:Hide()
  --MainMenuBar.BorderArt.Center:Hide()
  --MainMenuBar.Background.BottomEdge:Hide()
  --MainMenuBar.BorderArt.TopEdge:Hide()
  --MainMenuBar.BorderArt.BottomEdge:Hide()
  --MainMenuBar.BorderArt.TopRightCorner:Hide()
  --MainMenuBar.BorderArt.BottomRightCorner:Hide()
  --MainMenuBar.BorderArt.TopLeftCorner:Hide()
  --MainMenuBar.BorderArt.BottomLeftCorner:Hide()
  --MainMenuBar.ActionBarPageNumber.Text:Hide()
  --MainMenuBar.ActionBarPageNumber.DownButton:Hide()
  --MainMenuBar.ActionBarPageNumber.UpButton:Hide()
  MainMenuBar.EndCaps:Hide()
  MainMenuBar.BorderArt:Hide()

  for i=1, num do
    local button = _G["ActionButton"..i]
    table.insert(buttonList, button) --add the button object to the list
    button:SetSize(cfg.buttons.size, cfg.buttons.size)
    button:ClearAllPoints()
    if i == 1 then
      button:SetPoint("BOTTOMLEFT", frame, cfg.padding, cfg.padding)
    else
      local previous = _G["ActionButton"..i-1]
      if cfg.uselayout2x6 and i == (num/2+1) then
        previous = _G["ActionButton"]
        button:SetPoint("BOTTOM", previous, "TOP", 0, cfg.buttons.margin)
      else
        button:SetPoint("LEFT", previous, "RIGHT", cfg.buttons.margin, 0)
      end
    end
  end

  --show/hide the frame on a given state driver
  function updatestate()
    RegisterStateDriver(frame, "visibility", "[petbattle][overridebar][vehicleui][possessbar,@vehicle,exists] hide; show")
  end

  --create drag frame and drag functionality
  if cfg.userplaced.enable then
    rLib:CreateDragFrame(frame, dragFrameList, -2 , true) --frame, dragFrameList, inset, clamp
  end

  --create the mouseover functionality
  if cfg.mouseover.enable then
    rButtonBarFader(frame, buttonList, cfg.mouseover.fadeIn, cfg.mouseover.fadeOut) --frame, buttonList, fadeIn, fadeOut
    frame.mouseover = cfg.mouseover
  end


  local helper = CreateFrame("Frame") --this is needed...adding player_login to the visivility events does not do anything
  helper:RegisterEvent("UNIT_EXITED_VEHICLE")
  helper:RegisterEvent("PLAYER_LOGIN")
  helper:SetScript("OnEvent", function() updatestate(self) end)