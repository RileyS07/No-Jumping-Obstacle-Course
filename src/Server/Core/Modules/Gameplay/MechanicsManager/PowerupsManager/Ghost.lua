-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupsManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))

-- Initialize
function specificPowerupManager.Initialize()
    physicsService.CollisionGroupSetCollidable("Ghosts", "Players", false)
    physicsService.CollisionGroupSetCollidable("Ghosts", "GhostsNoCollide", false)

    -- This is the actual functionality behind the ghost powerup.
    if workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:FindFirstChild("AccessableParts") then
        physicsService.SetCollectionsCollisionGroup(workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name].AccessableParts:GetChildren(), "GhostsNoCollide")
    end

    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        -- We have to do a special exception for Paint powerup.
        if powerupsManager.GetPowerupInformation(player, "Paint") then
            physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), powerupsManager.GetPowerupInformation(player, "Paint").PlatformName)
        else
            physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Players")
        end

		for _, basePart in next, character:GetDescendants() do
			if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
				basePart.Transparency = 0
			end
		end
    end)
end


-- Apply
function specificPowerupManager.Apply(player)
    if not playerUtilities.IsPlayerAlive(player) then return end

    -- We have to do a special exception for Paint powerup.
    if powerupsManager.GetPowerupInformation(player, "Paint") then
        physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), powerupsManager.GetPowerupInformation(player, "Paint").PlatformName.."Ghost")
    else
        physicsService.SetCollectionsCollisionGroup(player.Character:GetChildren(), "Ghosts")
    end

    for _, basePart in next, player.Character:GetDescendants() do
		if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
			basePart.Transparency = 0.5
		end
	end
end


--
return specificPowerupManager