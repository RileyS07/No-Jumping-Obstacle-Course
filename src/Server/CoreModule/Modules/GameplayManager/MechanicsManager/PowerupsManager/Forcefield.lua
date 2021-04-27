-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function specificPowerupManager.Initialize()
    coreModule.Services.CollectionService:GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = coreModule.Services.Players:GetPlayerFromCharacter(character)
		if not utilitiesLibrary.IsPlayerAlive(player) then return end
        if not character:FindFirstChildOfClass("ForceField") then return end

        character:FindFirstChildOfClass("ForceField"):Destroy()
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not utilitiesLibrary.IsPlayerAlive(player) then return end
    if player.Character:FindFirstChild("ForceField") then return end

    Instance.new("ForceField").Parent = player.Character
end


--
return specificPowerupManager