-- Variables
local specificClientAnimation = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local cameraEssentialsLibrary = require(coreModule.GetObject("Libraries.CameraEssentials"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Methods
function specificClientAnimation.Play()
    if not utilitiesLibrary.IsPlayerAlive() then return end
    cameraEssentialsLibrary.YieldTillCurrentCameraIsReadyForManipulation()

    -- Reset the camera to their humanoid.
	local currentCamera: Camera = workspace.CurrentCamera
    currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CameraSubject = clientEssentialsLibrary.GetPlayer().Character.Humanoid :: Humanoid

	game:GetService("TweenService"):Create(
		workspace.CurrentCamera,
		TweenInfo.new(1, Enum.EasingStyle.Linear),
		{FieldOfView = 70}
	):Play()
end


--
return specificClientAnimation