-- Roth_UI/embeds/rCooldown/availability.lua
-- Spell known + item ownership/equipped detection (Classic-safe + C_Container-safe)
-- Adds CanDisplayEntry() to support "shift positions when unavailable" behavior.

local addon, ns = ...
local RC = ns.rCooldown
if not RC then return end

RC.Availability = RC.Availability or {}
local AV = RC.Availability

AV._spellKnown     = AV._spellKnown or {}
AV._itemOwned      = AV._itemOwned  or {}
AV._itemEquipped   = AV._itemEquipped or {}
AV._itemEquippable = AV._itemEquippable or {}

-- ---------------------------------------------------------------------
-- Bag API compatibility
-- ---------------------------------------------------------------------
local function BagNumSlots(bag)
  if C_Container and C_Container.GetContainerNumSlots then
    return C_Container.GetContainerNumSlots(bag)
  end
  if GetContainerNumSlots then
    return GetContainerNumSlots(bag)
  end
  return 0
end

local function BagItemLink(bag, slot)
  if C_Container and C_Container.GetContainerItemLink then
    return C_Container.GetContainerItemLink(bag, slot)
  end
  if GetContainerItemLink then
    return GetContainerItemLink(bag, slot)
  end
  return nil
end

local function BagItemID(bag, slot)
  if C_Container and C_Container.GetContainerItemID then
    return C_Container.GetContainerItemID(bag, slot)
  end
  if GetContainerItemID then
    return GetContainerItemID(bag, slot)
  end
  local link = BagItemLink(bag, slot)
  if link then
    return tonumber(link:match("item:(%d+)"))
  end
  return nil
end

-- ---------------------------------------------------------------------
-- Spell availability
-- ---------------------------------------------------------------------
local function ClearSpellCache()
  wipe(AV._spellKnown)
end

local function IsSpellKnownModern(spellID)
  if type(IsSpellKnown) == "function" then
    return IsSpellKnown(spellID) == true
  end
  return nil
end

local function IsSpellKnownClassic(spellID)
  if not spellID then return false end

  local spellName = GetSpellInfo(spellID)
  if not spellName then return false end

  local tabs = GetNumSpellTabs and GetNumSpellTabs() or 0
  for i = 1, tabs do
    local _, _, offset, numSpells = GetSpellTabInfo(i)
    for s = 1, numSpells do
      local index = offset + s
      local name = GetSpellBookItemName(index, "spell")
      if name and name == spellName then
        return true
      end
    end
  end

  return false
end

function AV:IsSpellKnown(spellID)
  if not spellID then return false end
  if self._spellKnown[spellID] ~= nil then
    return self._spellKnown[spellID]
  end

  local known = IsSpellKnownModern(spellID)
  if known == nil then
    known = IsSpellKnownClassic(spellID)
  end

  self._spellKnown[spellID] = (known == true)
  return self._spellKnown[spellID]
end

-- ---------------------------------------------------------------------
-- Item: equippable detection
-- ---------------------------------------------------------------------
local function ItemEquipLoc(itemID)
  if GetItemInfoInstant then
    local _, _, _, equipLoc = GetItemInfoInstant(itemID)
    return equipLoc
  end
  if GetItemInfo then
    local _, _, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
    return equipLoc
  end
  return nil
end

function AV:IsItemEquippable(itemID)
  if not itemID then return false end
  if self._itemEquippable[itemID] ~= nil then
    return self._itemEquippable[itemID]
  end

  local equipLoc = ItemEquipLoc(itemID)
  local equippable = (type(equipLoc) == "string" and equipLoc ~= "")

  self._itemEquippable[itemID] = equippable
  return equippable
end

-- ---------------------------------------------------------------------
-- Item ownership / equipped
-- ---------------------------------------------------------------------
local function ClearItemCache()
  wipe(AV._itemOwned)
  wipe(AV._itemEquipped)
  wipe(AV._itemEquippable)
end

local function IsEquipped(itemID)
  for slot = 1, 19 do
    local id = GetInventoryItemID("player", slot)
    if id == itemID then
      return true
    end
  end
  return false
end

local function IsOwned(itemID)
  if IsEquipped(itemID) then
    return true
  end

  for bag = 0, 4 do
    local slots = BagNumSlots(bag) or 0
    for slot = 1, slots do
      local id = BagItemID(bag, slot)
      if id == itemID then
        return true
      end
    end
  end

  return false
end

function AV:IsItemEquipped(itemID)
  if not itemID then return false end
  if self._itemEquipped[itemID] ~= nil then
    return self._itemEquipped[itemID]
  end
  local eq = IsEquipped(itemID)
  self._itemEquipped[itemID] = (eq == true)
  return self._itemEquipped[itemID]
end

function AV:IsItemOwned(itemID)
  if not itemID then return false end
  if self._itemOwned[itemID] ~= nil then
    return self._itemOwned[itemID]
  end
  local owned = IsOwned(itemID)
  self._itemOwned[itemID] = (owned == true)
  return self._itemOwned[itemID]
end

-- ---------------------------------------------------------------------
-- Unified rules:
-- - spells must be learned
-- - equippable items must be equipped (treated as "unknown" if not)
-- - non-equippable items must be owned (consumables)
-- - entry.equippedOnly enforces equipped for equippables only
-- ---------------------------------------------------------------------
function AV:CanDisplayEntry(entry)
  if not entry or not entry.type then return false end

  if entry.type == "spell" then
    return self:IsSpellKnown(entry.id)
  elseif entry.type == "item" then
    local equippable = self:IsItemEquippable(entry.id)

    if equippable then
      -- Your new rule: equippable on-use items are "unknown" unless equipped
      return self:IsItemEquipped(entry.id)
    else
      -- Consumables (pots, stones) remain displayable if owned
      return self:IsItemOwned(entry.id)
    end
  end

  return false
end

-- legacy: "has entry" (owned OR equipped) for items; keep for other uses if needed
function AV:HasEntry(entry)
  if not entry or not entry.type then
    return false
  end
  if entry.type == "spell" then
    return self:IsSpellKnown(entry.id)
  elseif entry.type == "item" then
    return self:IsItemOwned(entry.id)
  end
  return false
end

function AV:Init()
  ClearSpellCache()
  ClearItemCache()
end

function AV:Refresh()
  ClearSpellCache()
  ClearItemCache()
end