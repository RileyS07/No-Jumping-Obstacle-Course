-- Variables
local tutorialManager = {}
tutorialManager.Stage = 4

local coreModule = require(script:FindFirstAncestor("Core"))
local cutsceneManager = require(coreModule.GetObject("/Parent.Parent"))
local buttonMechanicManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager.Buttons"))

-- PlayTutorial
function tutorialManager.PlayTutorial()

	-- Setup common variables
	local buttonObject = workspace.Map.Gameplay:WaitForChild("PlatformerMechanics"):WaitForChild("Buttons"):WaitForChild("Zone1"):WaitForChild("FirstButton")
	local buttonTutorialStorage = workspace.Map.Gameplay:WaitForChild("TutorialStorage"):WaitForChild("Buttons")
	local currentCamera = workspace.CurrentCamera
	currentCamera.CameraType = Enum.CameraType.Scriptable
	
	-- Mechanic Description Animation
	local mechanicDescriptionCameraTween = cutsceneManager.TweenCurrentCameraCFrame(CFrame.lookAt(buttonTutorialStorage["1"].Position, buttonTutorialStorage:WaitForChild("Mechanic Description"):GetPrimaryPartCFrame().Position))
	mechanicDescriptionCameraTween:Play()
	mechanicDescriptionCameraTween.Completed:Wait()

	cutsceneManager.StartDialogTextAnimation("What's this? A button? Hmm...", function(currentText, cutsceneTextAnimationCallbackState)
		if cutsceneTextAnimationCallbackState ~= coreModule.Enums.CutsceneTextAnimationCallbackState.After then return end
		if currentText == "What's this? " or currentText == "What's this? A button? " or currentText == "What's this? A button? Hmm..." then
			wait(1)
		end
	end):Wait()
	
	-- Button Pressing Animation
	local buttonPressingCameraTween = cutsceneManager.TweenCurrentCameraCFrame(CFrame.lookAt(buttonTutorialStorage["2"].Position, buttonObject:GetPrimaryPartCFrame().Position))
	buttonPressingCameraTween:Play()
	buttonPressingCameraTween.Completed:Wait()

	cutsceneManager.StartDialogTextAnimation("Let's see what happens when we press this button...", function(currentText, cutsceneTextAnimationCallbackState)
		if cutsceneTextAnimationCallbackState ~= coreModule.Enums.CutsceneTextAnimationCallbackState.After then return end
		if currentText == "Let's see what happens when we press this button..." then
			wait(0.5)
		end
	end):Wait()

	buttonMechanicManager.SimulatePlatform(buttonObject, {ManualSimulationLength = 7})
	
	-- Transformation Animation
	local transformationCameraTween = cutsceneManager.TweenCurrentCameraCFrame(CFrame.lookAt(buttonTutorialStorage["3"].Position, buttonObject.TransformationModel:GetPrimaryPartCFrame().Position))
	transformationCameraTween:Play()
	transformationCameraTween.Completed:Wait()

	cutsceneManager.StartDialogTextAnimation("Woah! This wedge is no longer invisible!", function(currentText, cutsceneTextAnimationCallbackState)
		if cutsceneTextAnimationCallbackState ~= coreModule.Enums.CutsceneTextAnimationCallbackState.After then return end
		if currentText == "Woah! " then
			wait(1)
		elseif currentText == "Woah! This wedge is no longer invisible!" then
			wait(1.5)
		end
	end):Wait()
	
	-- Finished + Clean up
	cutsceneManager.StartDialogTextAnimation("Go give it a try yourself now!"):Wait()
	repeat game:GetService("RunService").RenderStepped:Wait() until not buttonMechanicManager.IsPlatformBeingSimulated(buttonObject)
	currentCamera.CameraType = Enum.CameraType.Track
end


--
return tutorialManager