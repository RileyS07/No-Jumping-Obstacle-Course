-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

-- Initialize
function specificPowerupManager.Initialize()
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end
        if not character:FindFirstChildOfClass("ForceField") then return end

        character:FindFirstChildOfClass("ForceField"):Destroy()
    end)
end


-- Apply
function specificPowerupManager.Apply(player)
    if not playerUtilities.IsPlayerAlive(player) then return end
    if player.Character:FindFirstChild("ForceField") then return end

    Instance.new("ForceField").Parent = player.Character
end


--
return specificPowerupManager