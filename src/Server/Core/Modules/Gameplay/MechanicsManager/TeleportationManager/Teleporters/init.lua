local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local getTeleportationConsentRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.GetTeleportationConsent")

local TeleportersManager = {}
TeleportersManager.WaitingForPlayerConsent = {}

-- Initialize
function TeleportersManager.Initialize()
    if not TeleportersManager.GetTeleportersContainer() then return end

    coreModule.LoadModule("/")
end

-- This method will communicate with the client and see if they agree to being teleported.
function TeleportersManager.GetTeleportationConsent(player: Player, description: string) : boolean

    -- We can't teleport them if they're already teleporting.
    if not playerUtilities.IsPlayerAlive(player) then return end
    if TeleportersManager.GetIsWaitingOnPlayerConsent(player) then return end

    -- We can start asking if they want to be teleported.
    TeleportersManager.SetIsWaitingOnPlayerConsent(player, true)

    -- GetTeleportationConsent pops up a gui on the clients screen waiting for them to click yes/no.
    local teleportationConsentStatus = getTeleportationConsentRemote:InvokeClient(player, description)

    TeleportersManager.SetIsWaitingOnPlayerConsent(player, false)
    return teleportationConsentStatus
end

-- Returns whether or not the player is being waited on.
function TeleportersManager.GetIsWaitingOnPlayerConsent(player: Player) : boolean
    return not not TeleportersManager.WaitingForPlayerConsent[player]
end

-- Sets whether or not the player is being waited on
function TeleportersManager.SetIsWaitingOnPlayerConsent(player: Player, isWaiting: boolean)
    TeleportersManager.WaitingForPlayerConsent[player] = if isWaiting then true else nil
end

-- Returns the Teleporters instance in Workspace.
function TeleportersManager.GetTeleportersContainer() : Instance?
    return workspace.Map.Gameplay:FindFirstChild("Teleporters")
end

return TeleportersManager
