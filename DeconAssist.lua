DeconAssist = {}

DeconAssist.name = "DeconAssist"

function DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType, bagId)

  local maxSlotNumber = GetBagSize(bagId)
  local itemsThatCouldBeDeconstructedInThisBag = {}

  for i = 1, maxSlotNumber do
    if CanItemBeSmithingExtractedOrRefined(bagId, i, craftStationType) and not IsItemPlayerLocked(bagId, i) then
      local link = GetItemLink(bagId, i)

      itemsThatCouldBeDeconstructedInThisBag[i] = link
    end
  end

  return itemsThatCouldBeDeconstructedInThisBag
end

function DeconAssist:WorkOutWhatWasDeconstructed(craftStationType, bagId)
  local itemsThatStillExist = DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType, bagId)

  --Remove items that still exist from the list
  for i, v in pairs(itemsThatStillExist) do
    DeconAssist.itemsThatCouldBeDeconstructed[bagId][i] = nil
  end

  --Whatever is left is what has been deconstructed
  for i, v in pairs(DeconAssist.itemsThatCouldBeDeconstructed[bagId]) do
    d("You deconstructed "..v)
  end
end

function DeconAssist:OnCraftingStarted(craftStationType)
  --Deconstruction doesn't happen in Alchemy or Provisioning
  if craftStationType == CRAFTING_TYPE_ALCHEMY or craftStationType == CRAFTING_TYPE_PROVISIONING then
    return
  end

  d("Started crafting " .. craftStationType)
  DeconAssist.isCrafting = true

  --Clear local bag store
  DeconAssist.itemsThatCouldBeDeconstructed = {}

  -- Store the items that could be deconstructed - i.e. backpack and bank
  DeconAssist.itemsThatCouldBeDeconstructed[BAG_BACKPACK] = DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType, BAG_BACKPACK)
  DeconAssist.itemsThatCouldBeDeconstructed[BAG_BANK] = DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType, BAG_BANK)

end

function DeconAssist:OnCraftingCompleted(craftStationType)
  
  if craftStationType == CRAFTING_TYPE_ALCHEMY or craftStationType == CRAFTING_TYPE_PROVISIONING then
    return
  end

  --Work out what was deconstructed
  DeconAssist:WorkOutWhatWasDeconstructed(craftStationType, BAG_BACKPACK)
  DeconAssist:WorkOutWhatWasDeconstructed(craftStationType, BAG_BANK)

  d("Completed crafting " .. craftStationType)
  DeconAssist.isCrafting = false

end

function DeconAssist:OnInventoryChange(bagId, slotIndex, isNewItem, itemSoundCategory, updateReason, stackCountChange)
  local link = GetItemLink(bagId, slotIndex)

  if DeconAssist.isCrafting and updateReason == INVENTORY_UPDATE_REASON_DEFAULT and stackCountChange > 0 then
    d("You got a " .. link .. ".")
  end

end

function DeconAssist:Initialize()
  -- We'll need to know when crafting is happening
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_STARTED, self.OnCraftingStarted)
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_COMPLETED, self.OnCraftingCompleted)
  -- We'll also need to know which items have changed so we can work out what's happened!
  EVENT_MANAGER:RegisterForEvent(self.name, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, self.OnInventoryChange)

  --initialise local variables
  DeconAssist.isCrafting = false

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