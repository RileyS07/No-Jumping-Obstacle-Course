-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificPowerupManager.Initialize()
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end

        player.Character.Humanoid.WalkSpeed = 16
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    player.Character.Humanoid.WalkSpeed = 16*(powerupPlatform:GetAttribute("Multiplier") or script:GetAttribute("DefaultMultiplier") or 2)
end


--
return specificPowerupManager