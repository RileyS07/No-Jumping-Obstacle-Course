-- Variables
local versionUpdatesManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

-- Initialize
function versionUpdatesManager.Initialize()
    coreModule.Shared.GetObject("//Remotes.Server.IsReservedServer").OnServerInvoke = versionUpdatesManager.IsReservedServer

    -- Is it a reserved server?
    if versionUpdatesManager.IsReservedServer() then
        teleportationManager.TeleportPlayerListPostTranslationToPlaceId(coreModule.Services.Players:GetPlayers(), game.PlaceId)
        return
    end

    -- Server shutdown.
    game:BindToClose(versionUpdatesManager.ShutdownServer)

    -- Someone joined!
    coreModule.Services.Players.PlayerAdded:Connect(function(player)
        
    end)
end


-- Methods
-- This is used to see if they're in a temporary server which is reserved for teleportation between versions.
function versionUpdatesManager.IsReservedServer()
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end


function versionUpdatesManager.ShutdownServer()
    if coreModule.Services.RunService:IsStudio() then return end
	if #coreModule.Services.Players:GetPlayers() == 0 then return end

    coreModule.Shared.GetObject("//Remotes.Server.VersionUpdated"):FireAllClients()
    
    -- Teleport them away.
    teleportationManager.TeleportPlayerListPostTranslationToPlaceId(
        coreModule.Services.Players:GetPlayers(), 
        game.PlaceId, 
        {
            ReservedServerAccessCode = coreModule.Services.TeleportService:ReserveServer(game.PlaceId)
        }
    )
end


--
return versionUpdatesManager