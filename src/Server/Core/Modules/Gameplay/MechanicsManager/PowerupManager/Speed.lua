local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")
local starterPlayer: StarterPlayer = game:GetService("StarterPlayer")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local ThisPowerupManager = {}

-- Initialize
function ThisPowerupManager.Initialize()

    -- This will be called when the powerup is removed from a character.
    -- The main powerup system handles all of this.
    collectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character: Model)

        local player: Player? = players:GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        -- We use the default set in StarterPlayer in case we ever want to change it.
        player.Character.Humanoid.WalkSpeed = starterPlayer.CharacterWalkSpeed
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player, thisPowerup: Instance)

    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We use the default set in StarterPlayer in case we ever want to change it.
    player.Character.Humanoid.WalkSpeed =
        starterPlayer.CharacterWalkSpeed
        * (thisPowerup:GetAttribute("Multiplier") or sharedConstants.MECEHANICS.SPEED_POWERUP_DEFAULT_MULTIPLIER)
end

return ThisPowerupManager
