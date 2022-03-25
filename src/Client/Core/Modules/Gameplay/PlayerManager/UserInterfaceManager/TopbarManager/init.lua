local CoreModule = require(script:FindFirstAncestor("Core"))
local UserInterfaceManager = require(CoreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local TopbarContainer: Instance = UserInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TopbarContainer")
local MainMenuInterface: ScreenGui = UserInterfaceManager.GetInterface("MainMenu")

local TopbarManager = {}

-- Initialization.
function TopbarManager.Initialize()
    CoreModule.LoadModule("/")

    TopbarContainer:WaitForChild("MainMenu").Activated:Connect(function()
        UserInterfaceManager.UpdateInterfaceShown(MainMenuInterface)
    end)
end

-- Gets the topbar container.
function TopbarManager.GetTopbarContainer() : Instance
    return TopbarContainer
end

return TopbarManager
