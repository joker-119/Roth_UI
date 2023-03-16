
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg
  --get some values from the namespace
  local cfg = gcfg.bars.micromenu
  local dragFrameList = ns.dragFrameList

  -----------------------------
  -- FUNCTIONS
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
  if not cfg.enable then return end

  --micro menu button objects
  local MicroMenuButtons = {
    CharacterMicroButton,
    SpellbookMicroButton,
    TalentMicroButton,
    AchievementMicroButton,
    QuestLogMicroButton,
    GuildMicroButton,
    LFDMicroButton,
    CollectionsMicroButton,
    EJMicroButton,
    StoreMicroButton,
    MainMenuMicroButton,
  }

  local NUM_MICROBUTTONS = # MicroMenuButtons
  local buttonWidth = CharacterMicroButton:GetWidth()
  local buttonHeight = CharacterMicroButton:GetHeight()
  local gap = -3

  --create the frame to hold the buttons
  local frame = CreateFrame("Frame", "rABS_MicroMenu", UIParent, "SecureHandlerStateTemplate")
  frame:SetWidth(NUM_MICROBUTTONS*buttonWidth + (NUM_MICROBUTTONS-1)*gap + 2*cfg.padding)
  frame:SetHeight(buttonHeight + 2*cfg.padding)
  frame:ClearAllPoints();
  frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x,cfg.pos.y)
  frame:SetScale(cfg.scale)

  --move the buttons into position and reparent them
  for _, button in pairs(MicroMenuButtons) do
    button:SetParent(frame)
  end
  CharacterMicroButton:ClearAllPoints();
  CharacterMicroButton:SetPoint("LEFT", cfg.padding, 0)

  --disable reanchoring of the micro menu by the petbattle ui
  PetBattleFrame.BottomFrame.MicroButtonFrame:SetScript("OnShow", nil) --remove the onshow script
  MainMenuBar:ClearAllPoints();
  MainMenuBar:SetScript("OnShow", nil)
  

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
    rButtonBarFader(frame, MicroMenuButtons, cfg.mouseover.fadeIn, cfg.mouseover.fadeOut) --frame, buttonList, fadeIn, fadeOut
  end
