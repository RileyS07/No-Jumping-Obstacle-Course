-- Variables
local versionUpdatesManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local teleportationManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.TeleportationManager"))

-- Initialize
function versionUpdatesManager.Initialize()
    coreModule.Shared.GetObject("//Remotes.Server.IsReservedServer").OnServerInvoke = versionUpdatesManager.IsReservedServer

    -- Someone joined!
    coreModule.Services.Players.PlayerAdded:Connect(function(player)
        if not versionUpdatesManager.IsReservedServer() then return end
        teleportationManager.TeleportPlayerListPostTranslationToPlaceId({player}, game.PlaceId)
    end)

    -- Is it a reserved server?
    if versionUpdatesManager.IsReservedServer() then
        teleportationManager.TeleportPlayerListPostTranslationToPlaceId(coreModule.Services.Players:GetPlayers(), game.PlaceId)
        return
    end

    -- Server shutdown.
    if not coreModule.Services.RunService:IsStudio() then
        game:BindToClose(versionUpdatesManager.ShutdownServer)
    end
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
    local reservedServerAccessCode = coreModule.Services.TeleportService:ReserveServer(game.PlaceId)

    teleportationManager.TeleportPlayerListPostTranslationToPlaceId(
        coreModule.Services.Players:GetPlayers(), game.PlaceId, {ReservedServerAccessCode = reservedServerAccessCode}
    )

    -- Someone joined!
    coreModule.Services.Players.PlayerAdded:Connect(function(player)
        if not versionUpdatesManager.IsReservedServer() then return end
        teleportationManager.TeleportPlayerListPostTranslationToPlaceId(
            coreModule.Services.Players:GetPlayers(), game.PlaceId, {ReservedServerAccessCode = reservedServerAccessCode}
        )
    end)
end


--
return versionUpdatesManager