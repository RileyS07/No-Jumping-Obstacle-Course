local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local ThisPowerupManager = {}

-- Initialize
function ThisPowerupManager.Initialize()

    -- This will be called when the powerup is removed from a character.
    -- The main powerup system handles all of this.
    collectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character: Model)

        -- There might be a situation where the ForceField was already destroyed somehow.
        local player: Player? = players:GetPlayerFromCharacter(character)

		if not playerUtilities.IsPlayerAlive(player) then return end
        if not character:FindFirstChildOfClass("ForceField") then return end

        -- It exists so we want to remove it when the powerup is removed.
        character:FindFirstChildOfClass("ForceField"):Destroy()
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player)

    if not playerUtilities.IsPlayerAlive(player) then return end
    if player.Character:FindFirstChild("ForceField") then return end

    Instance.new("ForceField").Parent = player.Character
end

return ThisPowerupManager
