
  ---------------------------------------------
  --  Roth_UI - slashcmd
  ---------------------------------------------

  -- The slashcmd stuff

  --get the addon namespace
  local addon, ns = ...

  ---------------------------------------------
  --FUNCTIONS
  ---------------------------------------------

  Roth_UI_Bars = {
    "Roth_UIExpBar",
    "Roth_UIRepBar",
    "Roth_UISoulShardPower",
    "Roth_UIBurningEmberPower",
    "Roth_UIHolyPower",
    "Roth_UIHarmonyPower",
    "Roth_UIShadowOrbPower",
    "Roth_UIEclipsePower",
    "Roth_UIRuneBar",
    "Roth_UIComboPoints",
	"Roth_UIArcanePower",
	"Roth_DruidMana",
	"Roth_UIArtifactPower",
	"Roth_UIStateStrip",
	"RothUI_rCooldownFrame",
	"Roth_UISwingTimer"
  }
  Roth_UI_Orbs = {
  "Roth_UIPowerOrb",
  "Roth_UIPlayerFrame",
  }

  Roth_UI_Units = {
    "Roth_UITargetFrame",
    "Roth_UITargetTargetFrame",
    "Roth_UIPetTargetFrame",
    "Roth_UIPetFrame",
    "Roth_UIFocusTargetFrame",
    "Roth_UIFocusFrame",
  }

  Roth_UI_Art = {
    "Roth_UIActionBarBackground",
    "Roth_UIAngelFrame",
    "Roth_UIDemonFrame",
    "Roth_UIBottomLine",
    "Roth_UIPlayerPortrait",
    "Roth_UITargetPortrait",
  }

  function Roth_UIUnlock(c)
    print("Roth_UI: "..c.." unlocked")
    local a
    if c == "art" then
      a = Roth_UI_Art
    elseif c == "bars" then
      a = Roth_UI_Bars
    elseif c == "units" then
      a = Roth_UI_Units
	elseif c == "orbs" then
	  a = Roth_UI_Orbs
    elseif c == "all" then
      a = Roth_UI_Bars
      a = Roth_UI_Units
      a = Roth_UI_Art
	  a = Roth_UI_Orbs
    end
    for _, v in pairs(a) do
      local f = _G[v]
      if f and f:IsUserPlaced() then
        --print(f:GetName())
        f.dragframe:Show()
        f.dragframe:EnableMouse(true)
        f.dragframe:RegisterForDrag("LeftButton")
        f.dragframe:SetScript("OnEnter", function(s)
          GameTooltip:SetOwner(s, "ANCHOR_TOP")
          GameTooltip:AddLine(s:GetParent():GetName(), 0, 1, 0.5, 1, 1, 1)
          GameTooltip:AddLine("Hold down ALT+SHIFT to drag!", 1, 1, 1, 1, 1, 1)
          GameTooltip:Show()
        end)
        f.dragframe:SetScript("OnLeave", function(s) GameTooltip:Hide() end)
      end
    end
  end

  function Roth_UILock(c)
    print("Roth_UI: "..c.." locked")
    local a
    if c == "art" then
      a = Roth_UI_Art
    elseif c == "bars" then
      a = Roth_UI_Bars
    elseif c == "units" then
      a = Roth_UI_Units
	elseif c == "orbs" then
	  a = Roth_UI_Orbs
    elseif c == "all" then
      a = Roth_UI_Bars
      a = Roth_UI_Units
      a = Roth_UI_Art
	  a = Roth_UI_Orbs
    end
    for _, v in pairs(a) do
      local f = _G[v]
      if f and f:IsUserPlaced() then
        f.dragframe:Hide()
        f.dragframe:EnableMouse(false)
        --f.dragframe:RegisterForDrag(nil)
        f.dragframe:SetScript("OnEnter", nil)
        f.dragframe:SetScript("OnLeave", nil)
      end
    end
  end

  function Roth_UIReset(c)
    if InCombatLockdown() then
      print("Reseting frames is not possible in combat.")
      return
    end
    print("Roth_UI: "..c.." reset")
    local a
    if c == "art" then
      a = Roth_UI_Art
    elseif c == "bars" then
      a = Roth_UI_Bars
    elseif c == "units" then
      a = Roth_UI_Units
	  elseif c == "orbs" then
	  a = Roth_UI_Orbs
    elseif c == "all" then
      a = Roth_UI_Bars
      a = Roth_UI_Units
      a = Roth_UI_Art
	  a = Roth_UI_Orbs
    end
    for _, v in pairs(a) do
      local f = _G[v]
      if f and f.defaultPosition then
        f:ClearAllPoints()
        local pos = f.defaultPosition
        if pos.af and pos.a2 then
          f:SetPoint(pos.a1 or "CENTER", pos.af, pos.a2, pos.x or 0, pos.y or 0)
        elseif pos.af then
          f:SetPoint(pos.a1 or "CENTER", pos.af, pos.x or 0, pos.y or 0)
        else
          f:SetPoint(pos.a1 or "CENTER", pos.x or 0, pos.y or 0)
        end
      end
    end
  end

  local function SlashCmd(cmd)
    if (cmd:match"config") then
      if InCombatLockdown() then return end
      if ns.panel:IsShown() then
        ns.panel:Hide()
        --print("Hiding "..addon.." config panel")
      else
        ns.panel:Show()
        --print("Showing "..addon.." config panel")
      end
    elseif (cmd:match"resettemplates") then
      ns.db.resetTemplates()
        -- State Strip commands
        elseif cmd:match("^ss") or cmd:match("^statestrip") then
          local sub = cmd:gsub("^statestrip", "ss")
          local a, b, rest = sub:match("^ss%s*(%S*)%s*(%S*)%s*(.-)%s*$")
          a = a or ""
          b = b or ""
          rest = rest or ""
    
          local SS = ns.StateStrip
          if not SS then
            print("Roth_UI: State Strip not loaded")
            return
          end
    
          if a == "" or a == "help" then
            print("|c00FF3300State Strip commands:|r")
            print("|c00FF3300/roth ss addbuff <spellNameOrId>|r")
            print("|c00FF3300/roth ss adddebuff <spellNameOrId>|r")
            print("|c00FF3300/roth ss delbuff <spellNameOrId>|r")
            print("|c00FF3300/roth ss deldebuff <spellNameOrId>|r")
            print("|c00FF3300/roth ss listbuff|r")
            print("|c00FF3300/roth ss listdebuff|r")
            print("|c00FF3300/roth ss clearbuff|r")
            print("|c00FF3300/roth ss cleardebuff|r")
            print("|c00FF3300/roth ss test <all|buff|debuff|lowhp|lowmana|clear>|r")
            return
          end
    
          local function Tail(x, y, z)
            local s = ""
            if x and x ~= "" then s = x end
            if y and y ~= "" then s = (s == "" and y or (s .. " " .. y)) end
            if z and z ~= "" then s = (s == "" and z or (s .. " " .. z)) end
            return s
          end
    
          if a == "test" then
            local mode = b ~= "" and b or "all"
            if mode == "off" then mode = "clear" end
            SS.SetTestMode(mode)
            print("Roth_UI: State Strip test mode: " .. mode)
            return
          end
    
          if a == "addbuff" then
            local v = Tail(b, rest)
            local ok, err = SS.AddTracked("buffs", v)
            print(ok and ("Roth_UI: tracked buff: " .. v) or ("Roth_UI: failed: " .. (err or "?")))
            return
          end
          if a == "adddebuff" then
            local v = Tail(b, rest)
            local ok, err = SS.AddTracked("debuffs", v)
            print(ok and ("Roth_UI: tracked debuff: " .. v) or ("Roth_UI: failed: " .. (err or "?")))
            return
          end
          if a == "delbuff" then
            local v = Tail(b, rest)
            SS.RemoveTracked("buffs", v)
            print("Roth_UI: untracked buff: " .. v)
            return
          end
          if a == "deldebuff" then
            local v = Tail(b, rest)
            SS.RemoveTracked("debuffs", v)
            print("Roth_UI: untracked debuff: " .. v)
            return
          end
          if a == "clearbuff" then
            SS.ClearTracked("buffs")
            print("Roth_UI: cleared tracked buffs")
            return
          end
          if a == "cleardebuff" then
            SS.ClearTracked("debuffs")
            print("Roth_UI: cleared tracked debuffs")
            return
          end
          if a == "listbuff" then
            local list = SS.ListTracked("buffs")
            print("Roth_UI: tracked buffs (" .. #list .. ")")
            for i = 1, #list do print(" - " .. list[i]) end
            return
          end
          if a == "listdebuff" then
            local list = SS.ListTracked("debuffs")
            print("Roth_UI: tracked debuffs (" .. #list .. ")")
            for i = 1, #list do print(" - " .. list[i]) end
            return
          end
    
          print("Roth_UI: unknown ss subcommand. Try /roth ss help")
          return
    elseif (cmd:match"unlockart") then
      Roth_UIUnlock("art")
	elseif (cmd:match"unlockorbs") then
	  Roth_UIUnlock("orbs")
	elseif (cmd:match"lockorbs") then
	  Roth_UILock("orbs")
    elseif (cmd:match"lockart") then
      Roth_UILock("art")
    elseif (cmd:match"unlockbars") then
      Roth_UIUnlock("bars")
    elseif (cmd:match"lockbars") then
      Roth_UILock("bars")
    elseif (cmd:match"unlockunits") then
      Roth_UIUnlock("units")
    elseif (cmd:match"lockunits") then
      Roth_UILock("units")
    elseif (cmd:match"resetart") then
      Roth_UIReset("art")
    elseif (cmd:match"resetbars") then
      Roth_UIReset("bars")
    elseif (cmd:match"resetunits") then
      Roth_UIReset("units")
	elseif (cmd:match"resetorbs") then
      Roth_UIReset("orbs")
    elseif (cmd:match"unlockall") then
      Roth_UIUnlock("bars")
      Roth_UIUnlock("units")
      Roth_UIUnlock("art")
	  Roth_UIUnlock("orbs")
    elseif (cmd:match"resetall") then
      Roth_UIReset("bars")
      Roth_UIReset("units")
      Roth_UIReset("art")
	  Roth_UIReset("orbs")
    elseif (cmd:match"lockall") then
      Roth_UILock("units")
      Roth_UILock("bars")
      Roth_UILock("art")
	  Roth_UILock("orbs")
    else
      print("|c00FF3300Roth_UI command list:|r")
      print("|c00FF3300\/roth config|r, to open the orb config panel")
      print("|c00FF3300\/roth lockart|r, to lock the art")
      print("|c00FF3300\/roth unlockart|r, to unlock the art")
	  print("|c00FF3300\/roth unlockorbs|r, to unlock the orbs")
	  print("|c00FF3300\/roth lockorbs|r, to lock the orbs")
      print("|c00FF3300\/roth lockbars|r, to lock the bars")
      print("|c00FF3300\/roth unlockbars|r, to unlock the bars")
      print("|c00FF3300\/roth lockunits|r, to lock the units")
      print("|c00FF3300\/roth unlockunits|r, to unlock the units")
      print("|c00FF3300\/roth resetart|r, to reset the art")
      print("|c00FF3300\/roth resetbars|r, to reset the bars")
      print("|c00FF3300\/roth resetunits|r, to reset the units")
      print("|c00FF3300\/roth unlockall|r, to unlock all frames")
      print("|c00FF3300\/roth lockall|r, to lock all frames")
      print("|c00FF3300\/roth resetall|r, to reset all frames")
      print("|c00FF3300\/roth ss help|r, state strip tracking & test commands")
    end
  end

  SlashCmdList["roth"] = SlashCmd;
  SLASH_roth1 = "/roth";

  print("|c00FF3300Roth_UI loaded.|r")
  print("|c00FF3300\/roth|r to display the command list")
