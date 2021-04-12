-- Variables
local utilitiesLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function utilitiesLibrary.IsPlayerValid(player)
	if typeof(player) ~= "Instance" then return end
	if not player:IsA("Player") then return end
	if not player:IsDescendantOf(coreModule.Services.Players) then return end
	return true
end

function utilitiesLibrary.IsPlayerAlive(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not player.Character then return end
	if not player.Character.PrimaryPart then return end
	if not player.Character:FindFirstChildOfClass("Humanoid") then return end
	if player.Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead then return end
	return true
end

--
return utilitiesLibrary