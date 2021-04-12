-- Variables
local cutsceneManager = {}
cutsceneManager.IsPlayerBeingShownCutscene = false
cutsceneManager.IsPlayingBeingShownDialog = false
cutsceneManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent.UserInterfaceManager"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function cutsceneManager.Initialize()
	cutsceneManager.Interface.Container = userInterfaceManager.GetInterface("DialogInterface"):WaitForChild("Container")
	cutsceneManager.Interface.Content = cutsceneManager.Interface.Container:WaitForChild("Content")
	cutsceneManager.Interface.TextContent = cutsceneManager.Interface.Content:WaitForChild("TextContent")
	cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = 0
	
	--
	coreModule.LoadModule("/MechanicTutorials")
end

-- Methods
function cutsceneManager.StartDialogTextAnimation(finalDialogText, callbackFunction)
	if cutsceneManager.IsPlayerBeingShownDialog() then return end
	if not finalDialogText or typeof(finalDialogText) ~= "string" or finalDialogText == "" then return end
	userInterfaceManager.EnableInterface("DialogInterface", true)
	cutsceneManager.UpdatePlayerBeingShownDialog(true)
	
	-- Animation
	local animationCompletedEvent = Instance.new("BindableEvent")
	coroutine.wrap(function()
		cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = 0
		cutsceneManager.Interface.TextContent.Text = finalDialogText
		
		for index = 1, finalDialogText:len() do
			if callbackFunction then callbackFunction(finalDialogText:sub(1, index), coreModule.Enums.CutsceneTextAnimationCallbackState.Before) end
			
			-- Typewriter effect
			cutsceneManager.Interface.TextContent.MaxVisibleGraphemes = index
			soundEffectsManager.PlaySoundEffect("DialogTyping")
			wait(script:GetAttribute("DialogGraphemeDelay") or 1/30)
			
			if callbackFunction then callbackFunction(finalDialogText:sub(1, index), coreModule.Enums.CutsceneTextAnimationCallbackState.After) end
		end
		
		-- Finished
		cutsceneManager.UpdatePlayerBeingShownDialog(false)
		animationCompletedEvent:Fire()
	end)()
	
	--
	return animationCompletedEvent.Event
end

function cutsceneManager.TweenCurrentCameraCFrame(goalCFrame)
	if not workspace.CurrentCamera then return end
	return coreModule.Services.TweenService:Create(workspace.CurrentCamera, TweenInfo.new(1), {CFrame = goalCFrame})
end

function cutsceneManager.UpdatePlayerBeingShownCutscene(newValue)
	cutsceneManager.IsPlayerBeingShownCutscene = newValue
	if not cutsceneManager.IsPlayerBeingShownCutscene then
		userInterfaceManager.DisableInterface("DialogInterface")
		if utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then
			clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.Anchored = false
		end
	elseif utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then
		clientEssentialsLibrary.GetPlayer().Character.PrimaryPart.Anchored = true
	end
end

function cutsceneManager.IsPlayerBeingShownCutscene()
	return cutsceneManager.IsPlayerBeingShownCutscene
end

function cutsceneManager.UpdatePlayerBeingShownDialog(newValue)
	cutsceneManager.IsPlayingBeingShownDialog = newValue
end

function cutsceneManager.IsPlayerBeingShownDialog()
	return cutsceneManager.IsPlayingBeingShownDialog
end

function cutsceneManager.IsCameraReadyForManipulation()
	return workspace.CurrentCamera.CameraSubject ~= nil	
end

--
return cutsceneManager