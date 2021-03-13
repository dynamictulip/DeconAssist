DeconAssist = {}

DeconAssist.name = "DeconAssist"

function DeconAssist:StoreBagItemsThatCouldBeDeconstructed(craftStationType, bagId)
  local maxSlotNumber = GetBagSize(bagId)
  DeconAssist.itemsThatCouldBeDeconstructed[bagId] = {}


  for i = 1, maxSlotNumber do
    if  CanItemBeSmithingExtractedOrRefined(bagId, i, craftStationType)
    and not IsItemPlayerLocked(bagId, i)
    then
      local link = GetItemLink(bagId, i)

      d("You can deconstruct/refine "..link)
    end
  end

end

--EVENT_CRAFT_STARTED (integer craftSkill)
-- This event fires whenever the user presses a button to begin crafting an item, or any other action that can be taken at a crafting station.
-- craftSkill will be one of these values:
  -- CRAFTING_TYPE_INVALID = 0
  -- CRAFTING_TYPE_BLACKSMITHING = 1
  -- CRAFTING_TYPE_CLOTHIER = 2
  -- CRAFTING_TYPE_ENCHANTING = 3
  -- CRAFTING_TYPE_ALCHEMY = 4
  -- CRAFTING_TYPE_PROVISIONING = 5
  -- CRAFTING_TYPE_WOODWORKING = 6
function DeconAssist:OnCraftingStarted(craftStationType)

  if craftStationType == CRAFTING_TYPE_ALCHEMY or craftStationType == CRAFTING_TYPE_PROVISIONING then
    return
  end

  d("Started crafting " .. craftStationType)

  --Clear local bag store
  DeconAssist.itemsThatCouldBeDeconstructed = {}

  -- Store the items that could be deconstructed - i.e. backpack and bank
  DeconAssist:StoreBagItemsThatCouldBeDeconstructed(craftStationType, BAG_BACKPACK)
  DeconAssist:StoreBagItemsThatCouldBeDeconstructed(craftStationType, BAG_BANK)

end

--user:/AddOns/DeconAssist/DeconAssist.lua:32: attempt to index a number value
-- stack traceback:
-- user:/AddOns/DeconAssist/DeconAssist.lua:32: in function 'DeconAssist:OnCraftingCompleted'
-- <Locals> self = 131535, craftSkill = 3 </Locals>

--EVENT_CRAFT_COMPLETED (integer craftSkill)
-- This event fires whenever the player finishes crafting an item, or if crafting is interrupted (For example, if the player leaves the station) also fires when an item is deconstructed.
-- craftSkill will be one of these values:
  -- CRAFTING_TYPE_INVALID = 0
  -- CRAFTING_TYPE_BLACKSMITHING = 1
  -- CRAFTING_TYPE_CLOTHIER = 2
  -- CRAFTING_TYPE_ENCHANTING = 3
  -- CRAFTING_TYPE_ALCHEMY = 4
  -- CRAFTING_TYPE_PROVISIONING = 5
  -- CRAFTING_TYPE_WOODWORKING = 6
function DeconAssist:OnCraftingCompleted(craftSkill)
  d("Completed crafting " .. craftSkill)
  DeconAssist.IsCrafting = false
end

--local function _onInventoryChanged(eventCode, bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
function DeconAssist:OnInventoryChange(bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  local link = GetItemLink(bagId, slotIndex)

  if updateReason == INVENTORY_UPDATE_REASON_DEFAULT and stackCountChange > 0 then
    d("bagId " .. bagId ..", slotIndex" .. slotIndex ..", itemSoundCategory" .. itemSoundCategory ..", updateReason "..updateReason..", stackCountChange"..stackCountChange)
    d("Picked up a " .. link .. ".")
  end


-- INVENTORY_UPDATE_REASON_DEFAULT 0
-- INVENTORY_UPDATE_REASON_DURABILITY_CHANGE 1
-- INVENTORY_UPDATE_REASON_DYE_CHANGE 2
-- INVENTORY_UPDATE_REASON_ITEM_CHARGE 3
-- INVENTORY_UPDATE_REASON_ITERATION_BEGIN 0
-- INVENTORY_UPDATE_REASON_ITERATION_END 4
-- INVENTORY_UPDATE_REASON_MAX_VALUE 4
-- INVENTORY_UPDATE_REASON_MIN_VALUE 0
-- INVENTORY_UPDATE_REASON_PLAYER_LOCKED 4

-- BAG_BACKPACK 1 <- this is the normal bag
-- BAG_BANK 2
-- BAG_BUYBACK 4
-- BAG_DELETE 17
-- BAG_GUILDBANK 3
-- BAG_HOUSE_BANK_EIGHT 14
-- BAG_HOUSE_BANK_FIVE 11
-- BAG_HOUSE_BANK_FOUR 10
-- BAG_HOUSE_BANK_NINE 15
-- BAG_HOUSE_BANK_ONE 7
-- BAG_HOUSE_BANK_SEVEN 13
-- BAG_HOUSE_BANK_SIX 12
-- BAG_HOUSE_BANK_TEN 16
-- BAG_HOUSE_BANK_THREE 9
-- BAG_HOUSE_BANK_TWO 8
-- BAG_ITERATION_BEGIN 0
-- BAG_ITERATION_END 16
-- BAG_MAX_VALUE 17
-- BAG_MIN_VALUE 0
-- BAG_SUBSCRIBER_BANK 6
-- BAG_VIRTUAL 5 <- this is the crafting bag
-- BAG_WORN 0

end

function DeconAssist:Initialize()
  -- We'll need to know when crafting is happening
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_STARTED, self.OnCraftingStarted)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_COMPLETED, self.OnCraftingCompleted)
  -- We'll also need to know which items have changed so we can work out what's happened!
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, self.OnInventoryChange)
  
  -- Set up initial variable structure
  self.savedVariables = ZO_SavedVars:NewAccountWide("DeconAssistSavedVariables", 1, nil, {})
end

function DeconAssist.OnAddOnLoaded(event, addonName)
    if addonName == DeconAssist.name then
        DeconAssist:Initialize()
        EVENT_MANAGER:UnregisterForEvent(DeconAssist.name, EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent(DeconAssist.name, EVENT_ADD_ON_LOADED, DeconAssist.OnAddOnLoaded)