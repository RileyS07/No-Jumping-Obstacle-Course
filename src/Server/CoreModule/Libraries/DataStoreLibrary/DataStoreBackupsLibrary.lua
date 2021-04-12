-- Variables
local dataStoreBackupsLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local orderedDataStoreLibrary = require(coreModule.GetObject("/Parent.OrderedDataStoreLibrary"))

-- Methods
function dataStoreBackupsLibrary.GetBackupInformation(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		BackupOffset = 0,
	}})
	
	-- Attempt to get the ordered list of backup times
	local wasSuccessful, orderedBackupTimesList = orderedDataStoreLibrary.GetSortedAsync({
		DataStoreName = functionParameters.DataStoreName,
		DataStoreScope = functionParameters.DataStoreScope,
		PageSize = 1 + functionParameters.BackupOffset
	})
	
	if not wasSuccessful then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	elseif not orderedBackupTimesList then	-- This means it's their first time playing the game
		return true, functionParameters.DataStoreKey..":Initial"
	end
	
	-- Attempt to get the backup in question albeit a little forcefully
	local wasSuccessful, lastBackupInformation = pcall(function() return orderedBackupTimesList:GetCurrentPage()[1 + functionParameters.BackupOffset] end)
	if not wasSuccessful then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	elseif not lastBackupInformation then	-- The backup in question does not exist so we default to the oldest backup
		return true, functionParameters.DataStoreKey..":Initial"
	else
		return true, functionParameters.DataStoreKey..":"..lastBackupInformation.value, lastBackupInformation.value
	end
end

function dataStoreBackupsLibrary.GenerateNewBackupInformation(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		BackupOffset = functionParameters.BackupOffset
	}})
	
	-- Attempt to get the ordered list of backup times
	local wasSuccessful, orderedBackupTimesList = orderedDataStoreLibrary.GetSortedAsync({
		DataStoreName = functionParameters.DataStoreName,
		DataStoreScope = functionParameters.DataStoreScope,
		PageSize = 1 + functionParameters.BackupOffset
	})
	
	if not wasSuccessful then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	elseif not orderedBackupTimesList then
		return true, 1
	end
	
	-- Attempt to get the backup in question albeit a little forcefully
	local wasSuccessful, lastBackupInformation = pcall(function() return orderedBackupTimesList:GetCurrentPage()[1 + functionParameters.BackupOffset] end)
	if not wasSuccessful then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	elseif not lastBackupInformation then
		return true, 1
	else
		return true, (tonumber(lastBackupInformation.value) or 0) + 1
	end
end

--
return dataStoreBackupsLibrary