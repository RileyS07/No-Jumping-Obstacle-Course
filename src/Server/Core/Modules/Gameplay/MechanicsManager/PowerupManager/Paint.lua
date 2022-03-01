local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local thisPowerupStorage: Instance = workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]

local ThisPowerupManager = {}

-- Initialize
function ThisPowerupManager.Initialize()

    --[[
        We need to do a lot of setup for collisions here.
        - paintType x paintType
        - paintType x painTypePart
        - paintType x Players
        - paintType x Ghosts
        - paintTypeGhost x paintTypeGhost
        - paintTypeGhost x Ghosts
        - paintTypeGhost x Players
        - paintTypeGhost x paintTypePart
        - paintTypeGhost x GhostsNoCollide
        - paintType x otherPaintType
        - paintTypeGhost x otherPaintTypeGhost
    ]]

    for _, thisPowerup: Instance in next, thisPowerupStorage:GetChildren() do

        -- paintType collisions.
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name, thisPowerup.Name, false)
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name, thisPowerup.Name .. "Part", false)
		physicsService.CollisionGroupSetCollidable(thisPowerup.Name, "Players", false)
		physicsService.CollisionGroupSetCollidable(thisPowerup.Name, "Ghosts", false)

        -- paintTypeGhost collisions.
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", thisPowerup.Name .. "Ghost", false)
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", "Ghosts", false)
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", "Players", false)
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", thisPowerup.Name .. "Part", false)
        physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", "GhostsNoCollide", false)

        -- otherPaintType collisions.
        for _, otherPowerup: Instance in next, thisPowerupStorage:GetChildren() do
            physicsService.CollisionGroupSetCollidable(thisPowerup.Name, otherPowerup.Name, false)
            physicsService.CollisionGroupSetCollidable(thisPowerup.Name .. "Ghost", otherPowerup.Name .. "Ghost", false)
        end
    end

    -- This is the actual functionality behind the paint powerup.
    if thisPowerupStorage:FindFirstChild("AccessableParts") then
        for _, accessablePart: Instance in next, thisPowerupStorage.AccessableParts:GetChildren() do
            physicsService.SetCollectionsCollisionGroup(
                {accessablePart},
                accessablePart.Name .. "Part"
            )
        end
    end

    -- This will be called when the powerup is removed from a character.
    -- The main powerup system handles all of this.
    collectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character: Model)

        local player: Player? = players:GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end
		if not character.Humanoid:FindFirstChild("HumanoidDescription") then return end

        -- We have to do a special exception for Ghost powerup.
        -- If they have the ghost powerup after the paint powerup is finished we just set it back to the paint collision.
        if powerupsManager.GetPowerupInformation(player, "Ghost") then
            physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Ghosts")
        else
            physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Players")
        end

        -- We use their HumanoidDescription to reapply their normal look.
        character.Humanoid:ApplyDescription(character.Humanoid.HumanoidDescription)
    end)
end

-- Applies the powerup, this is where we put any effects into play.
function ThisPowerupManager.Apply(player: Player, thisPowerup: Instance)

    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We have to do a special exception for Ghost powerup.
    -- If they have the ghost powerup after the paint powerup is finished we just set it back to the paint collision.
    if powerupsManager.GetPowerupInformation(player, "Ghost") then
        physicsService.SetCollectionsCollisionGroup(
            player.Character:GetChildren(),
            thisPowerup.Name .. "Ghost"
        )
    else
        physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), thisPowerup.Name)
    end

    -- We want to color them the same as the paint.
	for _, basePart: Instance in next, player.Character:GetChildren() do
		if basePart:IsA("BasePart") then
			basePart.Color = thisPowerup:GetAttribute("Color") or sharedConstants.MECHANICS.PAINT_POWERUP_DEFAULT_COLOR
		end
	end
end

return ThisPowerupManager
