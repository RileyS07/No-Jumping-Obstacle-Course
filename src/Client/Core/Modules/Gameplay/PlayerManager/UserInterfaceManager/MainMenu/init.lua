local CoreModule = require(script:FindFirstAncestor("Core"))
local UserInterfaceManager = require(CoreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

local ThisInterface: ScreenGui = UserInterfaceManager.GetInterface("MainMenu")
local ContainerFrame: Frame = ThisInterface:WaitForChild("Container")
local StagesContent: Frame = ContainerFrame:WaitForChild("Stages")
local SettingsContent: Frame = ContainerFrame:WaitForChild("SettingsContent")

local MainMenuManager = {}

-- Initialization
function MainMenuManager.Initialize()
    ContainerFrame:WaitForChild("StageSelection").Activated:Connect(function()
        StagesContent.Visible = not StagesContent.Visible
    end)

    ContainerFrame:WaitForChild("Settings").Activated:Connect(function()
        SettingsContent.Visible = not SettingsContent.Visible
    end)

    ContainerFrame:WaitForChild("TherapyZone").Activated:Connect(function()
        CoreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToBonusStage"):FireServer("Therapy Zone")
    end)

    CoreModule.LoadModule("/")
end

return MainMenuManager
