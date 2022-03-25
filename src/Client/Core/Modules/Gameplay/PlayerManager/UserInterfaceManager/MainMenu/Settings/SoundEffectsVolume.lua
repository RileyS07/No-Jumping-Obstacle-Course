-- Variables
local specificSettingManager = {}
specificSettingManager.Interface = {}
specificSettingManager.CurrentSettingValue = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local settingsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager.MainMenu.Settings"))
local soundEffectsManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.SoundEffects"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificSettingManager.Initialize()
    specificSettingManager.Interface.Slider = settingsManager.GetSettingsContainer():WaitForChild("Sound"):WaitForChild("Content"):WaitForChild("Slider")

    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation(
            "Slider",
            specificSettingManager.Interface.Slider,
            coreModule.Shared.GetObject("//Remotes.GetUserData"):InvokeServer().Settings.SoundEffectsVolumeModifier,
            function(newValue)
                soundEffectsManager.UpdateSetting(newValue)
                specificSettingManager.Interface.Slider:WaitForChild("Percentage").Text = tostring(math.floor(100*newValue)).."%"
                specificSettingManager.CurrentSettingValue = newValue
            end
        )

        -- Automatically update setting on the server.
        local lastSettingValue = specificSettingManager.CurrentSettingValue
        local updateSettingValue = coreModule.Shared.GetObject("//Remotes.Data.UpdateSettingValue")
        while true do
            if lastSettingValue ~= specificSettingManager.CurrentSettingValue then
                updateSettingValue:FireServer("SoundEffectsVolumeModifier", specificSettingManager.CurrentSettingValue)
                lastSettingValue = specificSettingManager.CurrentSettingValue
            end

            task.wait(1)
        end
    end)()
end


--
return specificSettingManager