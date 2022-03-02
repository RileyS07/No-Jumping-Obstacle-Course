local collectionService: CollectionService = game:GetService("CollectionService")
local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))

local thisPlatformContainer: Instance? = workspace.Map.Gameplay.PlatformerMechanics:FindFirstChild("RespawnPlatforms")

local ThisMechanicManager = {}
ThisMechanicManager.PlayerDeathInformation = {}

-- Initialize
function ThisMechanicManager.Initialize()
	if not thisPlatformContainer then return end

	-- Every descendant that is a BasePart of this collection will respawn them.
	for _, thisPlatform: Instance in next, (thisPlatformContainer :: Instance):GetDescendants() do

		if thisPlatform:IsA("BasePart") then
			thisPlatform.Touched:Connect(function(hit: BasePart)

				local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
				if not playerUtilities.IsPlayerAlive(player) then return end
				if collectionService:HasTag(player.Character, "Forcefield") then return end
				if teleportationManager.GetIsPlayerBeingTeleported(player) then return end

				-- We can safely assume this is only called once then.
				-- Let's register this respawn.
				ThisMechanicManager.RegisterRespawnOf(player)

				-- Respawns them.
				teleportationManager.TeleportPlayer(player)
			end)
		end
	end
end

-- Returns the player death information of this user.
function ThisMechanicManager.GetPlayerDeathInformationOf(player: Player) : {}
	ThisMechanicManager.PlayerDeathInformation[player] = ThisMechanicManager.PlayerDeathInformation[player] or {
		CurrentCheckpoint = 1,
		RespawnCount = 0,
		TimesShownPopup = 0,
	}

	return ThisMechanicManager.PlayerDeathInformation[player]
end

-- Sets the death information of this player to the given death information.
function ThisMechanicManager.SetPlayerDeathInformationOf(player: Player, deathInformation: {}?)
	ThisMechanicManager.PlayerDeathInformation[player] = deathInformation
end

-- Registers the respawn and updates the players death information.
function ThisMechanicManager.RegisterRespawnOf(player: Player)

	local playerDeathInformation: {} = ThisMechanicManager.GetPlayerDeathInformationOf(player)
	local userData: {} = userDataManager.GetData(player)

	-- Let's update their death information.
	if playerDeathInformation.CurrentCheckpoint == userData.UserInformation.CurrentCheckpoint then

		-- We don't want to update it if they're dying at a bonus stage.
		if userData.UserInformation.CurrentBonusStage == "" then
			playerDeathInformation.RespawnCount += 1
		end
	else
		playerDeathInformation.CurrentCheckpoint = userData.UserInformation.CurrentCheckpoint
		playerDeathInformation.RespawnCount = 1
	end

	-- Before we try to show the skip popup lets see if they have turned it off first.
	if userData and userData.Settings.SkipPopupEnabled then

		-- Have they died enough on their current stage to justify this?
		if playerDeathInformation.RespawnCount == (playerDeathInformation.TimesShownPopup + 1) * sharedConstants.GENERAL.RESPAWN_COUNT_NEEDED_TO_SHOW_POPUP then

			playerDeathInformation.TimesShownPopup += 1
			print("Would you like to skip stage " .. tostring(playerDeathInformation.CurrentCheckpoint))
		end
	end
end

return ThisMechanicManager
