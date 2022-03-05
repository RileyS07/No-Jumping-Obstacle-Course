local players: Players = game:GetService("Players")
local tweenService: TweenService = game:GetService("TweenService")

local tweenInformation: TweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
local thisPlayer: Player = players.LocalPlayer

local ThisAnimationManager = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local cameraUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.CameraUtilities"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

-- Plays this animation.
function ThisAnimationManager.Play()

	-- If they're not alive then we can't do anything.
    if not playerUtilities.IsPlayerAlive() then return end

	-- We should wait till we can manipulate it, just in case.
    cameraUtilities.WaitTillCurrentCameraIsManipulatable()

    -- Reset their view back to their Humanoid.
	local currentCamera: Camera = cameraUtilities.GetCurrentCamera()
    currentCamera.CameraType = Enum.CameraType.Custom
	currentCamera.CameraSubject = thisPlayer.Character.Humanoid :: Humanoid

	-- Tweening it back to normal.
	tweenService:Create(
		currentCamera,
		tweenInformation,
		{FieldOfView = sharedConstants.GENERAL.DEFAULT_FIELD_OF_VIEW}
	):Play()
end

return ThisAnimationManager
