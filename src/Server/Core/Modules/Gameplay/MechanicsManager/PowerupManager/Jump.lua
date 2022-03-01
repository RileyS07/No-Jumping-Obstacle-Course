-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

-- Initialize
function specificPowerupManager.Initialize()
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        player.Character.Humanoid.JumpHeight = 0
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not playerUtilities.IsPlayerAlive(player) then return end

    player.Character.Humanoid.JumpHeight = powerupPlatform:GetAttribute("JumpHeight") or script:GetAttribute("DefaultJumpHeight") or 7.5
end


--
return specificPowerupManager