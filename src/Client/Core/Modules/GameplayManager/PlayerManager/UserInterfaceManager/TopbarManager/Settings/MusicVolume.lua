-- Variables
local specificSettingManager = {}
specificSettingManager.Interface = {}
specificSettingManager.CurrentSettingValue = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local settingsManager = require(coreModule.GetObject("/Parent"))
local gameplayMusicManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.GameplayMusic"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificSettingManager.Initialize()
    specificSettingManager.Interface.Slider = settingsManager.GetSettingsContainer():WaitForChild("Audio"):WaitForChild("Music"):WaitForChild("Setting"):WaitForChild("Slider")
   
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation(
            "Slider", 
            specificSettingManager.Interface.Slider, 
            coreModule.Shared.GetObject("//Remotes.Data.GetUserData"):InvokeServer().Settings.MusicVolumeModifier,
            function(newValue)
                if gameplayMusicManager.MusicState ~= coreModule.Enums.MusicState.Playing then
                    repeat wait() until gameplayMusicManager.MusicState == coreModule.Enums.MusicState.Playing
                end
                
                gameplayMusicManager.UpdateSetting(newValue)
                specificSettingManager.Interface.Slider:WaitForChild("Percentage").Text = tostring(math.floor(100*newValue)).."%"
                specificSettingManager.CurrentSettingValue = newValue
            end
        )

        -- Automatically update setting on the server.
        local lastSettingValue = specificSettingManager.CurrentSettingValue
        local updateSettingValue = coreModule.Shared.GetObject("//Remotes.Data.UpdateSettingValue")
        while true do
            if lastSettingValue ~= specificSettingManager.CurrentSettingValue then
                updateSettingValue:FireServer("MusicVolumeModifier", specificSettingManager.CurrentSettingValue)
                lastSettingValue = specificSettingManager.CurrentSettingValue
            end

            wait(1)
        end
    end)()
end


--
return specificSettingManager