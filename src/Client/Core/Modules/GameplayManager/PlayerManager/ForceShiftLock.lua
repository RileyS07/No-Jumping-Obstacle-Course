-- Variables
local forceShiftLockManager = {}
forceShiftLockManager.Interface = {}
forceShiftLockManager.IsShiftLockActive = true

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local cameraEssentialsLibrary = require(coreModule.GetObject("Libraries.CameraEssentials"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function forceShiftLockManager.Initialize()
    forceShiftLockManager.Interface.Button = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Shiftlock")
    forceShiftLockManager.Interface.Icon = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("ShiftlockIcon")

    -- The actual shift lock logic.
    game:GetService("RunService"):BindToRenderStep("MobileShiftlock", Enum.RenderPriority.Camera.Value + 1, function()
        if not cameraEssentialsLibrary.IsCurrentCameraReadyForManipulation()  then return end
        if not utilitiesLibrary.IsPlayerValid() then game:GetService("RunService"):UnbindFromRenderStep("MobileShiftlock") end

        -- Reset the values.
        if not forceShiftLockManager.IsShiftLockActive or userInterfaceManager.GetPriorityInterface() or next(userInterfaceManager.ActiveContainers) then 
            game:GetService("UserInputService").MouseIconEnabled = true

            if utilitiesLibrary.IsPlayerAlive() and clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.LocalTransparencyModifier >= 0.8 then
                UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative
                game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
            elseif game:GetService("UserInputService").MouseBehavior ~= Enum.MouseBehavior.Default then
                UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative
                game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
            end

            return
        end

        UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.CameraRelative
        game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
        game:GetService("UserInputService").MouseIconEnabled = false
    end)

    -- Toggle it on and off.
    game:GetService("UserInputService").InputBegan:Connect(function(inputObject, gameProcessedEvent)
        if gameProcessedEvent then return end
        if inputObject.KeyCode ~= Enum.KeyCode.LeftShift and inputObject.KeyCode ~= Enum.KeyCode.RightShift and inputObject.KeyCode ~= Enum.KeyCode.ButtonR2 then return end

        forceShiftLockManager.UpdateShiftLockActive(not forceShiftLockManager.GetShiftLockActive())
        forceShiftLockManager.UpdateShiftLockInterface()
    end)

    forceShiftLockManager.Interface.Button.Activated:Connect(function()
        forceShiftLockManager.UpdateShiftLockActive(not forceShiftLockManager.GetShiftLockActive()) 
        forceShiftLockManager.UpdateShiftLockInterface()
    end)

    game:GetService("UserInputService").LastInputTypeChanged:Connect(function()
        forceShiftLockManager.UpdateShiftLockInterface()
    end)

    -- Setup.
    forceShiftLockManager.UpdateShiftLockInterface()
end


-- Methods
function forceShiftLockManager.GetShiftLockActive()
    return forceShiftLockManager.IsShiftLockActive
end


function forceShiftLockManager.UpdateShiftLockActive(newValue)
    forceShiftLockManager.IsShiftLockActive = newValue
end


function forceShiftLockManager.UpdateShiftLockInterface()
    forceShiftLockManager.Interface.Icon.Visible = forceShiftLockManager.GetShiftLockActive()
    forceShiftLockManager.Interface.Button.Image =
        forceShiftLockManager.GetShiftLockActive()
        and "rbxasset://textures/ui/mouseLock_on@2x.png" 
        or "rbxasset://textures/ui/mouseLock_off@2x.png"
end


--
return forceShiftLockManager