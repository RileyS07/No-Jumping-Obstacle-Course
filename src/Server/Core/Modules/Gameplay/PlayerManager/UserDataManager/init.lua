local coreModule = require(script:FindFirstAncestor("Core"))
local profileService = require(coreModule.GetObject("Libraries.ProfileService"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))

local UserDataManager = {}
UserDataManager.StoredProfiles = {}
UserDataManager.ProfilesBeingLoaded = {}
UserDataManager.ProfileServiceDataStore = nil
UserDataManager.UserDataLoaded = signal.new()

-- Initialize
function UserDataManager.Initialize()
	UserDataManager.ProfileServiceDataStore = profileService.GetProfileStore(
		"UserData/Global", require(script.DefaultData)
	)

	-- The client wants to view their data or someone elses.
	coreModule.Shared.GetObject("//Remotes.Data.GetUserData").OnServerInvoke = function(player: Player, optionalOtherPlayer: Player?)
		return UserDataManager.GetData(optionalOtherPlayer or player)
	end
end

-- Attempts to load a user's data. Returning whether or not it was successful.
function UserDataManager.LoadData(player: Player) : boolean
	if not playerUtilities.IsPlayerValid(player) then return false end
	if not UserDataManager.ProfileServiceDataStore then return false end
	if UserDataManager.StoredProfiles[player] then return false end

	-- Attempt to LoadProfileAsync with ForceLoad.
	UserDataManager.ProfilesBeingLoaded[player] = true
	local loadedProfileData = UserDataManager.ProfileServiceDataStore:LoadProfileAsync(tostring(player.UserId), "ForceLoad")

	-- The profile was successfully loaded.
	if loadedProfileData ~= nil then

		-- Setup; Reconcile syncs current data with the current default template; ListenToRelease is a callback for when this session lock is released.
		loadedProfileData:Reconcile()
		loadedProfileData:ListenToRelease(function()
			UserDataManager.StoredProfiles[player] = nil
			UserDataManager.ProfilesBeingLoaded[player] = nil
			player:Kick()
		end)

		-- The player is still in the game after all of our setup, so we can continue.
		if playerUtilities.IsPlayerValid(player) then
			UserDataManager.StoredProfiles[player] = loadedProfileData
			UserDataManager.UserDataLoaded:Fire(player, loadedProfileData.Data)

		-- The player left so we need to end this session.
		else
			loadedProfileData:Release()
		end

	-- Something went wrong and the profile could not be loaded.
	else
		player:Kick()
		return false
	end

	-- Cleanup.
	UserDataManager.ProfilesBeingLoaded[player] = nil
	return true
end

-- Attempts to save a user's data. Returns whether or not it was successful.
function UserDataManager.SaveData(player: Player) : boolean
	if not playerUtilities.IsPlayerValid(player) then return false end
	if not UserDataManager.StoredProfiles[player] then return false end

	-- Release the current session.
	UserDataManager.StoredProfiles[player]:Release()
	return true
end

-- Attempts to save data from multiple players. Returns whether or not all were successful.
function UserDataManager.SaveDataFromMultiplePlayers(playersArray: {Player}) : boolean

	local wereAllSuccessful: boolean = true

	for _, player: Player in next, playersArray do
		wereAllSuccessful = wereAllSuccessful and UserDataManager.SaveData(player)
	end

	return wereAllSuccessful
end

-- Attempts to get the data of this user.
-- If the data has not been loaded it tries to load it.
function UserDataManager.GetData(player: Player) : {}
	if not playerUtilities.IsPlayerValid(player) then
		return require(script.DefaultData)
	end

	-- Their profile has not been loaded yet.
	if not UserDataManager.StoredProfiles[player] then

		-- LoadData has already been called so we just need to task.wait.
		if UserDataManager.ProfilesBeingLoaded[player] then
			repeat
				task.wait()
			until not UserDataManager.ProfilesBeingLoaded[player]

		-- LoadData has not been called so we need to.
		else
			UserDataManager.LoadData(player)
		end
	end

	return UserDataManager.StoredProfiles[player].Data
end

return UserDataManager
