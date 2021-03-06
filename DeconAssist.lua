DeconAssist = {}

DeconAssist.name = "DeconAssist"

function DeconAssist.OnPlayerCombatState(event, inCombat)
    if inCombat ~= DeconAssist.inCombat then
      DeconAssist.inCombat = inCombat
   
      if inCombat then
        d("You are about to rock at combat.")
      else
        d("You totally rocked at combat.")
      end

      DeconAssistIndicator:SetHidden(not inCombat)
    end
end

function DeconAssist:RestorePosition()
    local left = self.savedVariables.left
    local top = self.savedVariables.top
   
    DeconAssistIndicator:ClearAnchors()
    DeconAssistIndicator:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, left, top)
end

function DeconAssist.OnIndicatorMoveStop()
    DeconAssist.savedVariables.left = DeconAssistIndicator:GetLeft()
    DeconAssist.savedVariables.top = DeconAssistIndicator:GetTop()
end

function DeconAssist:Initialize()
    self.inCombat = IsUnitInCombat("player")

    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, self.OnPlayerCombatState)

    self.savedVariables = ZO_SavedVars:NewAccountWide("DeconAssistSavedVariables", 1, nil, {})
    self:RestorePosition()
end

function DeconAssist.OnAddOnLoaded(event, addonName)
    if addonName == DeconAssist.name then
        DeconAssist:Initialize()
    end
end

EVENT_MANAGER:RegisterForEvent(DeconAssist.name, EVENT_ADD_ON_LOADED, DeconAssist.OnAddOnLoaded)