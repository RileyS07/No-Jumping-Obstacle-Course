-- Variables
local serverManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))

-- Initialize
function serverManager.Initialize()
    coreModule.LoadModule("/VersionUpdates")
    coreModule.LoadModule("/PurchaseManager")
end

--
return serverManager