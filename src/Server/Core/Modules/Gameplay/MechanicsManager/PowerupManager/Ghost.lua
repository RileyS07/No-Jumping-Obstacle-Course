local collectionService: CollectionService = game:GetService("CollectionService")

local coreModule = require(script:FindFirstAncestor("Core"))
local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))

local thisPowerupStorage: Instance = workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]

local ThisPowerupManager = {}

-- Initialize
function ThisPowerupManager.Initialize()

    -- We do not have to acknowledge the paint powerup here if it exists.
    physicsService.CollisionGroupSetCollidable("Ghosts", "Ghosts", false)
    physicsService.CollisionGroupSetCollidable("Ghosts", "Players", false)
    physicsService.CollisionGroupSetCollidable("Ghosts", "GhostsNoCollide", false)

    -- This is the actual functionality behind the ghost powerup.
    if thisPowerupStorage:FindFirstChild("AccessableParts") then
        physicsService.SetCollectionsCollisionGroup(thisPowerupStorage.AccessableParts:GetChildren(), "GhostsNoCollide")
    end

    -- This will be called when the powerup is removed from a character.
    -- The main powerup system handles all of this.
    collectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)

        local player: Player? = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        -- We have to do a special exception for Paint powerup.
        -- If they have the paint powerup after the ghost powerup is finished we just set it back to the paint collision.
        if powerupsManager.GetPowerupInformation(player, "Paint") then
            physicsService.SetCollectionsCollisionGroup(
                player.Character:GetChildren(),
                powerupsManager.GetPowerupInformation(player, "Paint").PlatformName
            )
        else
            physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Players")
        end

        -- Making them visible.
		for _, child: Instance in next, character:GetDescendants() do
			if child:IsA("BasePart") and child.Transparency ~= 1 then
				child.Transparency = 0
			end
		end
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player)

    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We have to do a special exception for Paint powerup.
    -- If we're adding ghost ontop of paint it's `paintTypeGhost`.
    if powerupsManager.GetPowerupInformation(player, "Paint") then
        physicsService.SetCollectionsCollisionGroup(
            player.Character:GetChildren(),
            powerupsManager.GetPowerupInformation(player, "Paint").PlatformName .. "Ghost"
        )
    else
        physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Ghosts")
    end

    -- Making them invisible.
    for _, basePart: Instance in next, player.Character:GetDescendants() do
		if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
			basePart.Transparency = 0.5
		end
	end
end

return ThisPowerupManager
