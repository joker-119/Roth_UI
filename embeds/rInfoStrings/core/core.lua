-----------------------------------------
-- Variables
-----------------------------------------
local A, L = ...
L.addonName        = A
L.dragFrames       = {}
LaddonColor        = "0000FF00"
L.addonShortcut    = "ris"

  --get the addon namespace
  local addon, ns = ...
  local cfg
  local dragFrameList = ns.dragFrameList
  local LSM = LibStub("LibSharedMedia-3.0")
  local f1, f2, f3, f4
  local showServerTime = true
  
local function rsiCreateFontString(f,size)
      local t = f:CreateFontString(nil, "BACKGROUND")
      local font = ns.Media.Font(ns.cfg.fonts.textFont)
      t:SetFont(font, size, "THINOUTLINE")
      t:SetPoint("CENTER", f)
      return t
    end

local function rsiClearGarbage()
    UpdateAddOnMemoryUsage()
    local before = gcinfo()
    collectgarbage()
    UpdateAddOnMemoryUsage()
    local after = gcinfo()
    print("Cleaned: "..ns.Format.memformat(before-after))
  end
  
    local addoncompare = function(a, b)
      	return a.memory > b.memory
      end
      local addonlist = 50
      
    --tooltip function from Lyn
    local function rsiShowMemTooltip(self)
      local color = { r=156/255, g=144/255, b=125/255 }
      GameTooltip:SetOwner(self, "ANCHOR_NONE")
      GameTooltip:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -90, 90)
      local blizz = collectgarbage("count")
      local addons = {}
      local enry, memory
      local total = 0
      local nr = 0
      UpdateAddOnMemoryUsage()
      GameTooltip:AddLine("Top "..addonlist.." AddOns", color.r, color.g, color.b)
      GameTooltip:AddLine(" ")
      for i=1, C_AddOns.GetNumAddOns(), 1 do
        if (GetAddOnMemoryUsage(i) > 0 ) then
          memory = GetAddOnMemoryUsage(i)
          entry = {name = C_AddOns.GetAddOnInfo(i), memory = memory}
          table.insert(addons, entry)
          total = total + memory
        end
      end
      table.sort(addons, addoncompare)
      for _, entry in pairs(addons) do
        if nr < addonlist then
          GameTooltip:AddDoubleLine(entry.name, ns.Format.memformat(entry.memory), 1, 1, 1, 1, 1, 1)
          nr = nr+1
        end
      end
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine("Total", ns.Format.memformat(total), color.r, color.g, color.b, color.r, color.g, color.b)
      GameTooltip:AddDoubleLine("Total incl. Blizzard", ns.Format.memformat(blizz), color.r, color.g, color.b, color.r, color.g, color.b)
      GameTooltip:Show()
    end
    
    local function rsiExpRep()
      local xp = " "
  
      if not IsXPUserDisabled() and (UnitLevel("player")<80) then
        xp = "|c00FA58F4"..ns.Format.numformat(UnitXP("player")).."/"..ns.Format.numformat(UnitXPMax("player")).." |r|c00ffb400("..ns.Format.numformat(GetXPExhaustion() or 0)..")|r|c00FA58F4 | "..string.format("%.0f", (UnitXP("player")/UnitXPMax("player")*100)).."%|r"
      else
        local _, _, minimum, maximum, value = ns.Reputation.GetFactionData()
        if (value==0) or (maximum==0) then return end
        if ((value-minimum)==999) and ((maximum-minimum)==1000) then
          xp = "|c0000FF00MAXED OUT|r"
        else
          xp = "|c0000FF00"..ns.Format.numformat(value-minimum).."/"..ns.Format.numformat(maximum-minimum).." | "..string.format("%.0f", (value-minimum)/(maximum-minimum)*100).."%|r"
        end
      end
      return xp
    end
  
    local function rsiFPS()
      return floor(GetFramerate()).."fps"
    end
  
    local function rsiLatency()
      return select(3, GetNetStats()) .. "/" .. select(4, GetNetStats()) .."ms"
    end
    
    local function rsiPad2(n)
        return (n < 10) and ("0"..n) or tostring(n)
    end
    
    local function rsiServerTime()
        local h, m = GetGameTime()
        return rsiPad2(h) .. ":" .. rsiPad2(m)
    end
    
    local function rsiLocalTime()
        local t = date("*t")
        return rsiPad2(t.hour) .. ":" .. rsiPad2(t.min)
    end
  
    local function rsiTimeText()
        local st = rsiServerTime()
        local lt = rsiLocalTime()
        
        if showServerTime then
            return "|c009C907DTime: |r|c00C9BCA8"..st.."|r|c009C907D (Server)|r"
        else
            return "|c009C907DTime: |r|c00C9BCA8"..lt.."|r|c009C907D (Local)|r"
        end 
    end
    
    local function rsiMemory()
      local t = 0
      UpdateAddOnMemoryUsage()
      for i=1, GetNumAddOns(), 1 do
        t = t + GetAddOnMemoryUsage(i)
      end
      return ns.Format.memformat(t)
    end
  
  
    local function rsiZoneCoords()
      local zone = ""
      local x, y
  	local mapID = C_Map.GetBestMapForUnit("player")
  	if mapID then
  		local mapPosObject = C_Map.GetPlayerMapPosition(mapID, "player")
  		if mapPosObject then
  			x, y = mapPosObject:GetXY()
  		end
  	end
  	local coords
      if x and y and x ~= 0 and y ~= 0 then
        coords = format("%.2d/%.2d",x*100,y*100)
      end
      if coords then
        zone = "|c00E8B444"..GetMinimapZoneText().." |c009C907D[|c00C9BCA8"..coords.."|c009C907D]|r"
      else
        zone = "|c00E8B444"..GetMinimapZoneText().."|r"
      end
      return zone
    end
  
    local function rsiMail()
      local mail = HasNewMail()
      local mailtext = ""
      if mail then
        mailtext = "|c00FF78F1(New Mail!)|r"
      end
      return mailtext
    end
  
    local function rsiUpdateStrings()
  
      if f1 then     
        f1.text:SetText(rsiZoneCoords())
        f1:SetHeight(f1.text:GetStringHeight())
        f1:SetWidth(f1.text:GetStringWidth())
    end
  
    if f2 then
      f2.text:SetText("|c009C907D"..rsiLatency().." "..rsiFPS().."|r")
      f2:SetHeight(f2.text:GetStringHeight())
      f2:SetWidth(f2.text:GetStringWidth())
    end
  
      local f3Text = ""
      if cfg.showMail and cfg.showXpRep then
        f3Text = rsiMail() or "".." "..rsiExpRep() or ""
      elseif cfg.showMail then
        f3Text = rsiMail()
      elseif cfg.showXpRep then
        f3Text = rsiExpRep()
      end
      
      if f3 then
        f3.text:SetText(f3Text or "")
        f3:SetHeight(f3.text:GetStringHeight())
        f3:SetWidth(f3.text:GetStringWidth())
    end
    
    if f4 and cfg.showTime then
        f4.text:SetText(rsiTimeText())
        f4:SetHeight(f4.text:GetStringHeight())
        f4:SetWidth(f4.text:GetStringWidth())  
    end
end
  
    local startSearch = function(self)
      --timer
      local ag = self:CreateAnimationGroup()
      ag.anim = ag:CreateAnimation()
      ag.anim:SetDuration(1)
      ag:SetLooping("REPEAT")
      ag:SetScript("OnLoop", function(self, event, ...)
        rsiUpdateStrings()
      end)
      ag:Play()
    end
    
local function Disable()
    if f1 ~= nil then
        f1:Hide()
        f1:SetParent(nil)
        f1 = nil
    end
    if f2 ~= nil then
        f2:Hide()
        f2:SetParent(nil)
        f2 = nil
    end
    if f3 ~= nil then
        f3:Hide()
        f3:SetParent(nil)
        f3 = nil
    end
    if f4 ~= nil then
        f4:Hide()
        f4:SetParent(nil)
        f4 = nil
    end
end

local function Init()
  ---------------------------------------
  -- FUNCTIONS
  ---------------------------------------
cfg = ns.cfg.embeds.rInfoStrings
if not cfg.enabled then
    Disable()
    return 
end


  --petbattle handler
  local petbattleHandler = CreateFrame("Frame",nil,UIParent)
  petbattleHandler:RegisterEvent("PET_BATTLE_OPENING_START")
  petbattleHandler:RegisterEvent("PET_BATTLE_CLOSE")
  --event
  petbattleHandler:SetScript("OnEvent", function(...)
    local self, event, arg1 = ...
    if event == "PET_BATTLE_OPENING_START" then
      self:Hide()
    elseif event == "PET_BATTLE_CLOSE" then
      self:Show()
    end
  end)

  local frame = CreateFrame("Frame", "riS_DragFrame", petbattleHandler)
  frame:SetSize(50,50)
  frame:SetScale(cfg.scale)
  frame:SetPoint(cfg.pos.a1,cfg.pos.af,cfg.pos.a2,cfg.pos.x,cfg.pos.y)

  f1 = CreateFrame("Frame", "rInfoStringsContainer1", frame)
  f2 = CreateFrame("Frame", "rInfoStringsContainer2", frame)
  f3 = CreateFrame("Frame", "rInfoStringsContainer3", frame)
  f4 = CreateFrame("Frame", "rInfoStringsContainer4", frame)

  f1:SetPoint("TOP", frame, 0, 0)
  f2:SetPoint("TOP", f1, "BOTTOM", 0, -3)
  f3:SetPoint("TOP", f4, "BOTTOM", 0, -3)
  f4:SetPoint("TOP", f2, "BOTTOM", 0, -3)

  f1.text = rsiCreateFontString(f1,11)
  f2.text = rsiCreateFontString(f2,11)
  f3.text = rsiCreateFontString(f3,11)
  f4.text = rsiCreateFontString(f4, 11)

  f2:EnableMouse(true)
  f2:SetScript("OnMouseDown", function()
    rsiClearGarbage()
  end)
  f2:SetScript("OnEnter", function() rsiShowMemTooltip(f2) end)
  f2:SetScript("OnLeave", function() GameTooltip:Hide() end)
  
  f4:EnableMouse(true)
  f4:SetScript("OnMouseDown", function()
    showServerTime = not showServerTime
    rsiUpdateStrings()
  end)

	rLib:CreateDragFrame(frame, L.dragFrames, -2, true)
	rLib:CreateSlashCmd(L.addonName, L.addonShortcut, L.dragFrames, L.addonColor)
    local a = CreateFrame("Frame")
	a:RegisterEvent("PLAYER_ENTERING_WORLD")
	a:SetScript("OnEvent", function(self,event,...)
	  	if event == "PLAYER_ENTERING_WORLD" then
	  		startSearch(self)
	  	end
	end)
end

  -- Create slash commands (hopefully this works?)  IT DOES, but this frame is anchored to minimap so no need

Roth_UI:AddConfig("embeds.rInfoStrings", {}, "Info Strings", Init, true)

Roth_UI:RegisterInit(Init)