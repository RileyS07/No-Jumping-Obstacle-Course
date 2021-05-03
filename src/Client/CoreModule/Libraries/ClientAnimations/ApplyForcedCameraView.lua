-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local cameraEssentialsLibrary = require(coreModule.GetObject("Libraries.CameraEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Methods
function specificClientAnimation.Play(goalCFrame, goalFOV)
    if not utilitiesLibrary.IsPlayerAlive() then return end
    cameraEssentialsLibrary.YieldTillCurrentCameraIsReadyForManipulation()

    -- Force the camera to a certain view.
    if typeof(goalCFrame) == "CFrame" then
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        coreModule.Services.TweenService:Create(
            workspace.CurrentCamera,
            TweenInfo.new(script:GetAttribute("Speed") or 1),
            {CFrame = goalCFrame}
        ):Play()
    end

    -- Force the camera's field of view.
    if typeof(goalFOV) == "number" then
        coreModule.Services.TweenService:Create(
            workspace.CurrentCamera,
            TweenInfo.new(script:GetAttribute("Speed") or 1),
            {FieldOfView = goalFOV}
        ):Play()
    end
end


--
return specificClientAnimation