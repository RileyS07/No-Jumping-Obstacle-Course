-- Variables
local gameplayManager = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Initialize
function gameplayManager.Initialize()
	if not workspace:FindFirstChild("Map") then return end
	if not workspace.Map:FindFirstChild("Gameplay") then return end
	
	print("This works???")
	--[[
	coreModule.LoadModule("/PlayerManager")
	coreModule.LoadModule("/MechanicsManager")
	coreModule.LoadModule("/EventsManager")]]
end

--
return gameplayManager