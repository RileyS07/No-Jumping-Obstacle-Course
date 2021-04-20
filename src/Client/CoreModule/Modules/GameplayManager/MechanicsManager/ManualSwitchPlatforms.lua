-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.CommonRaycastParameters = nil
gameplayMechanicManager.SwitchesBeingSimulated = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local playerMouseLibrary = require(coreModule.GetObject("Libraries.UserInput.Mouse"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ManualSwitchPlatforms")
    gameplayMechanicManager.CommonRaycastParameters = RaycastParams.new()
	gameplayMechanicManager.CommonRaycastParameters.FilterType = Enum.RaycastFilterType.Whitelist
	gameplayMechanicManager.CommonRaycastParameters.FilterDescendantsInstances = gameplayMechanicManager.MechanicContainer:GetDescendants()
    
    -- Setting up the ManualSwitchPlatforms to be functional.
    playerMouseLibrary.SetInputListener({Enum.UserInputType.Touch, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonX}, Enum.UserInputState.Begin):Connect(function()
        local raycastResult = playerMouseLibrary.Raycast(gameplayMechanicManager.CommonRaycastParameters)
        
        --[[
            These guard clauses check the following:
            1) Check if the rasycastResult is valid.
            2) Check if the player is alive.
            3) If MaxDistance exists we check to see if the distance is within the acceptable threshold.
            4) Check if the switch is already being simulated.
        ]]         
        
        if not raycastResult then return end
        if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
        if raycastResult.Instance:GetAttribute("MaxDistance") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(raycastResult.Position) > raycastResult.Instance:GetAttribute("MaxDistance") then return end
        if gameplayMechanicManager.IsSwitchBeingSimulated(raycastResult.Instance) then return end

        gameplayMechanicManager.SimulateSwitchActivation(raycastResult.Instance)
    end)

    -- Keybinds setup for the ManualSwitchPlatforms.
    local keybindActionName = "ManualSwitchPlatforms"
    local keybindButtonTitle = script:GetAttribute("KeybindButtonTitle") or "Switch"
    local keybindButtonDescription = script:GetAttribute("KeybindButtonDescription") or "Switch Description."
    local keybindButtonImageContent = script:GetAttribute("KeybindButtonImageContent") or "rbxassetid://6704235678"

    local function keybindActionFunction(_, userInputState, inputObject)
        if userInputState ~= Enum.UserInputState.Begin then return end
        
        for _, switchPlatform in next, gameplayMechanicManager.MechanicContainer:GetDescendants() do
            gameplayMechanicManager.SimulateSwitchActivation(switchPlatform)
        end
    end

    -- The functionality will only be avaliable if the player is within x studs of the platform.
    coroutine.wrap(function()
        while true do
            if utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then
                local isPlayerNearAnySwitchPlatforms = false

                for _, switchPlatform in next, gameplayMechanicManager.MechanicContainer:GetDescendants() do
                    if switchPlatform:IsA("BasePart") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(switchPlatform.Position) <= (script:GetAttribute("MaxBindDistance") or 30) then
                        isPlayerNearAnySwitchPlatforms = true
                    end
                end

                -- Now that we have the results let's bind/unbind.
                if isPlayerNearAnySwitchPlatforms then
                    coreModule.Services.ContextActionService:BindAction(keybindActionName, keybindActionFunction, true, Enum.KeyCode.E)
                    coreModule.Services.ContextActionService:SetDescription(keybindActionName, keybindButtonDescription)
                    coreModule.Services.ContextActionService:SetImage(keybindActionName, keybindButtonImageContent)
                else  
                    coreModule.Services.ContextActionService:UnbindAction(keybindActionName)
                end
            end


            wait(0.5)
        end
    end)()
end


-- Methods
function gameplayMechanicManager.SimulateSwitchActivation(switchPlatform)

    --[[
        These guard clauses check the following:
        1) Check if the switchPlatform is in a format we can work with.
        2) Check if the player is alive.
        3) If MaxDistance exists we check to see if the distance is within the acceptable threshold.
        4) Check if the switch is already being simulated.
    ]] 

    if not switchPlatform or typeof(switchPlatform) ~= "Instance" or not switchPlatform:IsA("BasePart") then return end
    if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
    if switchPlatform:GetAttribute("MaxDistance") and clientEssentialsLibrary.GetPlayer():DistanceFromCharacter(switchPlatform.Position) > switchPlatform:GetAttribute("MaxDistance") then return end
    if gameplayMechanicManager.IsSwitchBeingSimulated(switchPlatform) then return end
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform] = true

    -- The magic function where the transformation happens.
    local function transformSwitchPlatform()
        switchPlatform.CanCollide = not switchPlatform.CanCollide
        switchPlatform.Transparency = switchPlatform.CanCollide and (switchPlatform:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) or (switchPlatform:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
        mechanicsManager.PlayAppearanceChangedEffect(switchPlatform)
    end
    
    transformSwitchPlatform()
    wait(switchPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 10)
	transformSwitchPlatform()
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform] = nil
end


function gameplayMechanicManager.IsSwitchBeingSimulated(switchPlatform)
    return gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform]
end


--
return gameplayMechanicManager