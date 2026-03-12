-- rLFGFilter: LFGBrowseFrame role priority + class-colored role icons (Classic VanillaStyle browse)
-- 1) Groups: promote groups that still need any selected role(s) to top of GROUP section (stable)
-- 2) Individuals: if party leader, promote players matching selected role(s) to top of INDIVIDUALS section (stable)
-- 3) Tint member role icons by class color (best-effort, ScrollBox/VanillaStyle-friendly)

local addon, ns = ...
local cfg

local _Orig_LFGBrowseUtil_SortSearchResults

-------------------------------------------------
-- Config
-------------------------------------------------

local function EnsureDefaults()
  ns.cfg = ns.cfg or {}
  ns.cfg.embeds = ns.cfg.embeds or {}
  ns.cfg.embeds.rLFGFilter = ns.cfg.embeds.rLFGFilter or {
    enabled = true,
    tank = false,
    healer = false,
    dps = false,
    only5manInference = true,
    tintRoleIconsByClass = true,
  }

  if Roth_UI and Roth_UI.db and Roth_UI.db.profile then
    Roth_UI.db.profile.embeds = Roth_UI.db.profile.embeds or {}
    Roth_UI.db.profile.embeds.rLFGFilter = Roth_UI.db.profile.embeds.rLFGFilter or {
      enabled = true,
      tank = false,
      healer = false,
      dps = false,
      only5manInference = true,
      tintRoleIconsByClass = true,
    }
  end
end

local function GetLFGCfg()
  if Roth_UI and Roth_UI.db and Roth_UI.db.profile and Roth_UI.db.profile.embeds and Roth_UI.db.profile.embeds.rLFGFilter then
    return Roth_UI.db.profile.embeds.rLFGFilter
  end
  return ns.cfg and ns.cfg.embeds and ns.cfg.embeds.rLFGFilter
end

local function RefreshBrowse()
  if not LFGBrowseFrame then return end
  if LFGBrowseFrame.UpdateResultList then
    LFGBrowseFrame:UpdateResultList()
  elseif LFGBrowseFrame.UpdateResults then
    LFGBrowseFrame:UpdateResults()
  end
end

-------------------------------------------------
-- Common helpers
-------------------------------------------------

local function GetClassColorRGB(classTag)
  local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
  local c = colors and colors[classTag]
  if not c then return nil end
  return c.r, c.g, c.b
end

local function GetFirstActivityID(info)
  if not info then return nil end
  if info.activityID then return info.activityID end
  if info.activityIDs and info.activityIDs[1] then return info.activityIDs[1] end
  return nil
end

local function SafeGetMaxPlayers(activityID)
  if not activityID or not C_LFGList or not C_LFGList.GetActivityInfoTable then return nil end
  local a = C_LFGList.GetActivityInfoTable(activityID)
  return type(a) == "table" and a.maxNumPlayers or nil
end

local function SafeGetMemberCounts(resultID)
  if not C_LFGList or not C_LFGList.GetSearchResultMemberCounts then
    return 0, 0, 0
  end

  local a, b, c = C_LFGList.GetSearchResultMemberCounts(resultID)

  if type(a) == "table" then
    local t = a
    local tank   = t.TANK or t.tank or t[1] or 0
    local healer = t.HEALER or t.healer or t[2] or 0
    local dps    = t.DAMAGER or t.dps or t.damage or t[3] or 0
    return tank, healer, dps
  end

  return (a or 0), (b or 0), (c or 0)
end

-------------------------------------------------
-- Groups: promote “needs selected role(s)” (5-man inference)
-------------------------------------------------

local function PassesGroupRoleFilters(resultID)
  cfg = GetLFGCfg()
  if not cfg or not cfg.enabled then return true end
  if not (cfg.tank or cfg.healer or cfg.dps) then return true end

  local info = C_LFGList and C_LFGList.GetSearchResultInfo and C_LFGList.GetSearchResultInfo(resultID)
  if type(info) ~= "table" then
    return true
  end

  local activityID = GetFirstActivityID(info)
  local maxPlayers = SafeGetMaxPlayers(activityID)

  if cfg.only5manInference and maxPlayers ~= 5 then
    return true
  end
  if maxPlayers ~= 5 then
    return true
  end

  local tank, healer, dps = SafeGetMemberCounts(resultID)

  local needsTank   = tank < 1
  local needsHealer = healer < 1
  local needsDps    = dps < 3

  if cfg.tank and needsTank then return true end
  if cfg.healer and needsHealer then return true end
  if cfg.dps and needsDps then return true end
  return false
end

-------------------------------------------------
-- Individuals: if party leader, promote matching role(s)
-------------------------------------------------

local function IsPartyLeader()
  return IsInGroup() and UnitIsGroupLeader("player")
end

local function IsIndividualListing(resultID)
  if not (C_LFGList and C_LFGList.GetSearchResultInfo) then return false end
  local info = C_LFGList.GetSearchResultInfo(resultID)
  if type(info) ~= "table" then return false end

  local activityID = GetFirstActivityID(info)
  if activityID and C_LFGList.GetActivityInfoTable then
    local a = C_LFGList.GetActivityInfoTable(activityID)
    if type(a) == "table" and a.maxNumPlayers == 1 then
      return true
    end
  end

    -- Fallback heuristic: numMembers==1 and role counts sum to 1
    if info.numMembers == 1 then
      local t, h, d = SafeGetMemberCounts(resultID)
      if (t + h + d) == 1 then
        return true
      end
    end

  return false
end

local function IndividualMatchesSelectedRole(resultID)
  local c = GetLFGCfg()
  if not c or not c.enabled then return true end
  if not (c.tank or c.healer or c.dps) then return true end
  if not (C_LFGList and C_LFGList.GetSearchResultMemberCounts) then return true end
  
  local tank, healer, dps = SafeGetMemberCounts(resultID)
  tank, healer, dps = (tank or 0), (healer or 0), (dps or 0)

  if c.tank and tank >= 1 then return true end
  if c.healer and healer >= 1 then return true end
  if c.dps and dps >= 1 then return true end
  return false
end

-------------------------------------------------
-- Stable partition utilities (in-place, stable)
-------------------------------------------------

local function StablePartitionByPredicate(results, startIndex, endIndex, predicate)
  if type(results) ~= "table" then return end
  if startIndex > endIndex then return end

  local match, nomatch = {}, {}
  for i = startIndex, endIndex do
    local id = results[i]
    if predicate(id) then
      match[#match + 1] = id
    else
      nomatch[#nomatch + 1] = id
    end
  end

  local n = startIndex - 1
  for i = 1, #match do
    n = n + 1
    results[n] = match[i]
  end
  for i = 1, #nomatch do
    n = n + 1
    results[n] = nomatch[i]
  end
end

local function StablePartitionGroupsThenIndividuals(results)
  local c = GetLFGCfg()
  if not c or not c.enabled then return end
  if not (c.tank or c.healer or c.dps) then return end
  if type(results) ~= "table" or #results == 0 then return end

  local firstIndividual = nil
  for i = 1, #results do
    if IsIndividualListing(results[i]) then
      firstIndividual = i
      break
    end
  end

  if not firstIndividual then
    StablePartitionByPredicate(results, 1, #results, PassesGroupRoleFilters)
    return
  end

  if firstIndividual > 1 then
    StablePartitionByPredicate(results, 1, firstIndividual - 1, PassesGroupRoleFilters)
  end

  if IsPartyLeader() then
    StablePartitionByPredicate(results, firstIndividual, #results, IndividualMatchesSelectedRole)
  end
end

-------------------------------------------------
-- Row tinting (ScrollBox / VanillaStyle)
-- Your fstack shows: ScrollTarget.<row>.DataDisplay.Enumerate.Icon#
-------------------------------------------------

local function GetElementResultID(row)
  if not row then return nil end
  if row.resultID then return row.resultID end
  if row.searchResultID then return row.searchResultID end

  if row.GetElementData then
    local d = row:GetElementData()
    if type(d) == "table" then
      return d.resultID or d.searchResultID or d.id
    end
  end
  if row.elementData and type(row.elementData) == "table" then
    return row.elementData.resultID or row.elementData.searchResultID or row.elementData.id
  end
  if row.data and type(row.data) == "table" then
    return row.data.resultID or row.data.searchResultID or row.data.id
  end
  return nil
end

local function FindDataDisplayHolder(row)
  -- Sometimes the element frame itself *is* the holder; sometimes it has a single child that is.
  if row and row.DataDisplay and row.DataDisplay.Enumerate then
    return row
  end
  if not row or not row.GetChildren then return nil end

  local kids = { row:GetChildren() }
  for i = 1, #kids do
    local k = kids[i]
    if k and k.DataDisplay and k.DataDisplay.Enumerate then
      return k
    end
  end

  return nil
end

local function TintRoleIconsForRow(row)
  local c = GetLFGCfg()
  if not c or not c.tintRoleIconsByClass then return end
  if not (C_LFGList and C_LFGList.GetSearchResultInfo and C_LFGList.GetSearchResultMemberInfo) then return end

  local resultID = GetElementResultID(row)
  if not resultID then return end

  local holder = FindDataDisplayHolder(row)
  if not holder then return end

  local info = C_LFGList.GetSearchResultInfo(resultID)
  if type(info) ~= "table" then return end

  local numMembers = info.numMembers or 0
  if numMembers <= 0 then return end

  local enum = holder.DataDisplay and holder.DataDisplay.Enumerate
  if not enum then return end

  local colors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS

  -- Collect icons (Icon1..IconN) and hard-reset their tint to avoid ScrollBox reuse artifacts
  local icons = {}
  for i = 1, 10 do
    local ic = enum["Icon"..i]
    if ic and ic.SetVertexColor then
      ic:SetVertexColor(1, 1, 1, 1) -- reset
      icons[#icons + 1] = ic
    end
  end
  if #icons == 0 then return end

  -- Collect member class colors by ROLE in member-index order
  local roleToColors = { TANK = {}, HEALER = {}, DAMAGER = {} }
  for i = 1, math.min(numMembers, 8) do
    local role, classTag = C_LFGList.GetSearchResultMemberInfo(resultID, i)
    if role and classTag and colors[classTag] then
      local cc = colors[classTag]
      local bucket = roleToColors[role]
      if bucket then
        bucket[#bucket + 1] = { r = cc.r, g = cc.g, b = cc.b }
      end
    end
  end

  -- Determine each icon’s ROLE by reading its atlas/texture.
  -- VanillaStyle role icons typically use the roles texture / atlas; we can infer role by texture coords or atlas name
  -- BUT we can do something simpler: Blizzard often stores icon.role on these textures (sometimes present).
  -- We'll try a few best-effort hints, then fall back to "fill in order TANK,HEALER,DPS..."
  local iconRoles = {}

  local function GuessRoleForIcon(ic)
    -- 1) explicit field if Blizzard set one
    if ic.role then return ic.role end
    if ic.Role then return ic.Role end

    -- 2) atlas name contains role
    if ic.GetAtlas then
      local a = ic:GetAtlas()
      if type(a) == "string" then
        local s = a:upper()
        if s:find("TANK") then return "TANK" end
        if s:find("HEAL") then return "HEALER" end
        if s:find("DPS") or s:find("DAMAGER") then return "DAMAGER" end
      end
    end

    -- 3) last resort: unknown
    return nil
  end

  for idx, ic in ipairs(icons) do
    iconRoles[idx] = GuessRoleForIcon(ic)
  end

  -- If none of the icons can be guessed, assume the enumerate displays in role order:
  -- TANK, HEALER, then remaining are DPS (this matches what most people see in the browse list)
  local anyGuessed = false
  for i = 1, #iconRoles do
    if iconRoles[i] then anyGuessed = true break end
  end
  if not anyGuessed then
    if #icons >= 1 then iconRoles[1] = "TANK" end
    if #icons >= 2 then iconRoles[2] = "HEALER" end
    for i = 3, #icons do iconRoles[i] = "DAMAGER" end
  end

  -- Apply: assign tank icon from tank bucket, healer icon from healer bucket,
  -- DPS icons from DPS bucket in order.
  local used = { TANK = 0, HEALER = 0, DAMAGER = 0 }
  for idx, ic in ipairs(icons) do
    local role = iconRoles[idx] or "DAMAGER"
    local bucket = roleToColors[role]
    if bucket and #bucket > 0 then
      used[role] = used[role] + 1
      local col = bucket[used[role]] or bucket[#bucket] -- if more icons than members, reuse last
      if col then
        ic:SetVertexColor(col.r, col.g, col.b, 1)
      end
    end
  end
end

local function GetVisibleRows()
  if not LFGBrowseFrame then return nil end
  local sb = LFGBrowseFrame.ScrollBox or (LFGBrowseFrame.ResultList and LFGBrowseFrame.ResultList.ScrollBox)
  if sb and sb.GetFrames then
    return sb:GetFrames()
  end
  return nil
end

local function TintVisibleRows()
  local rows = GetVisibleRows()
  if type(rows) ~= "table" then return end
  for i = 1, #rows do
    TintRoleIconsForRow(rows[i])
  end
end

local function HookVanillaStyleRowTint()
  if not LFGBrowseFrame or LFGBrowseFrame.__rLFGFilterTintHooked then return end
  LFGBrowseFrame.__rLFGFilterTintHooked = true

  local function AfterUpdate()
    ns.Scheduler.NextFrame(TintVisibleRows)
  end

  if LFGBrowseFrame.UpdateResultList then
    hooksecurefunc(LFGBrowseFrame, "UpdateResultList", AfterUpdate)
  end
  if LFGBrowseFrame.UpdateResults then
    hooksecurefunc(LFGBrowseFrame, "UpdateResults", AfterUpdate)
  end

  -- Retint after scrolling (ScrollBox recycles row frames)
  local sb = LFGBrowseFrame.ScrollBox
  if sb and sb.RegisterCallback and ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnScroll then
    pcall(function()
      sb:RegisterCallback(ScrollBoxListMixin.Event.OnScroll, AfterUpdate, ns)
    end)
  end
end

-------------------------------------------------
-- Hook: keep Blizzard sort, then stable partition
-------------------------------------------------

local function WrapSort()
  if type(_G.LFGBrowseUtil_SortSearchResults) ~= "function" then return false end
  if _Orig_LFGBrowseUtil_SortSearchResults then return true end

  _Orig_LFGBrowseUtil_SortSearchResults = _G.LFGBrowseUtil_SortSearchResults

  _G.LFGBrowseUtil_SortSearchResults = function(results, ...)
    local ret = _Orig_LFGBrowseUtil_SortSearchResults(results, ...)
    StablePartitionGroupsThenIndividuals(results)
    return ret
  end

  return true
end

-------------------------------------------------
-- UI
-------------------------------------------------

local function CreateToggle(parent, label, key, x)
  local b = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  b:SetPoint("LEFT", parent, "LEFT", x, 0)
  b.text:SetText(label)

  b:SetScript("OnClick", function(self)
    local c = GetLFGCfg()
    if not c then return end
    c[key] = self:GetChecked() and true or false
    RefreshBrowse()
  end)

  return b
end

local function EnsureUI()
  if not LFGBrowseFrame or LFGBrowseFrame.__rLFGFilterUI then return end

  local f = CreateFrame("Frame", nil, LFGBrowseFrame)
  f:SetSize(280, 18)
  f:SetPoint("TOPRIGHT", LFGBrowseFrame, "TOPRIGHT", -12, -58)

  local t = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  t:SetPoint("BOTTOMLEFT", f, "TOPLEFT", 0, 2)
  t:SetText("Role Priority")

  f.tank   = CreateToggle(f, "Tank",   "tank",   0)
  f.healer = CreateToggle(f, "Healer", "healer", 70)
  f.dps    = CreateToggle(f, "DPS",    "dps",    150)

  LFGBrowseFrame.__rLFGFilterUI = f
end

local function SyncUI()
  local ui = LFGBrowseFrame and LFGBrowseFrame.__rLFGFilterUI
  if not ui then return end
  local c = GetLFGCfg()
  if not c then return end
  ui.tank:SetChecked(c.tank)
  ui.healer:SetChecked(c.healer)
  ui.dps:SetChecked(c.dps)
end

-------------------------------------------------
-- Init
-------------------------------------------------

local function Init()
  EnsureDefaults()

  local function TrySetup()
    if not LFGBrowseFrame then return false end

    WrapSort()
    HookVanillaStyleRowTint()

    EnsureUI()
    SyncUI()

    if not LFGBrowseFrame.__rLFGFilterOnShow then
      LFGBrowseFrame.__rLFGFilterOnShow = true
      LFGBrowseFrame:HookScript("OnShow", function()
        WrapSort()
        HookVanillaStyleRowTint()
        EnsureUI()
        SyncUI()
        RefreshBrowse()
      end)
    end

    return true
  end

  if TrySetup() then return end

  local ev = CreateFrame("Frame")
  ev:RegisterEvent("PLAYER_ENTERING_WORLD")
  ev:RegisterEvent("ADDON_LOADED")
  ev:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "Blizzard_GroupFinder_VanillaStyle" or addonName == "Blizzard_LookingForGroupUI" or addonName == nil then
      if TrySetup() then
        ev:UnregisterAllEvents()
      end
      return
    end
    if TrySetup() then
      ev:UnregisterAllEvents()
    end
  end)

  local configs = {
    enabled = {
      type = "toggle",
      name = "Enable LFG Role Priority",
      desc = "Promotes matching groups/players to the top of their sections in the browse list.",
      get = function() return GetLFGCfg().enabled end,
      set = function(_, v) local c=GetLFGCfg(); c.enabled=v; RefreshBrowse() end,
    },
    only5manInference = {
      type = "toggle",
      name = "Only infer for 5-mans",
      desc = "Only infer group role needs for activities with max players = 5 (recommended).",
      get = function() return GetLFGCfg().only5manInference end,
      set = function(_, v) local c=GetLFGCfg(); c.only5manInference=v; RefreshBrowse() end,
    },
    tintRoleIconsByClass = {
      type = "toggle",
      name = "Tint role icons by class",
      desc = "Class-color the group member role icons in browse list (VanillaStyle/ScrollBox).",
      get = function() return GetLFGCfg().tintRoleIconsByClass end,
      set = function(_, v) local c=GetLFGCfg(); c.tintRoleIconsByClass=v; RefreshBrowse() end,
    },
  }
  if Roth_UI and Roth_UI.AddConfig then
    Roth_UI:AddConfig("embeds.rLFGFilter", configs, "LFG Filters", true)
  end
end

ns:RegisterInit(Init)