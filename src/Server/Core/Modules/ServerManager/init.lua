local coreModule = require(script:FindFirstAncestor("Core"))

local ServerManager = {}

-- Initialize
function ServerManager.Initialize()
    coreModule.LoadModule("/VersionUpdates")
    coreModule.LoadModule("/PurchaseManager")
end

return ServerManager
