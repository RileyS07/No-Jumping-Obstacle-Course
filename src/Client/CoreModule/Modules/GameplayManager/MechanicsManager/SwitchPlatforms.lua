-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.CommonRaycastParameters = nil
gameplayMechanicManager.SwitchesBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("SwitchPlatforms")
    gameplayMechanicManager.CommonRaycastParameters = RaycastParams.new()
	gameplayMechanicManager.CommonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
	gameplayMechanicManager.CommonRaycastParameters.FilterDescendantsInstances = gameplayMechanicManager.MechanicContainer:GetDescendants()
    
    -- Setting up the SwitchPlatforms to be functional.
    playerMouseLibrary.SetInputListener({Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX}, Enum.UserInputState.Begin):Connect(function()
        local raycastResult = playerMouseLibrary.Raycast(gameplayMechanicManager.CommonRaycastParameters)
        
        --[[
            These guard clauses check the following:
            1) Check if the rasycastResult is valid.
            2) Check if the player is alive.
            3) If MaxDistance exists we check to see if the distance is within the acceptable threshold.
            4) Check if the switchPlatformContainer is already being simulated.
        ]]         
        
        if not raycastResult then return end
        if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
        if raycastResult.Instance:GetAttribute("MaxDistance") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(raycastResult.Position) > raycastResult.Instance:GetAttribute("MaxDistance") then return end
        if gameplayMechanicManager.IsSwitchBeingSimulated(raycastResult.Instance.Parent.Parent) then return end

        gameplayMechanicManager.SimulateSwitchActivation(raycastResult.Instance.Parent.Parent, raycastResult.Instance)
    end)
end


-- Methods
function gameplayMechanicManager.SimulateSwitchActivation(switchPlatformContainer, specificSwitchPlatform)

    --[[
        These guard clauses check the following:
        1) Check if the switchPlatformContainer is in a format we can work with.
        2) Check if the player is alive.
        3) If MaxDistance exists we check to see if the distance is within the acceptable threshold.
        4) Check if the switchPlatformContainer is already being simulated.
    ]] 

    if not switchPlatformContainer or typeof(switchPlatformContainer) ~= "Instance" then return end
    if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
    if switchPlatformContainer:GetAttribute("MaxDistance") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(specificSwitchPlatform.Position) > switchPlatformContainer:GetAttribute("MaxDistance") then return end
    if gameplayMechanicManager.IsSwitchBeingSimulated(switchPlatformContainer) then return end
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatformContainer] = true

    -- The magic function where the transformation happens.
    local function transformSwitchPlatform()
        for _, switchPlatform in next, switchPlatformContainer:GetDescendants() do
            if switchPlatform:IsA("BasePart") and switchPlatform.CanCollide ~= (switchPlatform.Name == specificSwitchPlatform.Name) then
                switchPlatform.CanCollide = switchPlatform.Name == specificSwitchPlatform.Name
                switchPlatform.Transparency = switchPlatform.CanCollide and (switchPlatform:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) or (switchPlatform:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
           
                local smokeParticleEmitter = coreModule.Shared.GetObject("//Assets.Objects.ParticleEmitters.Smoke"):Clone()
                smokeParticleEmitter.Parent = switchPlatform
        
                smokeParticleEmitter:Emit(script:GetAttribute("SmokeParticleEmittance") or 2)
                coreModule.Services.Debris:AddItem(smokeParticleEmitter, smokeParticleEmitter.Lifetime.Max)
                soundEffectsManager.PlaySoundEffect("Poof", {Parent = switchPlatform})
            end
        end
    end

    transformSwitchPlatform()
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatformContainer] = nil
end


function gameplayMechanicManager.IsSwitchBeingSimulated(switchPlatform)
    return gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform]
end


--
return gameplayMechanicManager