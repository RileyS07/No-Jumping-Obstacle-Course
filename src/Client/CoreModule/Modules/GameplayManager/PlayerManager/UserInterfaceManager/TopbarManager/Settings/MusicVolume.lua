-- Variables
local specificSettingManager = {}
specificSettingManager.Interface = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local settingsManager = require(coreModule.GetObject("/Parent"))
local gameplayMusicManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.GameplayMusic"))
local userInterfaceManager = require(coreModule.GetObject("Modules.GameplayManager.PlayerManager.UserInterfaceManager"))
local clientAnimationsLibrary = require(coreModule.GetObject("Libraries.ClientAnimations"))

-- Initialize
function specificSettingManager.Initialize()
    specificSettingManager.Interface.Slider = settingsManager.GetSettingsContainer():WaitForChild("Audio"):WaitForChild("Music"):WaitForChild("Setting"):WaitForChild("Slider")
   
    coroutine.wrap(function()
        clientAnimationsLibrary.PlayAnimation("Slider", specificSettingManager.Interface.Slider, 0.5, function(newValue)
            if gameplayMusicManager.MusicState ~= coreModule.Enums.MusicState.Playing then
                repeat wait() until gameplayMusicManager.MusicState == coreModule.Enums.MusicState.Playing
            end
            
            gameplayMusicManager.UpdateSetting(newValue)
            specificSettingManager.Interface.Slider:WaitForChild("Percentage").Text = tostring(math.floor(100*newValue)).."%"
        end)
    end)()
end


--
return specificSettingManager