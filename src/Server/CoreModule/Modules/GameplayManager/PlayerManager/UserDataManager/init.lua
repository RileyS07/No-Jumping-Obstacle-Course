-- Variables
local userDataManager = {}
userDataManager.Remotes = {}
userDataManager.UserData = {}
userDataManager.IsLoadingData = {}
userDataManager.IsUsingTemporaryData = {}
userDataManager.UserDataLoaded = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local dataStoreLibrary = require(coreModule.GetObject("Libraries.DataStoreLibrary"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))
local tableUtilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.TableUtilities"))

-- Initialize
function userDataManager.Initialize()
	coreModule.Shared.GetObject("//Remotes.Data.GetUserData").OnServerInvoke = function(player, optionalOtherPlayer)
		return userDataManager.GetData(optionalOtherPlayer or player)
	end
	
	-- Use this to inform the client their data might not be saved
	dataStoreLibrary.OutageStatusUpdated.Event:Connect(function(newOutageStatus)
		userDataManager.Remotes.OutageStatusUpdated = userDataManager.Remotes.OutageStatusUpdated or coreModule.Shared.GetObject("//Remotes.Data.OutageStatusUpdated")
		userDataManager.Remotes.OutageStatusUpdated:FireAllClients(newOutageStatus)
	end)

	-- Auto save and server shutdown saving
	game:BindToClose(userDataManager.SaveDataOfMultiplePlayers)
	coroutine.wrap(function()
		while true do
			wait(script:GetAttribute("AutoSaveDelay"))
			userDataManager.SaveDataOfMultiplePlayers()
		end
	end)()
end

-- Methods
function userDataManager.LoadData(player)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if userDataManager.UserData[player] then return userDataManager.UserData[player] end
	if userDataManager.IsLoadingData[player] then return userDataManager.GetData(player) end
	userDataManager.IsLoadingData[player] = true
	
	-- Attempt GetAsync
	local wasSuccessful, returnedUserData = dataStoreLibrary.GetAsync({
		DataStoreName = script:GetAttribute("DataStoreName"),
		DataStoreScope = script:GetAttribute("DataStoreScope"),
		DataStoreKey = player.UserId,
		DefaultData = require(script.DefaultData)
	})
	
	-- Now what are we going to do with those results
	if wasSuccessful then
		tableUtilitiesLibrary.SynchronizeTables(returnedUserData, require(script.DefaultData))
		userDataManager.UserData[player] = returnedUserData
		userDataManager.UserDataLoaded:Fire(player, userDataManager.UserData[player])
	else
		userDataManager.IsUsingTemporaryData[player] = true
		userDataManager.UserData[player] = tableUtilitiesLibrary.CloneTable(require(script.DefaultData))
		
		-- Passive retrying
		coroutine.wrap(function()
			while true do
				wait(script:GetAttribute("RetryDelay"))
				
				-- Attempt GetAsync
				local wasSuccessful, returnedUserData = dataStoreLibrary.GetAsync({
					DataStoreName = script:GetAttribute("DataStoreName"),
					DataStoreScope = script:GetAttribute("DataStoreScope"),
					DataStoreKey = script:GetAttribute("DataStoreKey"),
					DefaultData = require(script.DefaultData)
				})
				
				-- Now what are we going to do with those results		(seem familiar)
				if wasSuccessful then
					tableUtilitiesLibrary.SynchronizeTables(returnedUserData, require(script.DefaultData))
					userDataManager.UserData[player] = returnedUserData
					userDataManager.IsUsingTemporaryData[player] = nil
					userDataManager.UserDataLoaded:Fire(player, userDataManager.UserData[player])
				end
			end
		end)()
	end
	
	-- Finish up
	userDataManager.IsLoadingData[player] = nil
	return userDataManager.UserData[player]
end

function userDataManager.SaveData(player, isLeavingAfterwards)
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if userDataManager.IsUsingTemporaryData[player] then return end
	if userDataManager.GetData(player) == nil then return end
	
	-- Attempt SetAsync
	local wasSuccessful = dataStoreLibrary.SetAsync({
		DataStoreName = script:GetAttribute("DataStoreName"),
		DataStoreScope = script:GetAttribute("DataStoreScope"),
		DataStoreKey = player.UserId,
		Data = userDataManager.GetData(player)
	})
	
	-- Now what are we going to do with those results
	if not wasSuccessful then
		coroutine.wrap(function()
			while true do
				wait(script:GetAttribute("RetryDelay"))
				
				-- Attempt SetAsync
				local wasSuccessful = dataStoreLibrary.SetAsync({
					DataStoreName = script:GetAttribute("DataStoreName"),
					DataStoreScope = script:GetAttribute("DataStoreScope"),
					DataStoreKey = player.UserId,
					Data = userDataManager.GetData(player)
				})
				
				-- Now what are we going to do with those results
				if wasSuccessful then
					-- Are they leaving afterwards?
					if isLeavingAfterwards then
						userDataManager.UserData[player] = nil
						userDataManager.IsLoadingData[player] = nil
						userDataManager.IsUsingTemporaryData[player] = nil
					end
					
					-- Let's get out of here!
					break
				end
			end
		end)()
	end
	
	-- Are they leaving afterwards?
	if wasSuccessful and isLeavingAfterwards then
		userDataManager.UserData[player] = nil
		userDataManager.IsLoadingData[player] = nil
		userDataManager.IsUsingTemporaryData[player] = nil
	end
end

function userDataManager.SaveDataOfMultiplePlayers(playerArray, isLeavingAfterwards)
	for _, player in next, (playerArray or coreModule.Services.Players:GetPlayers()) do
		userDataManager.SaveData(player, isLeavingAfterwards)
	end
end

function userDataManager.GetData(player)
	if not userDataManager.UserData[player] then
		if userDataManager.IsLoadingData[player] then 
			repeat wait() until not userDataManager.IsLoadingData[player]
		else
			userDataManager.LoadData(player)
		end
	end

	--
	return userDataManager.UserData[player]
end

--
return userDataManager