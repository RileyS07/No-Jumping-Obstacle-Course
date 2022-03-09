local players: Players = game:GetService("Players")
local runService: RunService = game:GetService("RunService")
local userInputService: UserInputService = game:GetService("UserInputService")
local userGameSettings: UserGameSettings = UserSettings():GetService("UserGameSettings")

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local cameraUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.CameraUtilities"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local mainInterface: GuiBase2d = players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MainInterface")--userInterfaceManager.GetInterface("MainInterface")
local shiftlockButton: GuiButton = mainInterface:WaitForChild("ShiftlockButton")
local shiftlockCenterIcon: GuiObject = mainInterface:WaitForChild("ShiftlockCenterIcon")
local controllerSupportContainer: GuiObject = shiftlockButton:WaitForChild("ControllerSupportContainer")

local thisPlayer: Player = players.LocalPlayer

local ForcedShiftlockManager = {}
ForcedShiftlockManager.IsShiftlockActive = true
ForcedShiftlockManager._IsThereAnActiveInterface = false

-- Initialize
function ForcedShiftlockManager.Initialize()

    -- Since this overrides the default camera logic we need to bind it to render stepped.
    runService:BindToRenderStep(
        "MobileShiftlock",
        Enum.RenderPriority.Camera.Value + 1,
        ForcedShiftlockManager._Update
    )

    -- This is how they activate it. Turning it on and off.
    -- We want to update it at the start as well as whenever the input is changed.
    -- We do this so if they have a controller active we can show the controller hint.
    ForcedShiftlockManager._SetupActivationMethods()
    ForcedShiftlockManager._UpdateInterface()

    userInputService.LastInputTypeChanged:Connect(ForcedShiftlockManager._UpdateInterface)

    -- Listens for if there is an active interface.
    userInterfaceManager.ActiveInterfaceUpdated:Connect(function(interface: GuiBase2d)
        ForcedShiftlockManager._IsThereAnActiveInterface = interface ~= nil
    end)
end

-- Returns whether or not the shiftlock is currently active.
function ForcedShiftlockManager.GetIsShiftlockActive() : boolean
    return ForcedShiftlockManager.IsShiftlockActive
end

-- Sets and updates the shiftlock to reflect this value.
function ForcedShiftlockManager.SetIsShiftlockActive(isActive: boolean)
    ForcedShiftlockManager.IsShiftlockActive = isActive
    ForcedShiftlockManager._UpdateInterface()
end

-- Sets up the different types of activation for the shiftlock.
function ForcedShiftlockManager._SetupActivationMethods()

    -- For keyboards and controllers.
    userInputService.InputBegan:Connect(function(inputObject: InputObject, gameProcessedEvent: boolean)

        -- We need to make sure they weren't talking and that it's valid.
        if gameProcessedEvent then return end
        if not table.find(ForcedShiftlockManager._GetActivationKeyCodes(), inputObject.KeyCode) then return end

        -- We can update it.
        ForcedShiftlockManager.SetIsShiftlockActive(
            not ForcedShiftlockManager.GetIsShiftlockActive()
        )
    end)

    -- For anything that can click.
    shiftlockButton.Activated:Connect(function()
        ForcedShiftlockManager.SetIsShiftlockActive(
            not ForcedShiftlockManager.GetIsShiftlockActive()
        )
    end)
end

-- Returns the activation keycodes.
function ForcedShiftlockManager._GetActivationKeyCodes() : {Enum.KeyCode}
    return {
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.RightShift,
        sharedConstants.GENERAL.FORCED_SHIFTLOCK_CONTROLLER_KEYCODE
    }
end

-- Manages all of the shiftlock related updates.
function ForcedShiftlockManager._Update()

    -- If we can't manipulate their camera then there is no point.
    if not cameraUtilities.IsCurrentCameraManipulatable() then return end
    if not playerUtilities.IsPlayerValid(thisPlayer) then return end

    -- We have to replicate normal camera-player movement if this is the case.
    if not ForcedShiftlockManager.IsShiftlockActive or ForcedShiftlockManager._IsThereAnActiveInterface then

        userInputService.MouseIconEnabled = true

        -- We assume that they are in first person if the LocalTransparencyModifier is very high.
        -- So if they're in first person we need to change it.
        if playerUtilities.IsPlayerAlive() and thisPlayer.Character.PrimaryPart.LocalTransparencyModifier >= 0.8 then
            userGameSettings.RotationType = Enum.RotationType.CameraRelative
            userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        elseif userInputService.MouseBehavior ~= Enum.MouseBehavior.Default then
            userGameSettings.RotationType = Enum.RotationType.MovementRelative
            userInputService.MouseBehavior = Enum.MouseBehavior.Default
        end

        return
    end

    -- It's not active so we can do our shiftlock.
    userGameSettings.RotationType = Enum.RotationType.CameraRelative
    userInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
    userInputService.MouseIconEnabled = false
end

-- Updates the interface components of the shiftlock.
function ForcedShiftlockManager._UpdateInterface()
    shiftlockCenterIcon.Visible = ForcedShiftlockManager.GetIsShiftlockActive()

    -- For controller support.
    controllerSupportContainer.Visible = userInputService:GetLastInputType() == Enum.UserInputType.Gamepad1
    controllerSupportContainer:WaitForChild("KeyCode").Text = string.gsub(
        sharedConstants.INTERFACE.FORCED_SHIFTLOCK_CONTROLLER_KEYCODE.Name,
        "Button",
        ""
    )

    -- Straight from roblox assets.
    shiftlockButton.Image =
        ForcedShiftlockManager.GetIsShiftlockActive()
        and "rbxasset://textures/ui/mouseLock_on@2x.png"
        or "rbxasset://textures/ui/mouseLock_off@2x.png"
end

return ForcedShiftlockManager
