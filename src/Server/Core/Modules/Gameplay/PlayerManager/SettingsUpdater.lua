--[[
    This module's purpose is just to copy over setting changes
    done on the client into their userdata.
]]

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))

local SettingsUpdater = {}

-- Initialize
function SettingsUpdater.Initialize()

    -- The client is signaling then want to update something.
    coreModule.Shared.GetObject("//Remotes.Data.UpdateSettingValue").OnServerEvent:Connect(function(player: Player, settingName: string, newValue: any)

        -- First we need to make sure the datatypes are correct.
        if typeof(settingName) ~= "string" then return end
        if typeof(newValue) == "nil" then return end

        -- Now we need to check if the setting data is valid for this setting.
        local userData: {} = userDataManager.GetData(player)

        if not userData then return end
        if typeof(userData.Settings[settingName]) ~= typeof(newValue) then return end

        -- All is good! We can update it!
        userData.Settings[settingName] = newValue
    end)
end

return SettingsUpdater
