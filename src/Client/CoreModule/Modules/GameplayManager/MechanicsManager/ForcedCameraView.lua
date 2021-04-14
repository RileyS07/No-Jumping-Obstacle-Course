-- Variables
local gameplayMechanicManager = {}
gameplayMechanicManager.MechanicContainer = nil

-- Initialize
function gameplayMechanicManager.Initialize()
    gameplayMechanicManager.MechanicContainer = mechanicsManager.GetPlatformerMechanics():WaitForChild("ForcedCameraViews")

    -- Setting up the ForcedCameraViews to be functional.
    for _, forcedCameraViewsContainer in next, gameplayMechanicManager.MechanicContainer:GetChildren() do
        for _, forcedCameraView in next, forcedCameraViewsContainer:GetChildren() do

            -- The PrimaryPart is what the player will touch, and Camera's CFrame is what their view will match.
            if forcedCameraView:IsA("Model") and forcedCameraView.PrimaryPart and forcedCameraView:FindFirstChild("Camera") then

            else
				--coreModule.Debug("ForcedCameraView: "..forcedCameraView:GetFullName().." has PrimaryPart: "..tostring(spinningPlatform.PrimaryPart ~= nil)..", has Stand: "..tostring(spinningPlatform:FindFirstChild("Stand") ~= nil)..".", coreModule.Shared.Enums.DebugLevel.Exception, warn)
            end
        end
    end
end


--
return gameplayMechanicManager
--[[

-- Variables
local forcedCameraAnglesMechanic = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local clientMechanicsManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local config = require(script.Config)

-- Initialize
function forcedCameraAnglesMechanic.Initialize()
	if not clientMechanicsManager.GetPlatformerMechanicsContainer():FindFirstChild("Forced Camera Angles") then return end
	
	--
	for _, mechanicContainer in next, clientMechanicsManager.GetPlatformerMechanicsContainer()["Forced Camera Angles"]:GetChildren() do
		if mechanicContainer:IsA("Model") and mechanicContainer.PrimaryPart and mechanicContainer:FindFirstChild("Camera") then
			mechanicContainer.PrimaryPart.Touched:Connect(function(hit)
				local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
				if not utilitiesLibrary.IsPlayerAlive(player) then return end
				if player ~= clientEssentialsLibrary.GetPlayer() then return end
				if not workspace.CurrentCamera then return end
				
				--
				workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
				coreModule.Services.TweenService:Create(workspace.CurrentCamera, TweenInfo.new(config.AnimationLength), {CFrame = mechanicContainer.Camera.CFrame}):Play()
			end)
		end
	end
	
	-- Restoration
	if clientMechanicsManager.GetPlatformerMechanicsContainer():FindFirstChild("Reset Camera Angles") then
		for _, mechanicContainer in next, clientMechanicsManager.GetPlatformerMechanicsContainer()["Reset Camera Angles"]:GetChildren() do
			if mechanicContainer:IsA("BasePart") then
				mechanicContainer.Touched:Connect(function(hit)
					local player = coreModule.Services.Players:GetPlayerFromCharacter(hit.Parent)
					if not utilitiesLibrary.IsPlayerAlive(player) then return end
					if player ~= clientEssentialsLibrary.GetPlayer() then return end
					if not workspace.CurrentCamera then return end
					
					--
					workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
					workspace.CurrentCamera.CameraSubject = clientEssentialsLibrary.GetPlayer().Character.Humanoid
				end)
			end
		end
	end
	
	coreModule.Shared.GetObject("//Remotes.RestoreDefaultPlayerConditions").OnClientEvent:Connect(function()
		if not utilitiesLibrary.IsPlayerAlive(clientEssentialsLibrary.GetPlayer()) then return end
		if not workspace.CurrentCamera then return end
		
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		workspace.CurrentCamera.CameraSubject = clientEssentialsLibrary.GetPlayer().Character.Humanoid
	end)
end

--
return forcedCameraAnglesMechanic
]]