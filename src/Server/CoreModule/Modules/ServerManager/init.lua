-- Variables
local serverManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function serverManager.Initialize()
    coreModule.LoadModule("/VersionUpdates")
end


--
return serverManager