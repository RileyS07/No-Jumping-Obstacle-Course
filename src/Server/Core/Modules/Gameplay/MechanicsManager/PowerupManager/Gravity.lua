-- Variables
local specificPowerupManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local instanceUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.InstanceUtilities"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

-- Initialize
function specificPowerupManager.Initialize()
    game:GetService("CollectionService"):GetInstanceRemovedSignal(script.Name):Connect(function(character)
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
		if not playerUtilities.IsPlayerAlive(player) then return end
        if not character.PrimaryPart:FindFirstChildOfClass("BodyForce") then return end

        character.PrimaryPart:FindFirstChildOfClass("BodyForce"):Destroy()
    end)
end


-- Apply
function specificPowerupManager.Apply(player, powerupPlatform)
    if not playerUtilities.IsPlayerAlive(player) then return end

    local bodyForceObject = player.Character.PrimaryPart:FindFirstChildOfClass("BodyForce") or instanceUtilities.Create("BodyForce", {Parent = player.Character.PrimaryPart})
    bodyForceObject.Force = Vector3.new(
        0,
        -- CharacterMass*Gravity*GravityMultiplier; We do 1 - Force so you can do 1.5 thinking 1.5 times gravity and not really treat it was gravity + 1.5x gravity.
        specificPowerupManager.GetCharacterMass(player.Character)*workspace.Gravity*((powerupPlatform:GetAttribute("Force") or script:GetAttribute("DefaultForce")) - 1),
        0
    )
end


-- Methods
function specificPowerupManager.GetCharacterMass(character)
    if typeof(character) ~= "Instance" or not character:IsA("Model") then return end

    -- We add up all of the individual masses of the limbs.
    local totalCharacterMass = 0
    for _, basePart in next, character:GetChildren() do
        if basePart:IsA("BasePart") then
            totalCharacterMass += basePart:GetMass()
        end
    end

    return totalCharacterMass
end

--
return specificPowerupManager