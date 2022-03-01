-- Variables
local specificPowerupManager = {}
specificPowerupManager.Remotes = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

-- Initialize
function specificPowerupManager.Initialize()
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end

        specificPowerupManager.Remotes.RadarStatusUpdated:FireClient(player)
    end)

    specificPowerupManager.Remotes.RadarStatusUpdated = coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RadarStatusUpdated")
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not playerUtilities.IsPlayerAlive(player) then return end
    if not powerupPlatform:FindFirstChild("AccessableParts") then return end

    specificPowerupManager.Remotes.RadarStatusUpdated:FireClient(player, powerupPlatform.AccessableParts:GetChildren())
end


--
return specificPowerupManager