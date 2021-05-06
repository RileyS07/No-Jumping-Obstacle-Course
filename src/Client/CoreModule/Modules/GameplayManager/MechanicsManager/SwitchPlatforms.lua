-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.CommonRaycastParameters = nil
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("SwitchPlatforms")
    gameplayMechanicManager.CommonRaycastParameters = RaycastParams.new()
	gameplayMechanicManager.CommonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
	gameplayMechanicManager.CommonRaycastParameters.FilterDescendantsInstances = gameplayMechanicManager.MechanicContainer:GetDescendants()
    
    -- Setting up the platform to be functional.
    playerMouseLibrary.SetInputListener({Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX}, Enum.UserInputState.Begin):Connect(function()
        local raycastResult = playerMouseLibrary.Raycast(gameplayMechanicManager.CommonRaycastParameters)
              
        -- Guard clauses.
        if not raycastResult then return end
        if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
        if gameplayMechanicManager.IsPlatformBeingSimulated(raycastResult.Instance.Parent.Parent) then return end
        if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(raycastResult.Position) > (raycastResult.Instance:GetAttribute("MaxDistance") or script:GetAttribute("DefaultMaxDistance") or 50) then return end

        gameplayMechanicManager.SimulatePlatform(raycastResult.Instance.Parent.Parent, raycastResult.Instance)
    end)
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformContainer, platformObject)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("BasePart") then return end
    if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
    if gameplayMechanicManager.IsPlatformBeingSimulated(platformContainer) then return end
    if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(platformObject.Position) > (platformObject:GetAttribute("MaxDistance") or script:GetAttribute("DefaultMaxDistance") or 50) then return end

    gameplayMechanicManager.UpdatePlatformBeingSimulated(platformContainer, true)

    -- The magic function where the transformation happens.
    gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, true)

    for _, nestedPlatformObject in next, platformContainer:GetDescendants() do
        if nestedPlatformObject:IsA("BasePart") and nestedPlatformObject.CanCollide ~= (nestedPlatformObject.Name == platformObject.Name) then
            clientAnimationsLibrary.PlayAnimation("SwitchTransformation", nestedPlatformObject)
            soundEffectsManager.PlaySoundEffect("SwitchClicked", {Parent = nestedPlatformObject})
        end
    end
   
    gameplayMechanicManager.UpdatePlatformBeingSimulated(platformContainer, nil)
end


function gameplayMechanicManager.IsPlatformBeingSimulated(platformObject)
	if not platformObject then return end
	return gameplayMechanicManager.PlatformsBeingSimulated[platformObject]
end


function gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, newValue)
	if not platformObject then return end
	gameplayMechanicManager.PlatformsBeingSimulated[platformObject] = newValue
end


--
return gameplayMechanicManager