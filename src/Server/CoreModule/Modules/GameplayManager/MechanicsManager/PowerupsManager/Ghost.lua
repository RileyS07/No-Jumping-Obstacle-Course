-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))

-- Initialize
function specificPowerupManager.Initialize()
    collisionsLibrary.CollisionGroupSetCollidable("Ghosts", "Players", false)
	collisionsLibrary.CollisionGroupSetCollidable("Ghosts", "GhostsNoCollide", false)

    -- This is the actual functionality behind the ghost powerup.
    if workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:FindFirstChild("AccessableParts") then
        collisionsLibrary.SetDescendantsCollisionGroup(workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name].AccessableParts, "GhostsNoCollide")
    end
    
    coreModule.Services.CollectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = coreModule.Services.Players:GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
        
        collisionsLibrary.SetDescendantsCollisionGroup(character, "Players")
		for _, basePart in next, character:GetDescendants() do
			if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
				basePart.Transparency = 0
			end
		end
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Ghosts")
    for _, basePart in next, player.Character:GetDescendants() do
		if basePart:IsA("BasePart") and basePart.Transparency ~= 1 then
			basePart.Transparency = 0.5
		end
	end
end


--
return specificPowerupManager