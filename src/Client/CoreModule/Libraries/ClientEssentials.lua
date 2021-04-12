-- Variables
local clientEssentialsLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function clientEssentialsLibrary.GetPlayer()
	return coreModule.Services.Players.LocalPlayer
end

--
return clientEssentialsLibrary