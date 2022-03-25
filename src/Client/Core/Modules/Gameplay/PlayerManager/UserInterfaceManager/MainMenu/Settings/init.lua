-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainMenu"):WaitForChild("Container"):WaitForChild("SettingsContent")
    specificInterfaceManager.Interface.SettingsContainer = specificInterfaceManager.Interface.Container:WaitForChild("List"):WaitForChild("Scroll"):WaitForChild("Content")

    coreModule.LoadModule("/")
end


-- Methods
function specificInterfaceManager.GetSettingsContainer()
    return specificInterfaceManager.Interface.SettingsContainer
end


--
return specificInterfaceManager