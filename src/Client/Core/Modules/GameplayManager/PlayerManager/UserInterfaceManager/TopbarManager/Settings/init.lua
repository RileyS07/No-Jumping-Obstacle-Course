-- Variables
local specificInterfaceManager = {}
specificInterfaceManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local topbarManager = require(coreModule.GetObject("/Parent"))
local userInterfaceManager = require(coreModule.GetObject("/Parent.Parent"))

-- Initialize
function specificInterfaceManager.Initialize()
    specificInterfaceManager.Interface.Button = topbarManager.GetTopbarContainer():WaitForChild("Settings")
    specificInterfaceManager.Interface.Container = userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("Settings")
    specificInterfaceManager.Interface.SettingsContainer = specificInterfaceManager.Interface.Container:WaitForChild("Body"):WaitForChild("Container")
    specificInterfaceManager.Interface.SettingTypes = specificInterfaceManager.Interface.Container:WaitForChild("Body"):WaitForChild("Types")

    -- Open the settings container.
    specificInterfaceManager.Interface.Button.Activated:Connect(function()
        userInterfaceManager.UpdateActiveContainer(specificInterfaceManager.Interface.Container)
    end)

    -- Loading modules.
    coreModule.LoadModule("/MusicVolume")
    coreModule.LoadModule("/SoundEffectsVolume")
end


-- Methods
function specificInterfaceManager.GetSettingsContainer()
    return specificInterfaceManager.Interface.SettingsContainer
end


--
return specificInterfaceManager