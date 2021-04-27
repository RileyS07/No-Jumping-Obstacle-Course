-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificPowerupManager.Initialize()
    coreModule.Services.CollectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = coreModule.Services.Players:GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end

        player.Character.Humanoid.JumpHeight = 0
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    
    player.Character.Humanoid.JumpHeight = powerupPlatform:GetAttribute("JumpHeight") or script:GetAttribute("DefaultJumpHeight") or 7.5
end


--
return specificPowerupManager