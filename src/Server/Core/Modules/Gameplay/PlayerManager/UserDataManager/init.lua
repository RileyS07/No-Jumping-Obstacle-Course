-- Variables
local userDataManager = {}
userDataManager.StoredProfiles = {}
userDataManager.ProfilesBeingLoaded = {}
userDataManager.ProfileServiceDataStore = nil
userDataManager.UserDataLoaded = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("Core"))
local profileService = require(coreModule.GetObject("Libraries.ProfileService"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries._Utilities"))

-- Initialize
function userDataManager.Initialize()
	userDataManager.ProfileServiceDataStore = profileService.GetProfileStore(
		-- DataStoreName; UserData/Global is the default.
		((script:GetAttribute("DataStoreName") or "UserData").."/"..(script:GetAttribute("DataStoreScope") or "Global")):sub(1, 50),
		-- TemplateData.
		require(script.DefaultData)
	)

	-- The client wants to view data.
	coreModule.Shared.GetObject("//Remotes.Data.GetUserData").OnServerInvoke = function(player, optionalOtherPlayer)
		return userDataManager.GetData(optionalOtherPlayer or player)
	end

	-- Loading modules.
	coreModule.LoadModule("/Settings")
end


-- Methods
function userDataManager.LoadData(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not userDataManager.ProfileServiceDataStore then return end
	if userDataManager.StoredProfiles[player] then return end

	-- Attempt to LoadProfileAsync with ForceLoad.
	userDataManager.ProfilesBeingLoaded[player] = true
	local loadedProfileData = userDataManager.ProfileServiceDataStore:LoadProfileAsync(tostring(player.UserId), "ForceLoad")
	
	-- The profile was successfully loaded.
	if loadedProfileData ~= nil then

		-- Setup; Reconcile syncs current data with the current default template; ListenToRelease is a callback for when this session lock is released.
		loadedProfileData:Reconcile()
		loadedProfileData:ListenToRelease(function()
			userDataManager.StoredProfiles[player] = nil
			userDataManager.ProfilesBeingLoaded[player] = nil
			player:Kick()
		end)

		-- The player is still in the game after all of our setup, so we can continue.
		if utilitiesLibrary.IsPlayerValid(player) then
			userDataManager.StoredProfiles[player] = loadedProfileData
			userDataManager.UserDataLoaded:Fire(player, loadedProfileData.Data)

		-- The player left so we need to end this session.
		else
			loadedProfileData:Release()
		end

	-- Something went wrong and the profile could not be loaded.
	else
		player:Kick()
	end

	-- Cleanup.
	userDataManager.ProfilesBeingLoaded[player] = nil
end


function userDataManager.SaveData(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not userDataManager.StoredProfiles[player] then return end

	-- Release the current session.
	userDataManager.StoredProfiles[player]:Release()
end


function userDataManager.SaveDataFromMultiplePlayers(playersArray)
	for _, player in next, playersArray do
		userDataManager.SaveData(player)
	end
end


function userDataManager.GetData(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	
	-- Their profile has not been loaded yet.
	if not userDataManager.StoredProfiles[player] then

		-- LoadData has already been called so we just need to task.wait.
		if userDataManager.ProfilesBeingLoaded[player] then
			repeat
				task.wait()
			until not userDataManager.ProfilesBeingLoaded[player]

		-- LoadData has not been called so we need to.
		else
			userDataManager.LoadData(player)
		end
	end

	return userDataManager.StoredProfiles[player].Data
end


--
return userDataManager