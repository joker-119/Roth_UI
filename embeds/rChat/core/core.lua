-----------------------------
-- INIT
-----------------------------

--get the addon namespace
local addon, ns = ...
local cfg
local addonName, Roth_UI = ...
local LSM = LibStub("LibSharedMedia-3.0")
local chatFont = nil
local chatScale = 1

-----------------------------
-- FUNCTIONS
-----------------------------

-----------------------------
-- PLAYER LEVEL TAGS (persistent cache + unit token harvesting)
-----------------------------

-- Runtime cache: key -> level
-- We keep both "Name" and "Name-Realm" in runtime for lookup convenience,
-- but only store the canonical key in SavedVariables to avoid duplicates.
local levelCache = {}

-- Persistent cache (SavedVariables)
local db, realmDB

local function Now()
  return time and time() or 0
end

local function GetPlayerRealmKey()
  local r = GetRealmName and GetRealmName()
  return r or "UnknownRealm"
end

local function GetExpansionMaxLevel()
  if GetMaxLevelForPlayerExpansion then
    local ok, v = pcall(GetMaxLevelForPlayerExpansion)
    if ok and type(v) == "number" and v > 0 then return v end
  end
  if GetMaxPlayerLevel then
    local ok, v = pcall(GetMaxPlayerLevel)
    if ok and type(v) == "number" and v > 0 then return v end
  end
  return MAX_PLAYER_LEVEL or 60
end

local function EnsureDB()
  if type(_G.rChatLevelDB) ~= "table" then
    _G.rChatLevelDB = { version = 1, ttl = 86400, realms = {} }
  end

  db = _G.rChatLevelDB
  db.version = db.version or 1
  db.ttl = db.ttl or 86400
  db.realms = db.realms or {}

  local rk = GetPlayerRealmKey()
  db.realms[rk] = db.realms[rk] or {}
  realmDB = db.realms[rk]
end

local function LoadRealmIntoRuntimeCache()
  if not realmDB then return end
  for nameKey, rec in pairs(realmDB) do
    if type(rec) == "table" and type(rec.level) == "number" and rec.level > 0 then
      levelCache[nameKey] = rec.level
      -- also seed short name for convenience lookups
      local short = nameKey:gsub("%-.*$", "")
      levelCache[short] = rec.level
    end
  end
end

local function NormalizeNameKey(name)
  if not name or name == "" then return nil end
  return name
end

local function ShortName(name)
  if not name then return nil end
  return (name:gsub("%-.*$", ""))
end

-- Canonical DB key:
-- Prefer "Name-Realm" when we know realm, else "Name".
local function CanonicalKeyFromUnit(unit)
  local name, realm = UnitName(unit)
  if not name or name == "" then return nil end

  -- If realm is missing, it commonly means "same realm as player" on many clients.
  if not realm or realm == "" then
    realm = GetPlayerRealmKey()
  end

  if realm and realm ~= "" then
    return name .. "-" .. realm
  end

  return name
end

local function CanonicalKeyFromNameKey(nameKey)
  -- If we already have Name-Realm, keep it.
  if not nameKey then return nil end
  if nameKey:find("%-") then return nameKey end
  -- Otherwise keep short. We *could* append player realm, but that risks wrongness.
  return nameKey
end

local function GetCachedLevel(nameKey)
  if not nameKey then return nil end
  return levelCache[nameKey]
end

-- Write-through caching with dedupe: only write if new or level changed.
local function CacheLevelCanonical(canonicalKey, lvl)
  if not canonicalKey or not lvl or lvl <= 0 then return end
  if not realmDB then EnsureDB() end
  if not realmDB then return end

  local existing = realmDB[canonicalKey]
  local existingLevel = existing and existing.level

  if existingLevel == lvl then
    -- Still mirror to runtime
    levelCache[canonicalKey] = lvl
    levelCache[ShortName(canonicalKey)] = lvl
    return
  end

  -- Update runtime
  levelCache[canonicalKey] = lvl
  levelCache[ShortName(canonicalKey)] = lvl

  -- Update DB
  local maxLvl = GetExpansionMaxLevel()
  if lvl < maxLvl then
    realmDB[canonicalKey] = { level = lvl, ts = Now() }
  else
    realmDB[canonicalKey] = { level = lvl }
  end
end

local function IsStaleAndRefreshable(nameKey)
  if not realmDB then EnsureDB() end
  if not realmDB then return false end

  local canonical = CanonicalKeyFromNameKey(nameKey)
  local rec = canonical and realmDB[canonical] or nil
  if type(rec) ~= "table" then return false end

  local lvl = rec.level
  if type(lvl) ~= "number" or lvl <= 0 then return false end

  local maxLvl = GetExpansionMaxLevel()
  if lvl >= maxLvl then
    return false
  end

  local ts = rec.ts
  if type(ts) ~= "number" or ts <= 0 then
    return true
  end

  local ttl = (db and db.ttl) or 86400
  return (Now() - ts) > ttl
end

-----------------------------
-- Unit token harvesting
-----------------------------

local function TryHarvestUnit(unit)
  if not unit or not UnitExists(unit) then return end
  if not UnitIsPlayer(unit) then return end

  local lvl = UnitLevel(unit)
  if not lvl or lvl <= 0 then return end

  local key = CanonicalKeyFromUnit(unit)
  if not key then return end

  CacheLevelCanonical(key, lvl)
end

local function HarvestGroup()
  if IsInRaid() then
    for i = 1, 40 do
      TryHarvestUnit("raid" .. i)
    end
  elseif IsInGroup() then
    -- party1-4 are other players, and "player" is you
    for i = 1, 4 do
      TryHarvestUnit("party" .. i)
    end
  end

  -- Always harvest yourself too
  TryHarvestUnit("player")
end

local function HarvestCommonUnits()
  TryHarvestUnit("target")
  TryHarvestUnit("mouseover")
  TryHarvestUnit("focus")
end

local function HarvestNameplates()
  if not (C_NamePlate and C_NamePlate.GetNamePlates) then return end
  local plates = C_NamePlate.GetNamePlates()
  if not plates then return end
  for _, plate in ipairs(plates) do
    local unit = plate.namePlateUnitToken
    if unit then
      TryHarvestUnit(unit)
    end
  end
end

-----------------------------
-- Manual /who parsing (chat output)
-----------------------------

-- Your observed format:
-- [Poxman]: Level 67 Human Warrior <Names Are Hard> - Shadow Labyrinth
-- 1 player total
local function ParseWhoSystemLine(msg)
  if not msg or msg == "" then return nil end

  local name, lvl = msg:match("^%s*%[([^%]]+)%]%s*:%s*Level%s+(%d+)%s+")
  if name and lvl then
    return name, tonumber(lvl)
  end

  -- some clients include hyperlink markup; keep a fallback
  local linkName, linkLvl = msg:match("|Hplayer:([^:|]+)[^|]*|h%[[^%]]+%]|h%s*:%s*Level%s+(%d+)%s+")
  if linkName and linkLvl then
    return linkName, tonumber(linkLvl)
  end

  return nil
end

local function HarvestWhoUIResults()
  -- Modern Classic / Anniversary / TBC clients
  if C_FriendList and C_FriendList.GetNumWhoResults and C_FriendList.GetWhoInfo then
    local ok, displayed = pcall(C_FriendList.GetNumWhoResults)
    if ok and displayed and displayed > 0 then
      for i = 1, displayed do
        local info = C_FriendList.GetWhoInfo(i)
        if type(info) == "table" and info.level and info.fullName then
          -- Who panel is realm-local, but fullName may already include realm
          local name = info.fullName
          local lvl  = info.level
          if lvl and lvl > 0 then
            CacheLevelCanonical(name.."-"..GetPlayerRealmKey(), lvl)
          end
        end
      end
    end
    return
  end

  -- Legacy fallback (if ever present)
  if GetNumWhoResults and GetWhoInfo then
    local num = GetNumWhoResults()
    if num and num > 0 then
      for i = 1, num do
        local name, _, level = GetWhoInfo(i)
        if name and level and level > 0 then
          CacheLevelCanonical(name .. "-" .. GetPlayerRealmKey(), level)
        end
      end
    end
  end
end

-----------------------------
-- Difficulty color helper
-----------------------------

local function RGBToHex(r, g, b)
  r = (r and r <= 1) and r * 255 or (r or 255)
  g = (g and g <= 1) and g * 255 or (g or 255)
  b = (b and b <= 1) and b * 255 or (b or 255)
  return string.format("%02x%02x%02x", r, g, b)
end

local function ColorizeLevelByDifficulty(level)
  if not level then return nil end
  local c = GetQuestDifficultyColor and GetQuestDifficultyColor(level)
  if not c then
    return "|cffffffff" .. level .. "|r"
  end
  local hex = RGBToHex(c.r, c.g, c.b)
  return "|cff" .. hex .. level .. "|r"
end

local function InjectLevelIntoPlayerLinks(text)
  return text:gsub("(|Hplayer:([^:|]+)[^|]*|h%[)([^%]]+)(%]|h)", function(prefix, rawName, display, suffix)
    local nameKey = NormalizeNameKey(rawName)
    if not nameKey then
      return prefix .. display .. suffix
    end

    -- Opportunistic harvest right now (in case this player is target/mouseover/etc)
    HarvestCommonUnits()

    local lvl = GetCachedLevel(nameKey) or GetCachedLevel(ShortName(nameKey))

    -- If we have it and it's stale, we *cannot* auto-/who; user shift-click can refresh.
    -- So we just show cached value and rely on unit harvest/manual who.
    if not lvl then
      return prefix .. display .. suffix
    end

    local lvlText = ColorizeLevelByDifficulty(lvl)
    return prefix .. lvlText .. " " .. display .. suffix
  end)
end

-----------------------------
-- EVENT FRAME
-----------------------------

local levelTagger = CreateFrame("Frame")
levelTagger:RegisterEvent("ADDON_LOADED")
levelTagger:RegisterEvent("CHAT_MSG_SYSTEM")
levelTagger:RegisterEvent("GROUP_ROSTER_UPDATE")
levelTagger:RegisterEvent("PLAYER_TARGET_CHANGED")
levelTagger:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
levelTagger:RegisterEvent("PLAYER_FOCUS_CHANGED")
levelTagger:RegisterEvent("NAME_PLATE_UNIT_ADDED")
levelTagger:RegisterEvent("PLAYER_ENTERING_WORLD")
levelTagger:RegisterEvent("ZONE_CHANGED_NEW_AREA")
levelTagger:RegisterEvent("WHO_LIST_UPDATE")

levelTagger:SetScript("OnEvent", function(self, event, ...)
  if event == "ADDON_LOADED" then
    if not db then
      EnsureDB()
      LoadRealmIntoRuntimeCache()
      -- Seed own level immediately
      TryHarvestUnit("player")
    end
    return
  end

  if event == "CHAT_MSG_SYSTEM" then
    local msg = ...
    local name, lvl = ParseWhoSystemLine(msg)
    if name and lvl and lvl > 0 then
      CacheLevelCanonical(name .. "-" .. GetPlayerRealmKey(), lvl)
    end
    return
  end

  -- Unit events: harvest aggressively
  if event == "GROUP_ROSTER_UPDATE" then
    HarvestGroup()
    return
  end

  if event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" or event == "PLAYER_FOCUS_CHANGED" then
    HarvestCommonUnits()
    return
  end

  if event == "NAME_PLATE_UNIT_ADDED" then
    local unit = ...
    if unit then
      TryHarvestUnit(unit)
    else
      HarvestNameplates()
    end
    return
  end
  
  if event == "WHO_LIST_UPDATE" then
    HarvestWhoUIResults()
    return
  end

  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
    HarvestGroup()
    HarvestCommonUnits()
    HarvestNameplates()
    return
  end
end)

-----------------------------
-- Chat skinning
-----------------------------

local function skinChat(self)
  for i = 1, 23 do
    CHAT_FONT_HEIGHTS[i] = i + 7
  end
  local name = self:GetName()

  self:SetClampRectInsets(0, 0, 0, 0)
  self:SetResizeBounds(100, 50, UIParent:GetWidth(), UIParent:GetHeight())
  self:SetFrameStrata("HIGH")

  self:SetFontObject(ChatFontNormal)

  ChatFrameMenuButton:SetNormalTexture(ns.mediapath .. "ChatButtons_36x36_ChatMenu")
  ChatFrameMenuButton:SetDisabledTexture(ns.mediapath .. "ChatButtons_36x36_ChatMenuDisabled", "BLEND")
  ChatFrameMenuButton:SetPushedTexture(ns.mediapath .. "ChatButtons_36x36_ChatMenuDisabled", "BLEND")
  ChatFrameMenuButton:SetHighlightTexture(ns.mediapath .. "ChatButtons_36x36_ChatMenuHighlight", "BLEND")
  ChatFrame1ButtonFrameUpButton:SetNormalTexture(ns.mediapath .. "ChatButtons_36x36_Up")
  ChatFrame1ButtonFrameUpButton:SetDisabledTexture(ns.mediapath .. "ChatButtons_36x36_UpDisabled")
  ChatFrame1ButtonFrameUpButton:SetPushedTexture(ns.mediapath .. "ChatButtons_36x36_UpDisabled")
  ChatFrame1ButtonFrameUpButton:SetHighlightTexture(ns.mediapath .. "ChatButtons_36x36_UpHighlight")
  ChatFrame1ButtonFrameDownButton:SetNormalTexture(ns.mediapath .. "ChatButtons_36x36_Down")
  ChatFrame1ButtonFrameDownButton:SetDisabledTexture(ns.mediapath .. "ChatButtons_36x36_DownDisabled")
  ChatFrame1ButtonFrameDownButton:SetPushedTexture(ns.mediapath .. "ChatButtons_36x36_DownDisabled")
  ChatFrame1ButtonFrameDownButton:SetHighlightTexture(ns.mediapath .. "ChatButtons_36x36_DownHighlight")
  ChatFrame1ButtonFrameBottomButton:SetNormalTexture(ns.mediapath .. "ChatButtons_36x36_Bottom")
  ChatFrame1ButtonFrameBottomButton:SetDisabledTexture(ns.mediapath .. "ChatButtons_36x36_BottomDisabled")
  ChatFrame1ButtonFrameBottomButton:SetPushedTexture(ns.mediapath .. "ChatButtons_36x36_BottomDisabled")
  ChatFrame1ButtonFrameBottomButton:SetHighlightTexture(ns.mediapath .. "ChatButtons_36x36_BottomHighlight")

  _G[name .. "EditBoxLeft"]:Hide()
  _G[name .. "EditBoxMid"]:Hide()
  _G[name .. "EditBoxRight"]:Hide()
  local eb = _G[name .. "EditBox"]
  eb:SetAltArrowKeyMode(false)
  eb:ClearAllPoints()
  eb:SetPoint("BOTTOM", self, "TOP", 0, 22)
  eb:SetPoint("LEFT", self, -5, 0)
  eb:SetPoint("RIGHT", self, 10, 0)

  local tab = _G[name .. "Tab"]
  local tabFs = tab:GetFontString()
  tabFs:SetFont(chatFont, floor(11 * chatScale), "THINOUTLINE")
  tabFs:SetShadowOffset(1, -1)
  tabFs:SetShadowColor(0, 0, 0, 0.6)
  tabFs:SetTextColor(unpack(cfg.selectedTabColor))

  if cfg.hideChatTabBackgrounds then
    _G[name .. "Tab"]:SetAlpha(0)
  end
  tab:SetAlpha(cfg.selectedTabColor[4])

  self.skinApplied = true
end

-----------------------------
-- Unified AddMessage wrapper
-----------------------------

local function chatFilter(self, text, ...)
  if not text then
    return self.am(self, text, ...)
  end

  -- STEP 1: Channel/flag cleanup
  text = text:gsub('|h%[(%d+)%. .-%]|h', '|h%1|h')

  -- STEP 1.5: Add player level tags (when known)
  if cfg.showPlayerLevels then
    text = InjectLevelIntoPlayerLinks(text)
  end

  -- STEP 2: Emotes into UIErrorsFrame
  if text:find("(|Hplayer:.-|h.-|h )?(.*)") then
    local msg = text
    if msg:find("emote", 1, true) then
      UIErrorsFrame:AddMessage("|cffff4500" .. msg .. "|r")
    end
  end

  -- STEP 3: URL highlight
  local color = "0099FF"
  local foundurl = false
  local function highlighturl(before, url, after)
    foundurl = true
    if not string.link then
      function string.link(text2, linkType, value, colorHex)
        colorHex = colorHex or "ffffff"
        return "|cFF" .. colorHex .. "|H" .. linkType .. ":" .. value .. "|h" .. text2 .. "|h|r"
      end
    end
    return " " .. string.link("[" .. url .. "]", "url", url, color) .. " "
  end

  if not string.find(text, "%pTInterface%p+") and not string.find(text, "%pTINTERFACE%p+") then
    text = text:gsub("(%s?)(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?:%d%d?%d?%d?%d?)(%s?)", highlighturl)
    if not foundurl then text = text:gsub("(%s?)(%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?)(%s?)", highlighturl) end
    if not foundurl then text = text:gsub("(%s?)([%w_-]+%.?[%w_-]+%.[%w_-]+:%d%d%d?%d?%d?)(%s?)", highlighturl) end
    if not foundurl then text = text:gsub("(%s?)(%a+://[%w_/%.%?%%=~&-'%-]+)(%s?)", highlighturl) end
    if not foundurl then text = text:gsub("(%s?)(www%.[%w_/%.%?%%=~&-'%-]+)(%s?)", highlighturl) end
    if not foundurl then text = text:gsub("(%s?)([_%w-%.~-]+@[_%w-]+%.[_%w-%.]+)(%s?)", highlighturl) end
  end

  return self.am(self, text, ...)
end

-- Apply filter to all chat frames
local function applyChatHooks()
  for i = 1, NUM_CHAT_WINDOWS do
    local f = _G["ChatFrame" .. i]
    if f and not f._CombinedHook then
      f.am = f.AddMessage
      f.AddMessage = chatFilter
      f._CombinedHook = true
    end
  end
end

-- Hyperlink handler for our url links
local origHyperlink = ChatFrame_OnHyperlinkShow
ChatFrame_OnHyperlinkShow = function(frame, link, text, button)
  local type, value = link:match("(%a+):(.+)")
  if type == "url" then
    local eb = LAST_ACTIVE_CHAT_EDIT_BOX or _G[frame:GetName() .. "EditBox"]
    if eb then
      eb:SetText(value)
      eb:SetFocus()
      eb:HighlightText()
    end
  else
    origHyperlink(frame, link, text, button)
  end
end

-- Chat setup
function Roth_UI:SkinChats()
  if not cfg.enabled then return end

  chatFont = ns.Media.Font(ns.cfg.fonts.chatFont)
  chatScale = ns.cfg.fonts.chatScale

  ChatFontNormal:SetFont(chatFont, floor(12 * chatScale), "THINOUTLINE")
  ChatFontNormal:SetShadowOffset(1, -1)
  ChatFontNormal:SetShadowColor(0, 0, 0, 0.6)

  for i = 1, NUM_CHAT_WINDOWS do
    skinChat(_G["ChatFrame" .. i])
  end

  applyChatHooks()
end

-----------------------------
-- CALL
-----------------------------

local function Init()
  cfg = ns.cfg.embeds.rChat
  Roth_UI:SkinChats()

  hooksecurefunc("FCF_OpenTemporaryWindow", function()
    for _, chatFrameName in pairs(CHAT_FRAMES) do
      local frame = _G[chatFrameName]
      if frame.isTemporary then
        skinChat(frame)
        applyChatHooks()
      end
    end
  end)

  hooksecurefunc("FCF_SetChatWindowFontSize", function(self, frame, size)
    local font, _, flags = frame:GetFont()
    frame:SetFont(chatFont, floor(size * chatScale), flags or "THINOUTLINE")
  end)

  -- Custom channel prefixes
  CHAT_GUILD_GET = "|Hchannel:GUILD|hG|h %s "
  CHAT_OFFICER_GET = "|Hchannel:OFFICER|hO|h %s "
  CHAT_RAID_GET = "|Hchannel:RAID|hR|h %s "
  CHAT_RAID_WARNING_GET = "RW %s "
  CHAT_RAID_LEADER_GET = "|Hchannel:RAID|hRL|h %s "
  CHAT_PARTY_GET = "|Hchannel:PARTY|hP|h %s "
  CHAT_PARTY_LEADER_GET = "|Hchannel:PARTY|hPL|h %s "
  CHAT_PARTY_GUIDE_GET = "|Hchannel:PARTY|hPG|h %s "
  CHAT_INSTANCE_CHAT_GET = "|Hchannel:Battleground|hI.|h %s: "
  CHAT_INSTANCE_CHAT_LEADER_GET = "|Hchannel:Battleground|hIL.|h %s: "
  CHAT_WHISPER_INFORM_GET = "to %s "
  CHAT_WHISPER_GET = "from %s "
  CHAT_BN_WHISPER_INFORM_GET = "to %s "
  CHAT_BN_WHISPER_GET = "from %s "
  CHAT_SAY_GET = "%s "
  CHAT_YELL_GET = "%s "
  CHAT_FLAG_AFK = "[AFK] "
  CHAT_FLAG_DND = "[DND] "
  CHAT_FLAG_GM = "[GM] "
end

local function ResetLevelDB()
  _G.rChatLevelDB = { version = 1, ttl = (db and db.ttl) or 86400, realms = {} }
  db = _G.rChatLevelDB
  realmDB = nil
  EnsureDB()
  wipe(levelCache)

  -- Re-seed with your own level so levels keep working immediately
  TryHarvestUnit("player")

  DEFAULT_CHAT_FRAME:AddMessage("|cff66ff66rChat:|r level database reset.")
end

SLASH_RCHATLEVELRESET1 = "/rchatlevelreset"
SLASH_RCHATLEVELRESET2 = "/rclreset"
SlashCmdList.RCHATLEVELRESET = function()
  ResetLevelDB()
end

ns:RegisterInit(Init)

local rChat = {}
Roth_UI:AddConfig("embeds.rChat", rChat, "Chat", Init, true)