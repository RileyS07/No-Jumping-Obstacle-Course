-- Variables
local settingsManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))

-- Initialize
function settingsManager.Initialize()

    -- Updates the setting's value in the data.
    coreModule.Shared.GetObject("//Remotes.Data.UpdateSettingValue").OnServerEvent:Connect(function(player, settingName, newValue)
        if not userDataManager.GetData(player) then return end
        if typeof(settingName) ~= "string" then return end
        if typeof(newValue) == "nil" then return end
        if userDataManager.GetData(player).Settings[settingName] == nil then return end

        userDataManager.GetData(player).Settings[settingName] = newValue
    end)
end


--
return settingsManager