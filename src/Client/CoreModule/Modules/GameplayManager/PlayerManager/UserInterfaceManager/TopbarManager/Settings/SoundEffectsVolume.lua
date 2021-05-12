-- Variables
local specificSettingManager = {}
specificSettingManager.Interface = {}
specificSettingManager.CurrentSettingValue = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local settingsManager = require(coreModule.GetObject("/Parent"))
local soundEffectsManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.SoundEffects"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificSettingManager.Initialize()
    specificSettingManager.Interface.Slider = settingsManager.GetSettingsContainer():WaitForChild("Audio"):WaitForChild("SoundEffects"):WaitForChild("Setting"):WaitForChild("Slider")
   
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation(
            "Slider", 
            specificSettingManager.Interface.Slider, 
            coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer().Settings.SoundEffectsVolumeModifier,
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

            wait(1)
        end
    end)()
end


--
return specificSettingManager