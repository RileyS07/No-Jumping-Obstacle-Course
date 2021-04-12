-- Variables
local playerManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local userDataManager = require(coreModule.GetObject("/UserDataManager"))

-- Initialize
function playerManager.Initialize()
	coreModule.LoadModule("/UserDataManager")
	playerManager.SetupJoiningConnections()
	playerManager.SetupLeavingConnections()
end

-- Methods
function playerManager.SetupJoiningConnections()
	local function onPlayerAdded(player)
		userDataManager.LoadData(player)
		
		--
		coreModule.LoadModule("/Admin", player)
	end
	
	-- It is possible that a player could already be registered into the game before this code is ever loaded so we must do this
	for _, player in next, coreModule.Services.Players:GetPlayers() do onPlayerAdded(player) end 
	coreModule.Services.Players.PlayerAdded:Connect(onPlayerAdded)
end

function playerManager.SetupLeavingConnections()
	coreModule.Services.Players.PlayerRemoving:Connect(function(player)
		userDataManager.SaveData(player, true)
	end)
end

--
return playerManager