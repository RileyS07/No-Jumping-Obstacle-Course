-- Variables
local gameplayManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Initialize
function gameplayManager.Initialize()
    coreModule.LoadModule("/")
end

--
return gameplayManager