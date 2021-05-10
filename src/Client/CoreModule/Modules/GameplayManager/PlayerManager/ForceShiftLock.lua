-- Variables
local forceShiftLockManager = {}
forceShiftLockManager.Interface = {}
forceShiftLockManager.IsShiftLockActive = true

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local cameraEssentialsLibrary = require(coreModule.GetObject("Libraries.CameraEssentials"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function forceShiftLockManager.Initialize()
    forceShiftLockManager.Interface.Button = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Shiftlock")

    -- The actual shift lock logic.
    coreModule.Services.RunService:BindToRenderStep("MobileShiftlock", Enum.RenderPriority.Camera.Value + 1, function()
        if not cameraEssentialsLibrary.IsCurrentCameraReadyForManipulation()  then return end
        if not utilitiesLibrary.IsPlayerValid() then coreModule.Services.RunService:UnbindFromRenderStep("MobileShiftlock") end

        -- Reset the values.
        if not forceShiftLockManager.IsShiftLockActive or userInterfaceManager.GetPriorityInterface() or next(userInterfaceManager.ActiveContainers) then 
            coreModule.Services.UserInputService.MouseIconEnabled = true

            if utilitiesLibrary.IsPlayerAlive() and clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.LocalTransparencyModifier >= 0.8 then
                UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative
                coreModule.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
            elseif coreModule.Services.UserInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
                UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative
                coreModule.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            end

            return 
        end

        UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative
        coreModule.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        coreModule.Services.UserInputService.MouseIconEnabled = false
    end)

    -- Toggle it on and off.
    coreModule.Services.UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObject.KeyCode ~= Enum.KeyCode.LeftShift and inputObject.KeyCode ~= Enum.KeyCode.ButtonR2 then return end

        forceShiftLockManager.UpdateShiftLockActive(not forceShiftLockManager.GetShiftLockActive())
        clientAnimationsLibrary.PlayAnimation("UpdateShiftLockIcon", forceShiftLockManager.Interface.Button, forceShiftLockManager.GetShiftLockActive())
    end)

    forceShiftLockManager.Interface.Button.Activated:Connect(function()
        forceShiftLockManager.UpdateShiftLockActive(not forceShiftLockManager.GetShiftLockActive()) 
        clientAnimationsLibrary.PlayAnimation("UpdateShiftLockIcon", forceShiftLockManager.Interface.Button, forceShiftLockManager.GetShiftLockActive())
    end)

    coreModule.Services.UserInputService.LastInputTypeChanged:Connect(function()
        clientAnimationsLibrary.PlayAnimation("UpdateShiftLockIcon", forceShiftLockManager.Interface.Button, forceShiftLockManager.GetShiftLockActive())
    end)

    -- Setup.
    clientAnimationsLibrary.PlayAnimation("UpdateShiftLockIcon", forceShiftLockManager.Interface.Button, forceShiftLockManager.GetShiftLockActive())
end


-- Methods
function forceShiftLockManager.GetShiftLockActive()
    return forceShiftLockManager.IsShiftLockActive
end


function forceShiftLockManager.UpdateShiftLockActive(newValue)
    forceShiftLockManager.IsShiftLockActive = newValue
end


--
return forceShiftLockManager