-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.CommonRaycastParameters = nil
gameplayMechanicManager.PlatformsBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local mechanicsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ManualSwitchPlatforms")
    gameplayMechanicManager.CommonRaycastParameters = RaycastParams.new()
	gameplayMechanicManager.CommonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
	gameplayMechanicManager.CommonRaycastParameters.FilterDescendantsInstances = gameplayMechanicManager.MechanicContainer:GetDescendants()

    -- Setting up the platform to be functional.
    playerMouseLibrary.SetInputListener({Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX}, Enum.UserInputState.Begin):Connect(function()
        local raycastResult = playerMouseLibrary.Raycast(gameplayMechanicManager.CommonRaycastParameters)

        -- Guard clauses.
        if not raycastResult then return end
        if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
        if gameplayMechanicManager.IsPlatformBeingSimulated(raycastResult.Instance) then return end
        if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(raycastResult.Position) > (raycastResult.Instance:GetAttribute("MaxDistance") or script:GetAttribute("DefaultMaxDistance") or 50) then return end

        gameplayMechanicManager.SimulatePlatform(raycastResult.Instance)
    end)

    -- Better mobile support.
    gameplayMechanicManager.SetupKeybindFunctionality()
end


-- Methods
function gameplayMechanicManager.SimulatePlatform(platformObject)
    if typeof(platformObject) ~= "Instance" or not platformObject:IsA("BasePart") then return end
    if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
    if gameplayMechanicManager.IsPlatformBeingSimulated(platformObject) then return end
    if clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(platformObject.Position) > (platformObject:GetAttribute("MaxDistance") or script:GetAttribute("DefaultMaxDistance") or 50) then return end


    -- The magic function where the transformation happens.
    gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, true)

    clientAnimationsLibrary.PlayAnimation("SwitchTransformation", platformObject)
    soundEffectsManager.PlaySoundEffect("SwitchClicked", {Parent = platformObject})
    task.wait(platformObject:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 10)
    clientAnimationsLibrary.PlayAnimation("SwitchTransformation", platformObject)

    gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, nil)
end


function gameplayMechanicManager.IsPlatformBeingSimulated(platformObject)
	if not platformObject then return end
	return gameplayMechanicManager.PlatformsBeingSimulated[platformObject]
end


function gameplayMechanicManager.UpdatePlatformBeingSimulated(platformObject, newValue)
	if not platformObject then return end
	gameplayMechanicManager.PlatformsBeingSimulated[platformObject] = newValue
end


-- Private Methods
function gameplayMechanicManager.SetupKeybindFunctionality()
    local keybindActionName = "ManualSwitchPlatforms"
    --local keybindButtonTitle = script:GetAttribute("KeybindButtonTitle") or "Switch"
    local keybindButtonDescription = script:GetAttribute("KeybindButtonDescription") or "Switch Description."
    local keybindButtonImageContent = script:GetAttribute("KeybindButtonImageContent") or "rbxassetid://6704235678"

    -- We need to setup ContentActionService so we can better support mobile devices.
    local function keybindActionFunction(_, userInputState)
        if userInputState ~= Enum.UserInputState.Begin then return end

        for _, platformObject in next, gameplayMechanicManager.MechanicContainer:GetDescendants() do
            gameplayMechanicManager.SimulatePlatform(platformObject)
        end
    end

    -- The functionality will only be avaliable if the player is within x studs of the platform.
    coroutine.wrap(function()
        while true do
            if not utilitiesLibrary.IsPlayerValid() then return end

            if utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) and not userInterfaceManager.GetPriorityInterface() then
                local isPlayerNearAnySwitchPlatforms = false

                for _, platformObject in next, gameplayMechanicManager.MechanicContainer:GetDescendants() do
                    if platformObject:IsA("BasePart") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(platformObject.Position) <= (script:GetAttribute("DefaultMaxDistance") or 50) then
                        isPlayerNearAnySwitchPlatforms = true
                        break
                    end
                end

                -- Now that we have the results let's bind/unbind.
                if isPlayerNearAnySwitchPlatforms then
                    game:GetService("ContextActionService"):BindAction(keybindActionName, keybindActionFunction, true, Enum.KeyCode.Q)
                    game:GetService("ContextActionService"):SetDescription(keybindActionName, keybindButtonDescription)
                    game:GetService("ContextActionService"):SetImage(keybindActionName, keybindButtonImageContent)
                else
                    game:GetService("ContextActionService"):UnbindAction(keybindActionName)
                end
            else
                game:GetService("ContextActionService"):UnbindAction(keybindActionName)
            end

            task.wait(0.5)
        end
    end)()
end


--
return gameplayMechanicManager