-- Variables
local topbarManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userInterfaceManager = require(coreModule.GetObject("/Parent"))

-- Initialize
function topbarManager.Initialize()
    coreModule.LoadModule("/Settings")
    coreModule.LoadModule("/StageSelection")
end


-- Methods
function topbarManager.GetTopbarContainer()
    return userInterfaceManager.GetInterface("MainInterface"):WaitForChild("Containers"):WaitForChild("TopbarContainer")
end


--
return topbarManager