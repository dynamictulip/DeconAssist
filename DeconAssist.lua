DeconAssist = {}

--[[
  Made by Sara (confuddled_squirrel)

  Features:
  - saves a record of mats gained from deconstructing items

  Future features:
  - UI to see stats
  - Tooltip addition on item hover to show deconstruction mats probabilities
  - Consider using libSavedVars - https://github.com/silvereyes333/LibSavedVars
  - Option to see items in chat - use https://github.com/silvereyes333/LibLootSummary

  Known bugs:
  - will give strange results when deconstructing multiple items at a time
]]

DeconAssist.name = "DeconAssist"
DeconAssist.variableVersion = 3
DeconAssist.default = {}

--[[
  {
    <crafting station type1> = {
      <item1> = {
        "count" = <x>
        "items" = {
          <item1> = <x>,
          <item2> = <x>,
        }
      }
    }
  }
--]]

function DeconAssist:SetUpSavedVarTable(var)
    if var == nil then var = {} end
    return var
end

function DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType, bagId)

    local maxSlotNumber = GetBagSize(bagId)
    local itemsThatCouldBeDeconstructedInThisBag = {}

    for i = 1, maxSlotNumber do
        if CanItemBeSmithingExtractedOrRefined(bagId, i, craftStationType) and
            not IsItemPlayerLocked(bagId, i) then
            local link = GetItemLink(bagId, i)

            itemsThatCouldBeDeconstructedInThisBag[i] = link
        end
    end

    return itemsThatCouldBeDeconstructedInThisBag
end

function DeconAssist:WorkOutWhatWasDeconstructed(craftStationType, bagId)
    local itemsThatStillExist = DeconAssist:GetBagItemsThatCouldBeDeconstructed(
                                    craftStationType, bagId)

    -- Remove items that still exist from the list
    for i, v in pairs(itemsThatStillExist) do
        DeconAssist.itemsThatCouldBeDeconstructed[bagId][i] = nil
    end

    -- Whatever is left is what has been deconstructed
    for i, v in pairs(DeconAssist.itemsThatCouldBeDeconstructed[bagId]) do
        -- d("You deconstructed "..v)
        return v
    end
end

function DeconAssist:OnCraftingStarted(craftStationType)
    -- Deconstruction doesn't happen in Alchemy or Provisioning
    if craftStationType == CRAFTING_TYPE_ALCHEMY or craftStationType ==
        CRAFTING_TYPE_PROVISIONING then return end

    -- set up this crafting station var if first time
    DeconAssist.savedVariables[craftStationType] =
        DeconAssist:SetUpSavedVarTable(
            DeconAssist.savedVariables[craftStationType])

    -- d("Started crafting " .. craftStationType)

    -- reset transient variables
    DeconAssist.isCrafting = true
    DeconAssist.gotItems = {}
    DeconAssist.itemsThatCouldBeDeconstructed = {}

    -- Store the items that could be deconstructed - i.e. backpack and bank
    DeconAssist.itemsThatCouldBeDeconstructed[BAG_BACKPACK] =
        DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType,
                                                        BAG_BACKPACK)
    DeconAssist.itemsThatCouldBeDeconstructed[BAG_BANK] =
        DeconAssist:GetBagItemsThatCouldBeDeconstructed(craftStationType,
                                                        BAG_BANK)

end

function DeconAssist:OnCraftingCompleted(craftStationType)

    if craftStationType == CRAFTING_TYPE_ALCHEMY or craftStationType ==
        CRAFTING_TYPE_PROVISIONING then return end

    DeconAssist:ShowUI(true)

    -- Work out what was deconstructed
    local deconstructedItem = DeconAssist:WorkOutWhatWasDeconstructed(
                                  craftStationType, BAG_BACKPACK)
    if deconstructedItem == nil then
        deconstructedItem = DeconAssist:WorkOutWhatWasDeconstructed(
                                craftStationType, BAG_BANK)
    end

    -- Save results from a deconstructed item
    if deconstructedItem ~= nil then
        -- Set up deconstructed item in saved vars
        DeconAssist.savedVariables[craftStationType][deconstructedItem] =
            DeconAssist:SetUpSavedVarTable(
                DeconAssist.savedVariables[craftStationType][deconstructedItem])
        DeconAssist.savedVariables[craftStationType][deconstructedItem].Items =
            DeconAssist:SetUpSavedVarTable(
                DeconAssist.savedVariables[craftStationType][deconstructedItem]
                    .Items)

        -- Increase count of this deconstructed item
        if DeconAssist.savedVariables[craftStationType][deconstructedItem].Count ==
            nil then
            DeconAssist.savedVariables[craftStationType][deconstructedItem]
                .Count = 1
        else
            DeconAssist.savedVariables[craftStationType][deconstructedItem]
                .Count =
                DeconAssist.savedVariables[craftStationType][deconstructedItem]
                    .Count + 1
        end

        -- Store materials retrieved from deconstructing this item
        for index, value in ipairs(DeconAssist.gotItems) do
            if DeconAssist.savedVariables[craftStationType][deconstructedItem]
                .Items[value] == nil then
                DeconAssist.savedVariables[craftStationType][deconstructedItem]
                    .Items[value] = 1
            else
                DeconAssist.savedVariables[craftStationType][deconstructedItem]
                    .Items[value] = 1 +
                                        DeconAssist.savedVariables[craftStationType][deconstructedItem]
                                            .Items[value]
            end
        end
    end

    -- d("Completed crafting " .. craftStationType)
    DeconAssist.isCrafting = false

end

function DeconAssist:OnInventoryChange(bagId, slotIndex, isNewItem,
                                       itemSoundCategory, updateReason,
                                       stackCountChange)
    local link = GetItemLink(bagId, slotIndex)

    if DeconAssist.isCrafting and updateReason ==
        INVENTORY_UPDATE_REASON_DEFAULT and stackCountChange > 0 then
        -- d("You got a " .. link .. ".")
        table.insert(DeconAssist.gotItems, link)
    end
end

function DeconAssist:ShowUI(show)
    d("Trying to show " .. tostring(show))
    DeconAssistHistory:SetHidden(not show)
end
function DeconAssist:ShowUI_buttonclick() DeconAssist:ShowUI(true) end
function DeconAssist:HideUI_buttonclick() DeconAssist:ShowUI(false) end

function DeconAssist:Initialize()
    -- We'll need to know when crafting is happening
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_STARTED,
                                   self.OnCraftingStarted)
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CRAFT_COMPLETED,
                                   self.OnCraftingCompleted)
    -- We'll also need to know which items have changed so we can work out what's happened!
    EVENT_MANAGER:RegisterForEvent(self.name,
                                   EVENT_INVENTORY_SINGLE_SLOT_UPDATE,
                                   self.OnInventoryChange)

    -- initialise local variables
    DeconAssist.isCrafting = false

    -- Set up initial variable structure
    DeconAssist.savedVariables = ZO_SavedVars:NewAccountWide(
                                     "DeconAssistSavedVariables",
                                     DeconAssist.variableVersion, nil,
                                     DeconAssist.default)

    -- DeconAssist:ShowUI(false)
end

function DeconAssist.OnAddOnLoaded(event, addonName)
    if addonName == DeconAssist.name then
        DeconAssist:Initialize()
        EVENT_MANAGER:UnregisterForEvent(DeconAssist.name, EVENT_ADD_ON_LOADED)
    end
end

EVENT_MANAGER:RegisterForEvent(DeconAssist.name, EVENT_ADD_ON_LOADED,
                               DeconAssist.OnAddOnLoaded)
