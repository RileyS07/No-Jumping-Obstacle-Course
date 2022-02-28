-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil
gameplayMechanicManager.ResetMechanicContainer = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local mechanicsManager = require(coreModule.GetObject("Modules.GameplayManager.MechanicsManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ForcedCameraViews")
	gameplayMechanicManager.ResetMechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ResetCameraViews")

    -- Setting up the platform to be functional.
    for _, platformContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, platformObject in next, platformContainer:GetChildren() do
            if platformObject:IsA("Model") and platformObject.PrimaryPart then
				platformObject.PrimaryPart.Touched:Connect(function(hit)
					local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive(player) then return end

					-- Update the camera.
					gameplayMechanicManager.SimulateForcedCameraView(
						(platformObject:FindFirstChild("Camera") and (platformObject.Camera:IsA("BasePart") or platformObject.Camera:IsA("Camera"))) and platformObject.Camera.CFrame,
						script:GetAttribute("FieldOfView")
					)
				end)
			elseif platformObject:IsA("Model") then
				print(
					("ForcedCameraView: %s, has PrimaryPart: %s, has Camera: %s."):format(platformObject:GetFullName(), tostring(platformObject.PrimaryPart ~= nil), tostring(platformObject:FindFirstChild("Camera") ~= nil)),
					warn
				)
            end
        end
    end

	-- Setting up the platform to be functional.
	for _, resetCameraViewsContainer in next, gameplayMechanicManager.ResetMechanicContainer:GetChildren() do
        for _, resetCameraView in next, resetCameraViewsContainer:GetChildren() do
            if resetCameraView:IsA("BasePart") then
				resetCameraView.Touched:Connect(function(hit)
					local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
					if player ~= clientEssentialsLibrary.GetPlayer() or not utilitiesLibrary.IsPlayerAlive() then return end

					gameplayMechanicManager.ResetForcedCameraView()
				end)
			else
				print(
					("ResetCameraViews: %s, IsA: %s."):format(resetCameraView:GetFullName(), resetCameraView.ClassName),
					warn
				)
            end
        end
    end

	coreModule.Shared.GetObject("//Remotes.Gameplay.Miscellaneous.RestoreDefaultPlayerConditions").OnClientEvent:Connect(function()
		gameplayMechanicManager.ResetForcedCameraView()
	end)
end


-- Methods
function gameplayMechanicManager.SimulateForcedCameraView(goalCFrame, goalFOV)
	clientAnimationsLibrary.PlayAnimation("ApplyForcedCameraView", goalCFrame, goalFOV)
end


function gameplayMechanicManager.ResetForcedCameraView()
	clientAnimationsLibrary.PlayAnimation("ResetCameraView")
end


--
return gameplayMechanicManager