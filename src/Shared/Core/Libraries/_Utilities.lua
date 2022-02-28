-- Variables
local utilitiesLibrary = {}

-- Methods
-- Mostly used in addition with IsPlayerAlive but is still a useful function for type checking for Player.
function utilitiesLibrary.IsPlayerValid(player)
	player = player or (game:GetService("RunService"):IsClient() and game:GetService("Players").LocalPlayer)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then return end
	if not player:IsDescendantOf(game:GetService("Players")) then return end

	return true
end


-- A super useful function that leaves almost 0 room for error to check if a player is alive.
function utilitiesLibrary.IsPlayerAlive(player)
	player = player or (game:GetService("RunService"):IsClient() and game:GetService("Players").LocalPlayer)
	if not utilitiesLibrary.IsPlayerValid(player) then return end

	if not player.Character then return end
	if not player.Character.PrimaryPart then return end
	if not player.Character:FindFirstChildOfClass("Humanoid") then return end
	if not player.Character:FindFirstChild("HumanoidRootPart") then return end
	if player.Character:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead then return end

	return true
end


-- Creates an object in a single line.
function utilitiesLibrary.Create(instanceName, propertiesDictionary)
	if typeof(instanceName) ~= "string" then return end
	if typeof(propertiesDictionary) ~= "table" then return end

	local instanceObject = Instance.new(instanceName)
	for propertyName, propertyValue in next, propertiesDictionary do
		if propertyName ~= "Parent" then
			instanceObject[propertyName] = propertyValue
		end
	end

	-- Add parent afterwards.
	instanceObject.Parent = propertiesDictionary.Parent
	return instanceObject
end


-- Nil safe Destroy.
function utilitiesLibrary.Destroy(instanceObject)
	if typeof(instanceObject) ~= "Instance" then return end
	instanceObject:Destroy()
end


--
return utilitiesLibrary