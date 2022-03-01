local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
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
        if not character.PrimaryPart:FindFirstChildOfClass("BodyForce") then return end

        -- We destroy it if it exists!
        character.PrimaryPart:FindFirstChildOfClass("BodyForce"):Destroy()
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player, thisPowerup: Instance)

    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We need to either find it or create it.
    local thisBodyForce: BodyForce = player.Character.PrimaryPart:FindFirstChildOfClass("BodyForce")

    if not thisBodyForce then
        thisBodyForce = Instance.new("BodyForce")
        thisBodyForce.Parent = player.Character.PrimaryPart
    end

    -- Now we need to assign a force to it.
    -- The amount of force it applies it based on the gravity in workspace and the user's mass.
    -- Do keep in mind that the force is not constant the entire way up, it will work towards it's terminal velocity.
    -- https://en.wikipedia.org/wiki/Terminal_velocity
    -- Gravity * Multiplier * CharacterMass.
    thisBodyForce.Force = Vector3.new(
        0,
        workspace.Gravity
            * (thisPowerup:GetAttribute("Force") or sharedConstants.MECHANICS.GRAVITY_POWERUP_DEFAULT_FORCE)
            * instanceUtilities.GetMass(player.Character),
        0
    )
end

return ThisPowerupManager
