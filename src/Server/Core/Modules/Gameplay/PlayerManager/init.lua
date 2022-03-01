local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("/UserDataManager"))
local eventsManager = require(coreModule.GetObject("Modules.Gameplay.EventsManager"))
local commonPlayerBadges = require(coreModule.GetObject("Libraries.CommonPlayerBadges"))
local physicsService = require(coreModule.Shared.GetObject("Libraries.Services.PhysicsService"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))

local PlayerManager = {}

-- Initialize
function PlayerManager.Initialize()
	coreModule.LoadModule("/UserDataManager")

	-- This is for PlayerAdded and PlayerRemoving neatness.
	PlayerManager.SetupJoiningConnections()
	PlayerManager.SetupLeavingConnections()

	physicsService.CollisionGroupSetCollidable("Players", "Players", false)
end


-- Sets up the PlayerAdded wrapper.
function PlayerManager.SetupJoiningConnections()

	-- We want to handle anything involving user data first.
	playerUtilities.CreatePlayerAddedWrapper(function(player: Player)

		userDataManager.LoadData(player)
		eventsManager.ValidateAllEventData(player)
		PlayerManager.SetupCharacterConnections(player)

		-- Misc modules.
		commonPlayerBadges.AwardBadges(player)
		coreModule.LoadModule("/Leaderstats", player)
	end)
end

-- Sets up the PlayerRemoving connection.
function PlayerManager.SetupLeavingConnections()

	-- All we have to do is save their data.
	players.PlayerRemoving:Connect(function(player)
		userDataManager.SaveData(player, true)
	end)
end

-- Sets up the CharacterAdded wrapper.
function PlayerManager.SetupCharacterConnections(player: Player)

	-- The character manager will handle all of the specific stuff.
	-- We just want to make sure their collisions are correct.
	playerUtilities.CreateCharacterAddedWrapper(player, function(character: Model)
		physicsService.SetCollectionsCollisionGroup(character:GetDescendants(), "Players")
		coreModule.LoadModule("/CharacterManager", player, character)
	end)
end

return PlayerManager
