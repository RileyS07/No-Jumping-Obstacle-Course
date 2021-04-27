-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))

-- Initialize
function specificPowerupManager.Initialize()

    -- We need to setup A LOT of collision group stuff here.
    for _, powerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:GetChildren() do
        collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, powerupContainer.Name.."Part", false)
		collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, "Players", false)
		collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, "Ghosts", false)

        -- BluePaint shouldn't collide with RedPaint.
        for _, nestedPowerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:GetChildren() do
            collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, nestedPowerupContainer.Name, false)
        end
    end

    -- This is the actual functionality behind the paint powerup.
    if workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:FindFirstChild("AccessableParts") then
        for _, accessablePart in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name].AccessableParts:GetChildren() do
            collisionsLibrary.SetPartCollisionGroup(accessablePart, accessablePart.Name.."Part")
        end
    end
    
    coreModule.Services.CollectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = coreModule.Services.Players:GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if not character.Humanoid:FindFirstChild("HumanoidDescription") then return end
		
		collisionsLibrary.SetDescendantsCollisionGroup(character, "Players")
        character.Humanoid:ApplyDescription(character.Humanoid.HumanoidDescription)
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    collisionsLibrary.SetDescendantsCollisionGroup(player.Character, powerupPlatform.Name)
	for _, basePart in next, player.Character:GetChildren() do
		if basePart:IsA("BasePart") then
			basePart.Color = powerupPlatform:GetAttribute("Color") or Color3.new()
		end
	end
end


--
return specificPowerupManager