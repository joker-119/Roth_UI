
  -----------------------------
  -- INIT
  -----------------------------

  --get the addon namespace
  local addon, ns = ...
  local gcfg = ns.cfg

  -----------------------------
  -- FUNCTIONS
  -----------------------------
if not gcfg.embeds.rActionBarStyler then return end
  --cooldown spiral alpha fix

  --SetCooldownSwipeAlpha
  local function SetCooldownSwipeAlpha(self,cooldown,alpha)
    cooldown:SetSwipeColor(0,0,0,0.8*alpha)
  end
   
  --ApplyButtonCooldownAlphaFix
  local function ApplyButtonCooldownAlphaFix(button)
    if not button then return end
    if not button.cooldown then return end
    local parent = button:GetParent():GetParent()
    hooksecurefunc(parent, "SetAlpha", function(self,alpha) SetCooldownSwipeAlpha(self,button.cooldown,alpha) end)
  end
   
  do
    --style the actionbar buttons
    for i = 1, NUM_ACTIONBAR_BUTTONS do
      ApplyButtonCooldownAlphaFix(_G["ActionButton"..i])
      ApplyButtonCooldownAlphaFix(_G["MultiBarBottomLeftButton"..i])
      ApplyButtonCooldownAlphaFix(_G["MultiBarBottomRightButton"..i])
      ApplyButtonCooldownAlphaFix(_G["MultiBarRightButton"..i])
      ApplyButtonCooldownAlphaFix(_G["MultiBarLeftButton"..i])
    end
    --override buttons
    for i = 1, 6 do
      ApplyButtonCooldownAlphaFix(_G["OverrideActionBarButton"..i])
    end
    --petbar buttons
    for i=1, NUM_PET_ACTION_SLOTS do
      ApplyButtonCooldownAlphaFix(_G["PetActionButton"..i])
    end
    --stancebar buttons
    for i=1, 10 do
      ApplyButtonCooldownAlphaFix(_G["StanceButton"..i])
    end
  end
