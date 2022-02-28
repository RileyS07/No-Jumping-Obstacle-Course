-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupsManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))

-- Initialize
function specificPowerupManager.Initialize()
    collisionsLibrary.CollisionGroupSetCollidable("Ghosts", "Players", false)
	collisionsLibrary.CollisionGroupSetCollidable("Ghosts", "GhostsNoCollide", false)

    -- This is the actual functionality behind the ghost powerup.
    if workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:FindFirstChild("AccessableParts") then
        collisionsLibrary.SetDescendantsCollisionGroup(workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name].AccessableParts, "GhostsNoCollide")
    end
    
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
        
        -- We have to do a special exception for Paint powerup.
        if powerupsManager.GetPowerupInformation(player, "Paint") then
            collisionsLibrary.SetDescendantsCollisionGroup(player.Character, powerupsManager.GetPowerupInformation(player, "Paint").PlatformName)
        else
            collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Players")
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
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    -- We have to do a special exception for Paint powerup.
    if powerupsManager.GetPowerupInformation(player, "Paint") then
        collisionsLibrary.SetDescendantsCollisionGroup(player.Character, powerupsManager.GetPowerupInformation(player, "Paint").PlatformName.."Ghost")
    else
        collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Ghosts")
    end

    for _, basePart in next, player.Character:GetDescendants() do
		if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
			basePart.Transparency = 0.5
		end
	end
end


--
return specificPowerupManager