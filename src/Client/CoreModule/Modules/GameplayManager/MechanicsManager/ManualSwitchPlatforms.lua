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
        if gameplayMechanicManager.SwitchesBeingSimulated[raycastResult.Instance] then return end

        gameplayMechanicManager.SimulateSwitchActivation(raycastResult.Instance)
    end)
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
    if gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform] then return end
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform] = true

    -- The magic function where the transformation happens.
    local function transformSwitchPlatform()
        switchPlatform.CanCollide = not switchPlatform.CanCollide
        switchPlatform.Transparency = switchPlatform.CanCollide and (switchPlatform:GetAttribute("VisibleTransparency") or script:GetAttribute("DefaultVisibleTransparency") or 0) or (switchPlatform:GetAttribute("InvisibleTransparency") or script:GetAttribute("DefaultInvisibleTransparency") or 0.5)
    end

    transformSwitchPlatform()
    wait(switchPlatform:GetAttribute("Duration") or script:GetAttribute("DefaultDuration") or 10)
	transformSwitchPlatform()
    gameplayMechanicManager.SwitchesBeingSimulated[switchPlatform] = nil
end


--
return gameplayMechanicManager