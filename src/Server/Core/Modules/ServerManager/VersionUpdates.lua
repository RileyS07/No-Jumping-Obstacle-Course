--[[
    This module's purpose is to implement a soft shutdown system.
    When a server is shutdown instead of having them go to the default rejoin button,
    we teleport them to a new reserved server and then back to a new updated server.
]]

local players: Players = game:GetService("Players")
local runService: RunService = game:GetService("RunService")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local teleportService = require(coreModule.Shared.GetObject("Libraries.Services.TeleportService"))

local VersionUpdatesManager = {}
VersionUpdatesManager.ReservedServerCode = ""

-- Initialize
function VersionUpdatesManager.Initialize()
    coreModule.Shared.GetObject("//Remotes.Server.IsReservedServer").OnServerInvoke = VersionUpdatesManager.IsReservedServer

    -- This server is a reserved server, so that means it's one that we created.
    -- So we send them back to the original game.
    if VersionUpdatesManager.IsReservedServer() then
        playerUtilities.CreatePlayerAddedWrapper(function(player: Player)
            if not playerUtilities.IsPlayerValid(player) then return end
            teleportService.TeleportAsync(game.PlaceId, {player})
        end)

        return
    end

    -- Server shutdown.
    if not runService:IsStudio() then
        game:BindToClose(VersionUpdatesManager.ShutdownServer)
    end
end

-- This is used to see if they're in a temporary server which is reserved for teleportation between versions.
function VersionUpdatesManager.IsReservedServer()
    return game.PrivateServerId ~= "" and game.PrivateServerOwnerId == 0
end

-- Teleports everyone in this server to a new reserved server.
-- The system will teleport them back into the game after this.
function VersionUpdatesManager.ShutdownServer()
    if runService:IsStudio() or #players:GetPlayers() == 0 then return end

    -- We only want to create one reserved server if possible so that all players can stick together.
    if VersionUpdatesManager.ReservedServerCode == "" then
        VersionUpdatesManager.ReservedServerCode = teleportService.ReserveServer(game.PlaceId)
    end

    -- We want to update the clients to tell them that they're leaving and also teleport them away.
    playerUtilities.CreatePlayerAddedWrapper(function(player: Player)
        if not playerUtilities.IsPlayerValid(player) then return end

        -- There are players we need to teleport
        coreModule.Shared.GetObject("//Remotes.Server.VersionUpdated"):FireClient(player)

        teleportService.TeleportAsync(
            game.PlaceId,
            {player},
            teleportService.CreateTeleportOptions(VersionUpdatesManager.ReservedServerCode)
        )
    end)
end

return VersionUpdatesManager
