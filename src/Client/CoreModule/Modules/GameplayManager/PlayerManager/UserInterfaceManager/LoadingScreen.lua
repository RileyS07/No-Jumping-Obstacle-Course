-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("LoadingScreen")
    specificInterfaceManager.Interface.BackgroundImage = specificInterfaceManager.Interface.ScreenGui:WaitForChild("BackgroundImage")
    specificInterfaceManager.Interface.Container = specificInterfaceManager.Interface.BackgroundImage:WaitForChild("Container")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
    specificInterfaceManager.Interface.Information = specificInterfaceManager.Interface.Content:WaitForChild("Information")
    specificInterfaceManager.Interface.Logo = specificInterfaceManager.Interface.Content:WaitForChild("LogoContainer")
    specificInterfaceManager.Interface.Skip = specificInterfaceManager.Interface.Content:WaitForChild("Right"):WaitForChild("Skip")

    userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true, IsPriority = true})
    coreModule.Services.ReplicatedFirst:RemoveDefaultLoadingScreen()
    clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    clientAnimationsLibrary.PlayAnimation("LoadingScreenBackgroundImage", specificInterfaceManager.Interface.BackgroundImage)
    clientAnimationsLibrary.PlayAnimation("LoadingText...", specificInterfaceManager.Interface.Information:WaitForChild("Title"))

    -- We have to add this because some people have bad computers.
    delay(10, function()
        if userInterfaceManager.GetPriorityInterface() ~= specificInterfaceManager.Interface.ScreenGui then return end
        coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()

        -- They still gotta press skip.
        specificInterfaceManager.Interface.Skip.Visible = true
        local activatedConnection; activatedConnection = specificInterfaceManager.Interface.Skip.Activated:Connect(function()
            activatedConnection:Disconnect()
            specificInterfaceManager.Interface.Skip.Visible = false

            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish", 
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImage, specificInterfaceManager.Interface.Content
            )
        end)
    end)

    -- Let's load everything then go from there.
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation("LoadingScreenLoadAssets", specificInterfaceManager.Interface.Information:WaitForChild("Description"))
        coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer()
        
        wait(5)

        if userInterfaceManager.GetPriorityInterface() == specificInterfaceManager.Interface.ScreenGui then 
            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish", 
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImage, specificInterfaceManager.Interface.Content
            )
        end
    end)()
end


--
return specificInterfaceManager

--[[
    -- Variables
local loadingScreenInterface = {}
loadingScreenInterface.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))
local playerSetupManager = require(coreModule.GetObject("Game.PlayerManager.PlayerSetupManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local interfaceTransparencyModifierLibrary = require(coreModule.GetObject("Libraries.InterfaceTransparencyModifier"))
local config = require(script.Config)

-- Initialize
function loadingScreenInterface.Initialize()
	loadingScreenInterface.Interface.InterfaceObject = userInterfaceManager.GetInterface("LoadingScreen")
	loadingScreenInterface.Interface.Container = loadingScreenInterface.Interface.InterfaceObject:WaitForChild("Container")
	loadingScreenInterface.Interface.TopText = loadingScreenInterface.Interface.Container:WaitForChild("TopText")
	loadingScreenInterface.Interface.BottomText = loadingScreenInterface.Interface.Container:WaitForChild("BottomText")
	loadingScreenInterface.Interface.Logo = loadingScreenInterface.Interface.Container:WaitForChild("Logo")
	
	--
	loadingScreenInterface.Setup()
	coroutine.wrap(loadingScreenInterface.SetupPreloading)()
end

-- Methods
function loadingScreenInterface.Setup()
	userInterfaceManager.DisableInterfaces()
	clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	
	loadingScreenInterface.Interface.InterfaceObject.Enabled = true
	coreModule.Services.ReplicatedFirst:RemoveDefaultLoadingScreen()
end

function loadingScreenInterface.SetupPreloading()
	-- Logo Movement Animation
	coroutine.wrap(function()
		while loadingScreenInterface.Interface.InterfaceObject.Enabled do
			local upwardsMovementTween = coreModule.Services.TweenService:Create(loadingScreenInterface.Interface.Logo:WaitForChild("Fill"), TweenInfo.new(config.AnimationInformation.LogoMovementDuration, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0.5, 0.9)})
			upwardsMovementTween:Play()
			upwardsMovementTween.Completed:Wait()
			
			local downwardsMovementTween = coreModule.Services.TweenService:Create(loadingScreenInterface.Interface.Logo:WaitForChild("Fill"), TweenInfo.new(config.AnimationInformation.LogoMovementDuration, Enum.EasingStyle.Linear), {Position = UDim2.fromScale(0.5, 1.1)})
			downwardsMovementTween:Play()
			downwardsMovementTween.Completed:Wait()
		end
	end)()
	
	-- ... Animation
	coroutine.wrap(function()
		while loadingScreenInterface.Interface.InterfaceObject.Enabled do
			for index = 1, config.AnimationInformation.MaximumNumberOfPeriodsFollowingTopText do
				loadingScreenInterface.Interface.TopText.Text = loadingScreenInterface.Interface.TopText.Text:match("[%w+%s?]+")..("."):rep(index)
				wait(config.AnimationInformation.DelayBetweenNewPeriod)
			end
		end
	end)()
	
	-- Preload the Interface
	loadingScreenInterface.Interface.BottomText.Text = "Loading in the Interface"
	coreModule.Services.ContentProvider:PreloadAsync(clientEssentialsLibrary.GetPlayer():WaitForChild("PlayerGui"):GetChildren())
	wait(config.DelayBetweenPreloadingClusters)
	
	-- Preload the Assets
	loadingScreenInterface.Interface.BottomText.Text = "Loading in Assets"
	coreModule.Services.ContentProvider:PreloadAsync(coreModule.Shared.GetObject("//Assets"):GetChildren())
	wait(config.DelayBetweenPreloadingClusters)
	
	-- Preload the workspace
	loadingScreenInterface.Interface.BottomText.Text = "Loading in the Map"
	coreModule.Services.ContentProvider:PreloadAsync(workspace:GetChildren())
	loadingScreenInterface.FinishLoading()
end

function loadingScreenInterface.FinishLoading()
	interfaceTransparencyModifierLibrary.FadeTransparency(loadingScreenInterface.Interface.InterfaceObject, 1, 1).Completed:Wait()
	loadingScreenInterface.Interface.InterfaceObject.Enabled = false
	userInterfaceManager.CanSwitchInterfaces = true
	userInterfaceManager.UpdateDeviceSpecificInterface()
	playerSetupManager.UpdateCoreGuis()
end

--
return loadingScreenInterface 
]]