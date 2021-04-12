-- Variables
local orderedDataStoreLibrary = {}
local coreModule = require(script:FindFirstAncestor("CoreModule"))
local throttlePreventionLibrary = require(coreModule.GetObject("/Parent.ThrottlePreventionLibrary"))

-- Methods
function orderedDataStoreLibrary.GetSortedAsync(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		
		-- OrderedDataStore specifics
		IsAscending = false,
		PageSize = 10
	}})
	
	-- This is useful if you want to overwrite your data in studio easily
	if not script.Parent:GetAttribute("StudioLoadingEnabled") and coreModule.Services.RunService:IsStudio() then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	end
	
	-- Keeping it consistent with the other datastore libraries
	local dataStoreObject = coreModule.Services.DataStoreService:GetOrderedDataStore(functionParameters.DataStoreName, functionParameters.DataStoreScope)
	throttlePreventionLibrary.WaitForRequestBudget(Enum.DataStoreRequestType.GetSortedAsync)
	return pcall(dataStoreObject.GetSortedAsync, dataStoreObject, functionParameters.IsAscending, functionParameters.PageSize)
end

function orderedDataStoreLibrary.SetAsync(functionParameters)
	functionParameters = setmetatable(functionParameters or {}, {__index = {
		DataStoreName = "Name",
		DataStoreScope = "global",
		DataStoreKey = "Key",
		Data = 0
	}})
	
	-- This is useful if you don't want to give yourself a headache while testing your game out
	if not script.Parent:GetAttribute("StudioSavingEnabled") and coreModule.Services.RunService:IsStudio() then
		require(coreModule.GetObject("/Parent")).UpdateOutageStatus(true)	-- Welcome to the world of circular reasoning
		return false
	end
	
	-- Keeping it consistent with the other datastore libraries
	local dataStoreObject = coreModule.Services.DataStoreService:GetOrderedDataStore(functionParameters.DataStoreName, functionParameters.DataStoreScope)
	throttlePreventionLibrary.WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync, dataStoreObject, functionParameters.DataStoreKey)
	throttlePreventionLibrary.AddToSameKeySetExceptionList(dataStoreObject, functionParameters.DataStoreKey)
	return pcall(dataStoreObject.SetAsync, dataStoreObject, functionParameters.DataStoreKey, functionParameters.Data)
end

--
return orderedDataStoreLibrary