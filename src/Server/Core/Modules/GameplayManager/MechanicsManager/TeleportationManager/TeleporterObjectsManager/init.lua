-- Variables
local teleporterObjectsManager = {}
teleporterObjectsManager.WaitingForPlayerConsent = {}
teleporterObjectsManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function teleporterObjectsManager.Initialize()
    if not teleporterObjectsManager.GetTeleportersContainer() then return end

    -- Setup.
    teleporterObjectsManager.Remotes.GetTeleportationConsent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.GetTeleportationConsent")
    
    -- Loading modules.
    coreModule.LoadModule("/BonusStages")
end


-- Methods
function teleporterObjectsManager.GetTeleportationConsent(player, title, description, imageContent)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if teleporterObjectsManager.IsWaitingOnPlayerConsent(player) then return end
    teleporterObjectsManager.WaitingForPlayerConsent[player] = true

    -- GetTeleportationConsent pops up a gui on the clients screen waiting for them to click yes/no.
    local teleportationConsentStatus = teleporterObjectsManager.Remotes.GetTeleportationConsent:InvokeClient(player, title, description, imageContent)
    teleporterObjectsManager.WaitingForPlayerConsent[player] = nil
    return teleportationConsentStatus
end


function teleporterObjectsManager.IsWaitingOnPlayerConsent(player)
    return teleporterObjectsManager.WaitingForPlayerConsent[player]
end


function teleporterObjectsManager.GetTeleportersContainer()
    return workspace.Map.Gameplay:FindFirstChild("Teleporters")
end


--
return teleporterObjectsManager