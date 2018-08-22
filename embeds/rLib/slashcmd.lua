
-- rLib: slashcmd
-- zork, 2016

-----------------------------
-- Variables
-----------------------------

local A, L = ...

local defaultColor = "00FFFFFF"

-----------------------------
-- Functions
-----------------------------

--rLib:CreateSlashCmd
function rLib:CreateSlashCmd(addonName, shortcut, frames, color)
  if not addonName or not shortcut or not frames then return end
  SlashCmdList[shortcut] = function(cmd)
    if (cmd:match"unlock") then
      L:UnlockFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames unlocked")
    elseif (cmd:match"lock") then
      L:LockFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames locked")
    elseif (cmd:match"reset") then
      L:ResetFrames(frames, "|c"..(color or defaultColor)..addonName.."|r frames reset")
    else
      print("|c"..(color or defaultColor)..addonName.." command list:|r")
      print("|c"..(color or defaultColor).."\/"..shortcut.." lock|r, to lock all frames")
      print("|c"..(color or defaultColor).."\/"..shortcut.." unlock|r, to unlock all frames")
      print("|c"..(color or defaultColor).."\/"..shortcut.." reset|r, to reset all frames")
    end
  end
  _G["SLASH_"..shortcut.."1"] = "/"..shortcut
  print("|c"..(color or defaultColor)..addonName.." loaded.|r")
  print("|c"..(color or defaultColor).."\/"..shortcut.."|r to display the command list")
end

  function rCreateSlashCmdFunction(addon, shortcut, dragFrameList, color)
    if not addon or not shortcut or not dragFrameList then return end
    local slashCmdFunction = function(cmd)
      if (cmd:match"unlock") then
        L:UnlockFrames(dragFrameList, addon..": frames unlocked")
      elseif (cmd:match"lock") then
        L:LockFrames(dragFrameList, addon..": frames locked")
      elseif (cmd:match"reset") then
        L:ResetFrames(dragFrameList, addon..": frames reseted")
      else
        print("|c"..(color or defaultColor)..addon.." command list:|r")
        print("|c"..(color or defaultColor).."\/"..shortcut.." lock|r, to lock all frames")
        print("|c"..(color or defaultColor).."\/"..shortcut.." unlock|r, to unlock all frames")
        print("|c"..(color or defaultColor).."\/"..shortcut.." reset|r, to reset all frames")
      end
    end
    return slashCmdFunction
  end
