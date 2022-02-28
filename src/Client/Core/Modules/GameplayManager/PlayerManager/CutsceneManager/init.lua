-- Variables
local cutsceneManager = {}
cutsceneManager.Interface = {}
cutsceneManager.IsPlayingBeingShownDialogValue = false
cutsceneManager.IsPlayerBeingShownCutsceneValue = false

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("/Parent.UserInterfaceManager"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function cutsceneManager.Initialize()
	cutsceneManager.Interface.Container = userInterfaceManager.GetInterface("DialogInterface"):WaitForChild("Container")
	cutsceneManager.Interface.Content = cutsceneManager.Interface.Container:WaitForChild("Content")
	cutsceneManager.Interface.TextContent = cutsceneManager.Interface.Content:WaitForChild("TextContent")
	cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = 0

	-- Loading modules
	coreModule.LoadModule("/MechanicTutorials")
end


-- Methods
function cutsceneManager.StartDialogTextAnimation(finalDialogText, callbackFunction)

	-- Guard clause #1 checks if the player is in the middle of dialog; #2 checks if finalDialogText is valid.
	if cutsceneManager.IsPlayerBeingShownDialog() then return end
	if not finalDialogText or typeof(finalDialogText) ~= "string" or finalDialogText == "" then return end

	-- Setup the interface and values
	userInterfaceManager.EnableInterface("DialogInterface", {DisableOtherInterfaces = true})
	cutsceneManager.UpdatePlayerBeingShownDialog(true)

	-- Animation; I have animationCompletionEvent so that when you call this function we have the ability to yield if you want to.
	local animationCompletionEvent = Instance.new("BindableEvent")
	coroutine.wrap(function()
		cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = 0
		cutsceneManager.Interface.TextContent.Text = finalDialogText

		-- Typewriter effect; Reveal one grapheme at a time till they're all visible.
		for index = 1, finalDialogText:len() do
			if callbackFunction then
				callbackFunction(finalDialogText:sub(1, index), coreModule.Enums.CutsceneTextAnimationCallbackState.Before)
			end

			cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = index
			soundEffectsManager.PlaySoundEffect("DialogTyping")
			wait(script:GetAttribute("DialogGraphemeDelay") or (1 / 30))

			if callbackFunction then
				callbackFunction(finalDialogText:sub(1, index), coreModule.Enums.CutsceneTextAnimationCallbackState.After)
			end
		end

		-- Finished; Update the values and fire the event.
		cutsceneManager.UpdatePlayerBeingShownDialog(false)
		animationCompletionEvent:Fire()
		animationCompletionEvent:Destroy()
	end)()

	return animationCompletionEvent.Event
end


-- Updates values and cleans up after itself
function cutsceneManager.UpdatePlayerBeingShownCutscene(newValue)
	cutsceneManager.IsPlayerBeingShownCutsceneValue = newValue

	-- The cutscene ended so we need to clean up a little.
	if not cutsceneManager.IsPlayerBeingShownCutsceneValue then
		userInterfaceManager.DisableInterface("DialogInterface")

		if utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then
			clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.Anchored = false
		end

	-- Cap. Freeze them.
	elseif utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then
		clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.Anchored = true
	end
end


function cutsceneManager.IsPlayerBeingShownCutscene()
	return cutsceneManager.IsPlayerBeingShownCutsceneValue
end


function cutsceneManager.UpdatePlayerBeingShownDialog(newValue)
	cutsceneManager.IsPlayingBeingShownDialogValue = newValue
end


function cutsceneManager.IsPlayerBeingShownDialog()
	return cutsceneManager.IsPlayingBeingShownDialogValue
end


function cutsceneManager.IsCameraReadyForManipulation()
	return workspace.CurrentCamera.CameraSubject ~= nil
end


function cutsceneManager.YieldTillCameraIsReadyForManipulation()
	if not cutsceneManager.IsCameraReadyForManipulation() then
		repeat
			task.wait()
		until cutsceneManager.IsCameraReadyForManipulation()
	end
end


-- Private Methods
-- A consistent way of tweening the camera for cinematic effects.
function cutsceneManager.TweenCurrentCameraCFrame(goalCFrame, optionalTweenInformation)
	if not workspace.CurrentCamera then return end
	return game:GetService("TweenService"):Create(
		workspace.CurrentCamera,
		optionalTweenInformation or TweenInfo.new(1),
		{CFrame = goalCFrame}
	)
end


--
return cutsceneManager