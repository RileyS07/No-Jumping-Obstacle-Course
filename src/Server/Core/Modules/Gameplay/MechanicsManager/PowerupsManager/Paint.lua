-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local powerupsManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.PowerupsManager"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))

-- Initialize
function specificPowerupManager.Initialize()

    -- We need to setup A LOT of collision group stuff here.
    for _, powerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:GetChildren() do
        collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, powerupContainer.Name.."Part", false)
		collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, "Players", false)
		collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, "Ghosts", false)

        collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name.."Ghost", "Ghosts", false)
        collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name.."Ghost", "Players", false)
        collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name.."Ghost", powerupContainer.Name.."Part", false)

        -- BluePaint shouldn't collide with RedPaint.
        for _, nestedPowerupContainer in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:GetChildren() do
            collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name, nestedPowerupContainer.Name, false)
            collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name.."Ghost", nestedPowerupContainer.Name.."Ghost", false)
            collisionsLibrary.CollisionGroupSetCollidable(powerupContainer.Name.."Ghost", "GhostsNoCollide", false)
        end
    end

    -- This is the actual functionality behind the paint powerup.
    if workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name]:FindFirstChild("AccessableParts") then
        for _, accessablePart in next, workspace.Map.Gameplay.PlatformerMechanics.Powerups[script.Name].AccessableParts:GetChildren() do
            collisionsLibrary.SetPartCollisionGroup(accessablePart, accessablePart.Name.."Part")
        end
    end
    
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
		if not character.Humanoid:FindFirstChild("HumanoidDescription") then return end
		
        -- We have to do a special exception for Ghost powerup.
        if powerupsManager.GetPowerupInformation(player, "Ghost") then
            collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Ghosts")
        else
            collisionsLibrary.SetDescendantsCollisionGroup(player.Character, "Players")
        end

        character.Humanoid:ApplyDescription(character.Humanoid.HumanoidDescription)
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    -- We have to do a special exception for Ghost powerup.
    if powerupsManager.GetPowerupInformation(player, "Ghost") then
        collisionsLibrary.SetDescendantsCollisionGroup(player.Character, powerupPlatform.Name.."Ghost")
    else
        collisionsLibrary.SetDescendantsCollisionGroup(player.Character, powerupPlatform.Name)
    end

	for _, basePart in next, player.Character:GetChildren() do
		if basePart:IsA("BasePart") then
			basePart.Color = powerupPlatform:GetAttribute("Color") or Color3.new()
		end
	end
end


--
return specificPowerupManager