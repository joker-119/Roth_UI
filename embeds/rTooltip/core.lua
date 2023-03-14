
  ---------------------------------------------
  --  rTooltip
  ---------------------------------------------

  --  A simple tooltip mod
  --  Galaxy - 2016

  ---------------------------------------------
local addon, ns = ...
local cfg = ns.cfg
if not cfg.embeds.rTooltip then return end
cfg.rtooltip.backdrop = { bgFile = (mediapath.."Tooltip_Background"), edgeFile = (mediapath.."Tooltip_Border"),  tiled = false, edgeSize = 10, insets = {left=8, right=8, top=8, bottom=8} }
  
  ---------------------------------------------
  --  VARIABLES
  ---------------------------------------------

  local unpack, type = unpack, type
  local RAID_CLASS_COLORS = RAID_CLASS_COLORS
  local FACTION_BAR_COLORS = FACTION_BAR_COLORS
  local WorldFrame = WorldFrame
  local GameTooltip = GameTooltip
  local GameTooltipStatusBar = GameTooltipStatusBar

  ---------------------------------------------
  --  FUNCTIONS
  ---------------------------------------------

  --change some text sizes
  GameTooltipHeaderText:SetFont(cfg.font, 14, "THINOUTLINE")
  GameTooltipText:SetFont(cfg.font, 12, "THINOUTLINE")
  Tooltip_Small:SetFont(cfg.font, 11, "THINOUTLINE")

  --gametooltip statusbar
  GameTooltipStatusBar:ClearAllPoints()
  GameTooltipStatusBar:SetPoint("LEFT",5,0)
  GameTooltipStatusBar:SetPoint("RIGHT",-5,0)
  GameTooltipStatusBar:SetPoint("BOTTOM",GameTooltipStatusBar:GetParent(),"TOP",0,-6)
  GameTooltipStatusBar:SetHeight(3)
  --gametooltip statusbar bg
  GameTooltipStatusBar.bg = GameTooltipStatusBar:CreateTexture(nil,"BACKGROUND",nil,-8)
  GameTooltipStatusBar.bg:SetPoint("TOPLEFT",-1,1)
  GameTooltipStatusBar.bg:SetPoint("BOTTOMRIGHT",1,-1)
  GameTooltipStatusBar.bg:SetTexture(0,0,0)
  GameTooltipStatusBar.bg:SetVertexColor(0,0,0,0.7)

  --HookScript GameTooltip OnTooltipCleared
  GameTooltip:HookScript("OnTooltipCleared", function(self)
    GameTooltip_ClearStatusBars(self)
    --self:SetBackdropBorderColor(1,1,1,1)
  end)

  --hooksecurefunc GameTooltip_SetDefaultAnchor
  hooksecurefunc("GameTooltip_SetDefaultAnchor", function(tooltip, parent)
    if cfg.rtooltip.cursorfocus then
      tooltip:SetOwner(parent, "ANCHOR_CURSOR")
    else
      tooltip:SetOwner(parent, "ANCHOR_NONE")
      tooltip:ClearAllPoints()
      tooltip:SetPoint(unpack(cfg.rtooltip.pos))
    end
  end)

  --func AddSpellIdRow
  local function AddSpellIdRow(tooltip,spellid)
    tooltip:AddDoubleLine("|cff0099ffSpell ID|r",spellid)
    tooltip:Show()
  end

  -- ArtifactPowerIDs
hooksecurefunc(GameTooltip, "SetArtifactPowerByID", function(self, id)
    if id then 
    	local spellid = C_ArtifactUI.GetPowerInfo(id)
        if spellid then AddSpellIdRow(self,spellid) end
    end
end)
  --func AddBossDebuffRow
  local function AddBossDebuffRow(tooltip,isBossDebuff)
    tooltip:AddDoubleLine("|cff0099ffBossDebuff|r","Yes")
    tooltip:Show()
  end

  --hooksecurefunc GameTooltip SetUnitBuff
  hooksecurefunc(GameTooltip, "SetUnitBuff", function(self,...)
    local spellid = select(10,UnitBuff(...))
    if spellid then AddSpellIdRow(self,spellid) end
  end)

  --hooksecurefunc GameTooltip SetUnitDebuff
  hooksecurefunc(GameTooltip, "SetUnitDebuff", function(self,...)
    local spellid = select(10,UnitDebuff(...))
    if spellid then AddSpellIdRow(self,spellid) end
    local isBossDebuff = select(12,UnitDebuff(...))
    if isBossDebuff then AddBossDebuffRow(self,isBossDebuff) end
  end)

  --hooksecurefunc GameTooltip SetUnitAura
  hooksecurefunc(GameTooltip, "SetUnitAura", function(self,...)
    local spellid = select(10,UnitAura(...))
    if spellid then AddSpellIdRow(self,spellid) end
    local isBossDebuff = select(12,UnitAura(...))
    if isBossDebuff then AddBossDebuffRow(self,isBossDebuff) end
  end)

  --hooksecurefunc SetItemRef
  hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
    if string.find(link,"^spell:") then
      local spellid = string.sub(link,7)
      AddSpellIdRow(ItemRefTooltip,spellid)
    end
  end)

  --HookScript GameTooltip OnTooltipSetSpell
  hooksecurefunc("GameTooltip_OnUpdate", function(self, elapsed) 
    
  end)
  GameTooltip:HookScript("OnShow", function(self)
    local spellid = select(2,TooltipUtil.GetDisplayedSpell(self))
    if spellid then
      AddSpellIdRow(self,spellid)
    end
  end)

  --func GetHexColor
  local function GetHexColor(color)
    return ("%.2x%.2x%.2x"):format(color.r*255, color.g*255, color.b*255)
  end

  local classColors, reactionColors = {}, {}

  for class, color in pairs(RAID_CLASS_COLORS) do
    classColors[class] = GetHexColor(RAID_CLASS_COLORS[class])
  end

  for i = 1, #FACTION_BAR_COLORS do
    reactionColors[i] = GetHexColor(FACTION_BAR_COLORS[i])
  end

  local function GetTarget(unit)
    if UnitIsUnit(unit, "player") then
      return ("|cffff0000%s|r"):format("<YOU>")
    elseif UnitIsPlayer(unit, "player")then
      return ("|cff%s%s|r"):format(classColors[select(2, UnitClass(unit))], UnitName(unit))
    elseif UnitReaction(unit, "player") then
      return ("|cff%s%s|r"):format(reactionColors[UnitReaction(unit, "player")], UnitName(unit))
    else
      return ("|cffffffff%s|r"):format(UnitName(unit))
    end
  end

  --HookScript GameTooltip OnTooltipSetUnit
  GameTooltip:HookScript("OnShow", function(self,...)
    local unit = select(1, TooltipUtil.GetDisplayedUnit(self)) or (GetMouseFocus() and GetMouseFocus():GetAttribute("unit")) or (UnitExists("mouseover") and "mouseover")
    if not unit or (unit and type(unit) ~= "string") then return end
    if not UnitGUID(unit) then return end
    local ricon = GetRaidTargetIndex(unit)
    if ricon then
      local text = GameTooltipTextLeft1:GetText()
      GameTooltipTextLeft1:SetText(("%s %s"):format(ICON_LIST[ricon].."14|t", text))
    end
    for i = 2, GameTooltip:NumLines() do
      local line = _G["GameTooltipTextLeft"..i]
      if line then
        line:SetTextColor(0.5,0.5,0.5)
      end
    end
    if UnitIsPlayer(unit) then
      local _, unitClass = UnitClass(unit)
      local color = RAID_CLASS_COLORS[unitClass]
      GameTooltipStatusBar:SetStatusBarColor(color.r,color.g,color.b)
      GameTooltipTextLeft1:SetTextColor(color.r,color.g,color.b)
      if UnitIsAFK(unit) then
        self:AppendText(" |cff00cccc<AFK>|r")
      elseif UnitIsDND(unit) then
        self:AppendText(" |cffcc0000<DND>|r")
      end
      local unitGuild = GetGuildInfo(unit)
      local text = GameTooltipTextLeft2:GetText()
      if unitGuild and text and text:find("^"..unitGuild) then
        GameTooltipTextLeft2:SetText("<"..text..">")
        GameTooltipTextLeft2:SetTextColor(255/255, 20/255, 200/255)
      end
    else
      local reaction = UnitReaction(unit, "player")
      if reaction then
        local color = FACTION_BAR_COLORS[reaction]
        if color then
          GameTooltipStatusBar:SetStatusBarColor(color.r,color.g,color.b)
          GameTooltipTextLeft1:SetTextColor(color.r,color.g,color.b)
        end
      end

      local unitClassification = UnitClassification(unit)
      if unitClassification == "worldboss" or UnitLevel(unit) == -1 then
        if UnitReaction(unit, "player") == 2 then
          --highlight bosses
          GameTooltipTextLeft1:SetTextColor(1,0.1,0)
        end
        self:AppendText(" |TInterface\\TargetingFrame\\UI-TargetingFrame-Skull:14:14|t")
      elseif unitClassification == "rare" then
        self:AppendText(" |TInterface\\AddOns\\Roth_UI\\media\\diablo:14:14:0:0:16:16:0:15:0:14|t")
      elseif unitClassification == "rareelite" then
        self:AppendText(" |TInterface\\AddOns\\Roth_UI\\media\\diablo:14:14:0:0:16:16:0:15:0:14|t")
      elseif unitClassification == "elite" then
        self:AppendText(" |TInterface\\AddOns\\Roth_UI\\media\\plus:14:14|t")
      end

    end

    if UnitIsGhost(unit) then
      self:AppendText(" |cffaaaaaa<GHOST>|r")
      GameTooltipTextLeft1:SetTextColor(0.5,0.5,0.5)
    elseif UnitIsDead(unit) then
      self:AppendText(" |cffaaaaaa<DEAD>|r")
      GameTooltipTextLeft1:SetTextColor(0.5,0.5,0.5)
    end

    if (UnitExists(unit.."target")) then
      GameTooltip:AddDoubleLine("|cffff9999Target|r",GetTarget(unit.."target") or "Unknown")
      --GameTooltip:Show()
    end

  end)

  --func TooltipOnShow
  local function TooltipOnShow(self,...)
    --self:SetBackdropColor(1,1,1,1)
    --self:SetBackdropBorderColor(1,1,1,1)
    local itemName, itemLink = self:GetItem()
    if itemLink then
      local itemRarity = select(3,GetItemInfo(itemLink))
      if itemRarity then
        -- GameTooltip:SetBackdropColor(unpack({GetItemQualityColor(itemRarity)}))
      end
    end
  end
  
  --func TooltipOnShow
  local function TooltipOnHide(self,...)
    --self:SetBackdropColor(1,1,1,1)
    --self:SetBackdropBorderColor(1,1,1,1)
  end

  --loop over tooltips
  local tooltips = { GameTooltip, ItemRefTooltip, ShoppingTooltip1, ShoppingTooltip2, ShoppingTooltip3, WorldMapTooltip, }
  for idx, tooltip in ipairs(tooltips) do
    --tooltip:SetBackdrop(cfg.rtooltip.backdrop)
    tooltip:SetScale(cfg.rtooltip.scale)
    tooltip:HookScript("OnShow", TooltipOnShow)
    tooltip:HookScript("OnHide", TooltipOnHide)
  end

  --loop over menues
  local menues = {
    DropDownList1MenuBackdrop,
    DropDownList2MenuBackdrop,
  }
  for idx, menu in ipairs(menues) do
    menu:SetScale(cfg.rtooltip.scale)
  end
