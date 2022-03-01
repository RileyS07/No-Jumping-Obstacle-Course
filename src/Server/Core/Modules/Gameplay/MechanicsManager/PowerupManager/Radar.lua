local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local radarStatusUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RadarStatusUpdated")

local ThisPowerupManager = {}

-- Initialize
function ThisPowerupManager.Initialize()

    -- This will be called when the powerup is removed from a character.
    -- The main powerup system handles all of this.
    collectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character: Model)

        local player: Player? = players:GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        -- We tell the client to update the radar to clear any parts.
        radarStatusUpdatedRemote:FireClient(player)
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player, thisPowerup: Instance)

    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We can't render anything if these collection doesn't exist.
    if not thisPowerup:FindFirstChild("AccessableParts") then return end

    -- We tell the client to update the radar to show these parts.
    radarStatusUpdatedRemote:FireClient(player, thisPowerup.AccessableParts:GetChildren())
end

return ThisPowerupManager
