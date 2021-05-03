-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local cameraEssentialsLibrary = require(coreModule.GetObject("Libraries.CameraEssentials"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Methods
function specificClientAnimation.Play()
    if not utilitiesLibrary.IsPlayerAlive() then return end
    cameraEssentialsLibrary.YieldTillCurrentCameraIsReadyForManipulation()

    -- Reset the camera to their humanoid.
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	workspace.CurrentCamera.CameraSubject = clientEssentialsLibrary.GetPlayer().Character.Humanoid
	coreModule.Services.TweenService:Create(
		workspace.CurrentCamera,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{FieldOfView = 70}
	):Play()
end


--
return specificClientAnimation