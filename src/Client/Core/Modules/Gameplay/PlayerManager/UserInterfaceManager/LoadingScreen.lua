-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))
local clientEssentialsLibrary = require(coreModule.GetObject("Libraries.ClientEssentials"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.ScreenGui = userInterfaceManager.GetInterface("LoadingScreen")
    specificInterfaceManager.Interface.Background = specificInterfaceManager.Interface.ScreenGui:WaitForChild("Background")
	specificInterfaceManager.Interface.BackgroundImages = specificInterfaceManager.Interface.Background:WaitForChild("BackgroundImages")
    specificInterfaceManager.Interface.Container = specificInterfaceManager.Interface.Background:WaitForChild("Container")
    specificInterfaceManager.Interface.Content = specificInterfaceManager.Interface.Container:WaitForChild("Content")
    specificInterfaceManager.Interface.Information = specificInterfaceManager.Interface.Content:WaitForChild("Information")
    specificInterfaceManager.Interface.Logo = specificInterfaceManager.Interface.Content:WaitForChild("LogoContainer")
    specificInterfaceManager.Interface.Skip = specificInterfaceManager.Interface.Content:WaitForChild("Right"):WaitForChild("Skip")

    userInterfaceManager.EnableInterface(specificInterfaceManager.Interface.ScreenGui.Name, {DisableOtherInterfaces = true, IsPriority = true})
    game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
    clientEssentialsLibrary.SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

    clientAnimationsLibrary.PlayAnimation("LoadingScreenBackgroundImage", specificInterfaceManager.Interface.BackgroundImages)
    clientAnimationsLibrary.PlayAnimation("LoadingText...", specificInterfaceManager.Interface.Information:WaitForChild("Title"))

    -- We have to add this because some people have bad computers.
    task.delay(10, function()
        if userInterfaceManager.ActiveInterface ~= specificInterfaceManager.Interface.ScreenGui then return end
        coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()

        -- They still gotta press skip.
        specificInterfaceManager.Interface.Skip.Visible = true
        local activatedConnection; activatedConnection = specificInterfaceManager.Interface.Skip.Activated:Connect(function()
            activatedConnection:Disconnect()
            specificInterfaceManager.Interface.Skip.Visible = false

            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish",
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImages, specificInterfaceManager.Interface.Content
            )

            specificInterfaceManager.Interface = nil
        end)
    end)

    -- Let's load everything then go from there.
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation("LoadingScreenLoadAssets", specificInterfaceManager.Interface.Information:WaitForChild("Description"))
        coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer()

        task.wait(5)

        if not specificInterfaceManager.Interface or not specificInterfaceManager.Interface.Skip.Visible then return end

        if userInterfaceManager.ActiveInterface == specificInterfaceManager.Interface.ScreenGui then
            clientAnimationsLibrary.PlayAnimation(
                "LoadingScreenFinish",
                specificInterfaceManager.Interface.Information, specificInterfaceManager.Interface.BackgroundImages, specificInterfaceManager.Interface.Content
            )

            specificInterfaceManager.Interface = nil
        end
    end)()
end


--
return specificInterfaceManager