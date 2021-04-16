-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.ResetMechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local mechanicsManager = require(coreModule.GetObject("/Parent"))
local cutsceneManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.CutsceneManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ForcedCameraViews")
	gameplayMechanicManager.ResetMechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ResetCameraViews")

    -- Setting up the ForcedCameraViews to be functional.
    for _, forcedCameraViewsContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, forcedCameraView in next, forcedCameraViewsContainer:GetChildren() do

            -- The PrimaryPart is what the player will touch, and Camera's CFrame is what their view will match.
            if forcedCameraView:IsA("Model") and forcedCameraView.PrimaryPart and forcedCameraView:FindFirstChild("Camera") then

				-- Player touched the pad.
				forcedCameraView.PrimaryPart.Touched:Connect(function(hit)
					local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
					
					-- Guard clause #1 is checking if the player is actually the LocalPlayer and that they're alive; #2 is checking if the CurrentCamera is valid.
					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end
					if not workspace.CurrentCamera then return end

					gameplayMechanicManager.SimulateForcedCameraView(forcedCameraView.Camera.CFrame)
				end)
			elseif forcedCameraView:IsA("Model") then
				coreModule.Debug(
					("ForcedCameraView: %s, has PrimaryPart: %s, has Camera: %s."):format(forcedCameraView:GetFullName(), tostring(forcedCameraView.PrimaryPart ~= nil), tostring(forcedCameraView:FindFirstChild("Camera") ~= nil)),
					coreModule.Shared.Enums.DebugLevel.Exception, 
					warn
				)
            end
        end
    end

	-- Setting up the ResetCameraViews to be functional.
	for _, resetCameraViewsContainer in next, gameplayMechanicManager.ResetMechanicContainer:GetChildren() do
        for _, resetCameraView in next, resetCameraViewsContainer:GetChildren() do

            -- The platform itself is what the player will touch.
            if resetCameraView:IsA("BasePart") then

				-- Player touched the platform.
				resetCameraView.Touched:Connect(function(hit)
					local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
					
					-- Guard clause #1 is checking if the player is actually the LocalPlayer and that they're alive; #2 is checking if the CurrentCamera is valid.
					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end
					if not workspace.CurrentCamera then return end

					gameplayMechanicManager.ResetForcedCameraView()
				end)
			else
				coreModule.Debug(
					("ResetCameraViews: %s, IsA: %s."):format(resetCameraView:GetFullName(), resetCameraView.ClassName),
					coreModule.Shared.Enums.DebugLevel.Exception, 
					warn
				)
            end
        end
    end
end


-- Methods
function gameplayMechanicManager.SimulateForcedCameraView(forcedCameraViewCFrame, functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		IgnoreCutsceneValues = false
	}})

	--[[
		These guard clauses check for 4 things:
		1) Is the forcedCameraViewCFrame valid?
		2) Is the client alive?
		3) Unless there's an exception are they being shown a cutscene?
		4) Is the CurrentCamera valid?
	]]
	
	if not forcedCameraViewCFrame or typeof(forcedCameraViewCFrame) ~= "CFrame" then return end
	if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
	if not functionParameters.IgnoreCutsceneValues and cutsceneManager.IsPlayerBeingShownCutscene() then return end
	if not workspace.CurrentCamera then return end
	cutsceneManager.YieldTillCameraIsReadyForManipulation()
	
	-- Force the camera to a certain view.
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	coreModule.Services.TweenService:Create(
		workspace.CurrentCamera,
		TweenInfo.new(1),
		{CFrame = forcedCameraViewCFrame}
	):Play()
end


function gameplayMechanicManager.ResetForcedCameraView(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		IgnoreCutsceneValues = false
	}})

	--[[
		These guard clauses check for 3 things:
		1) Is the client alive?
		2) Unless there's an exception are they being shown a cutscene?
		3) Is the CurrentCamera valid?
	]]

	if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
	if not functionParameters.IgnoreCutsceneValues and cutsceneManager.IsPlayerBeingShownCutscene() then return end
	if not workspace.CurrentCamera then return end
	cutsceneManager.YieldTillCameraIsReadyForManipulation()

	-- Reset the camera to their humanoid.
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	workspace.CurrentCamera.CameraSubject = clientEssentialsLibrary.GetPlayer().Character.Humanoid
end


--
return gameplayMechanicManager