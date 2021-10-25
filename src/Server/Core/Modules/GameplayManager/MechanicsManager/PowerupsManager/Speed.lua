-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificPowerupManager.Initialize()
    coreModule.Services.CollectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = coreModule.Services.Players:GetPlayerFromCharacter(character)
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