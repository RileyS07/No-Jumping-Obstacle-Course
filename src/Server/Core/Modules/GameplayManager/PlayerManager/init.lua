-- Variables
local playerManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("/UserDataManager"))
local collisionsLibrary = require(coreModule.Shared.GetObject("Libraries.Collisions"))

-- Initialize
function playerManager.Initialize()
	coreModule.LoadModule("/UserDataManager")

	-- This is for PlayerAdded and PlayerRemoving neatness.
	playerManager.SetupJoiningConnections()
	playerManager.SetupLeavingConnections()

	collisionsLibrary.CollisionGroupSetCollidable("Players", "Players", false)
end


-- Private Methods
function playerManager.SetupJoiningConnections()
	local function onPlayerAdded(player)
		playerManager.SetupCharacterConnections(player)
		userDataManager.LoadData(player)
		coreModule.LoadModule("/JoiningBadges", player)
	end

	-- It's possible that a player could already be registered into the game before this code is ever loaded so we must do this.
	for _, player in next, game:GetService("Players"):GetPlayers() do onPlayerAdded(player) end 
	game:GetService("Players").PlayerAdded:Connect(onPlayerAdded)
end


function playerManager.SetupLeavingConnections()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		userDataManager.SaveData(player, true)
	end)
end


function playerManager.SetupCharacterConnections(player)
	local function characterApperanceLoaded(character)
		collisionsLibrary.SetDescendantsCollisionGroup(character, "Players")
		coreModule.LoadModule("/CharacterManager", player, character)
	end

	-- It's possible that the character could have already been loaded before this code is ever loaded so we must do this.
	if player:HasAppearanceLoaded() then characterApperanceLoaded(player.Character) end
	player.CharacterAppearanceLoaded:Connect(characterApperanceLoaded)
end


--
return playerManager