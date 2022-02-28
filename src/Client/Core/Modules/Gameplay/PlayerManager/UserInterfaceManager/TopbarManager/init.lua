-- Variables
local topbarManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local userInterfaceManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserInterfaceManager"))

-- Initialize
function topbarManager.Initialize()
    coreModule.LoadModule("/Settings")
    coreModule.LoadModule("/StageSelection")
    coreModule.LoadModule("/Skipping")
end


-- Methods
function topbarManager.GetTopbarContainer()
    return userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TopbarContainer")
end


--
return topbarManager