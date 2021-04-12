-- Variables
local dataStoreLibrary = {}
dataStoreLibrary.CurrentOutageStatus = false
dataStoreLibrary.OutageStatusUpdated = Instance.new("BindableEvent")

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local orderedDataStoreLibrary = require(coreModule.GetObject("/OrderedDataStoreLibrary"))
local dataStoreBackupsLibrary = require(coreModule.GetObject("/DataStoreBackupsLibrary"))
local throttlePreventionLibrary = require(coreModule.GetObject("/ThrottlePreventionLibrary"))
local tableUtilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.TableUtilities"))

-- Methods
function dataStoreLibrary.GetAsync(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		DefaultData = {},
		
		-- Optional
		BackupOffset = 0,
		
	}})
	
	-- This is useful if you want to overwrite your data in studio easily
	if not script:GetAttribute("StudioLoadingEnabled") and coreModule.Services.RunService:IsStudio() then
		dataStoreLibrary.UpdateOutageStatus(true)
		return false, tableUtilitiesLibrary.CloneTable(functionParameters.DefaultData)
	end
	
	-- Attempt to enforce datastore place based uniqueness, this allows you to have different data in places under the same game without worrying about data being overwritten
	if script:GetAttribute("EnforceDatastorePlaceUniqueness") then
		functionParameters.DataStoreName = (functionParameters.DataStoreName.."/"..game.PlaceId):sub(1, 50)
	end
	
	-- Attempt to pull up their latest backup
	if script:GetAttribute("BackupsEnabled") then
		local wasSuccessful, specifiedBackupKey = dataStoreBackupsLibrary.GetBackupInformation({
			DataStoreName = (functionParameters.DataStoreName:sub(1, 50 - tostring(functionParameters.DataStoreKey):len() - 1).."/"..functionParameters.DataStoreKey),
			DataStoreScope = functionParameters.DataStoreScope,
			BackupOffset = functionParameters.BackupOffset,
			DataStoreKey = functionParameters.DataStoreKey
		})
		
		-- Update the key
		
		dataStoreLibrary.UpdateOutageStatus(not wasSuccessful)
		if wasSuccessful then
			functionParameters.DataStoreKey = specifiedBackupKey
		else
			return false, tableUtilitiesLibrary.CloneTable(functionParameters.DefaultData) 
		end
	end
	
	-- Attempt GetAsync
	throttlePreventionLibrary.WaitForRequestBudget(Enum.DataStoreRequestType.GetAsync)
	local dataStoreObject = coreModule.Services.DataStoreService:GetDataStore(functionParameters.DataStoreName, functionParameters.DataStoreScope)
	local wasSuccessful, returnedData = pcall(dataStoreObject.GetAsync, dataStoreObject, functionParameters.DataStoreKey)
	dataStoreLibrary.UpdateOutageStatus(not wasSuccessful)
	
	-- Debugging
	coreModule.Debug(
		script:GetAttribute("DebugFormat_GetAsync")
		:gsub("${dataStoreName}", functionParameters.DataStoreName)
		:gsub("${dataStoreScope}", functionParameters.DataStoreScope)
		:gsub("${dataStoreKey}", functionParameters.DataStoreKey)
		:gsub("${data}", (wasSuccessful and typeof(returnedData) == "table") and coreModule.Services.HttpService:JSONEncode(returnedData) or tostring(returnedData)),
		coreModule.Enums.DebugLevel.Data
	)
	
	--
	return wasSuccessful, wasSuccessful and returnedData or tableUtilitiesLibrary.CloneTable(functionParameters.DefaultData) 
end

function dataStoreLibrary.SetAsync(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		Data = {},
		
		-- Optional
		BackupOffset = 0,

	}})
	
	-- This is useful if you don't want to give yourself a headache while testing your game out
	if not script:GetAttribute("StudioSavingEnabled") and coreModule.Services.RunService:IsStudio() then
		dataStoreLibrary.UpdateOutageStatus(true)
		return false
	end
	
	-- Attempt to enforce datastore place based uniqueness, this allows you to have different data in places under the same game without worrying about data being overwritten
	if script:GetAttribute("EnforceDatastorePlaceUniqueness") then
		functionParameters.DataStoreName = (functionParameters.DataStoreName.."/"..game.PlaceId):sub(1, 50)
	end
	
	-- Attempt to create new backup information
	local newBackupInformationIndexToBeSaved = 0
	local originalDataStoreName = functionParameters.DataStoreName
	if script:GetAttribute("BackupsEnabled") then
		local wasSuccessful, newBackupInformationIndex = dataStoreBackupsLibrary.GenerateNewBackupInformation({
			DataStoreName = (functionParameters.DataStoreName:sub(1, 50 - tostring(functionParameters.DataStoreKey):len() - 1).."/"..functionParameters.DataStoreKey),
			DataStoreScope = functionParameters.DataStoreScope,
			BackupOffset = functionParameters.BackupOffset,
			DataStoreKey = functionParameters.DataStoreKey
		})
		
		-- Update the key
		dataStoreLibrary.UpdateOutageStatus(not wasSuccessful)
		if wasSuccessful then
			newBackupInformationIndexToBeSaved = newBackupInformationIndex
			originalDataStoreName = (functionParameters.DataStoreName:sub(1, 50 - tostring(functionParameters.DataStoreKey):len() - 1).."/"..functionParameters.DataStoreKey)
			functionParameters.DataStoreKey = functionParameters.DataStoreKey..":"..newBackupInformationIndex
		else
			return false
		end
	end
	
	-- Attempt SetAsync
	local dataStoreObject = coreModule.Services.DataStoreService:GetDataStore(functionParameters.DataStoreName, functionParameters.DataStoreScope)
	throttlePreventionLibrary.WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync, dataStoreObject, functionParameters.DataStoreKey)
	throttlePreventionLibrary.AddToSameKeySetExceptionList(dataStoreObject, functionParameters.DataStoreKey)
	
	local wasSuccessful, returnedError = pcall(dataStoreObject.SetAsync, dataStoreObject, functionParameters.DataStoreKey, functionParameters.Data)
	dataStoreLibrary.UpdateOutageStatus(not wasSuccessful)
	if not wasSuccessful then return end
	
	-- Debugging
	coreModule.Debug(
		script:GetAttribute("DebugFormat_SetAsync")
		:gsub("${dataStoreName}", functionParameters.DataStoreName)
		:gsub("${dataStoreScope}", functionParameters.DataStoreScope)
		:gsub("${dataStoreKey}", functionParameters.DataStoreKey)
		:gsub("${data}", (wasSuccessful and typeof(functionParameters.Data) == "table") and coreModule.Services.HttpService:JSONEncode(functionParameters.Data) or tostring(functionParameters.Data)),
		coreModule.Enums.DebugLevel.Data
	)
	
	-- Attempt to save the backup to the ordered datastore
	if script:GetAttribute("BackupsEnabled") then
		local wasSuccessful = orderedDataStoreLibrary.SetAsync({
			DataStoreName = originalDataStoreName,
			DataStoreScope = functionParameters.DataStoreScope,
			DataStoreKey = functionParameters.DataStoreKey,
			Data = newBackupInformationIndexToBeSaved
		})
		
		--
		dataStoreLibrary.UpdateOutageStatus(not wasSuccessful)
		return wasSuccessful
	end
	
	--
	return true
end

function dataStoreLibrary.UpdateOutageStatus(isAnOutageActive)
	if dataStoreLibrary.CurrentOutageStatus == isAnOutageActive and not dataStoreLibrary.CurrentOutageStatu then return end
	dataStoreLibrary.CurrentOutageStatus = isAnOutageActive
	dataStoreLibrary.OutageStatusUpdated:Fire(dataStoreLibrary.CurrentOutageStatus)
end

--
return dataStoreLibrary