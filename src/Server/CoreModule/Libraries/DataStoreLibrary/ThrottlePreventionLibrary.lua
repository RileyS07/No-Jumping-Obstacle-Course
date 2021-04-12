-- Variables
local throttlePreventionLibrary = {}
throttlePreventionLibrary.SameKeySetExceptionList = {}	-- 6 second delay between set attempts to the same key
throttlePreventionLibrary.SameKeySetExceptionRequestList = {
	[Enum.DataStoreRequestType.SetIncrementAsync] = true,
	[Enum.DataStoreRequestType.SetIncrementSortedAsync] = true,
	[Enum.DataStoreRequestType.UpdateAsync] = true
}

local coreModule = require(script:FindFirstAncestor("CoreModule"))

-- Methods
function throttlePreventionLibrary.WaitForRequestBudget(requestType, dataStoreObject, dataStoreKey)
	if throttlePreventionLibrary.SameKeySetExceptionRequestList[requestType] then
		if throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject] and throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject][dataStoreKey] then
			-- We're gonna yield until the coroutine responsible for this cache is finished and removes it allowing us to safely make another call
			repeat wait(1) until not throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject] or not throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject][dataStoreKey]
		end
		
		-- This is where we're actually checking datastore budgets themselves
		if throttlePreventionLibrary.IsRequestBudgetEmpty(requestType) then
			repeat wait(1) until not throttlePreventionLibrary.IsRequestBudgetEmpty(requestType)
		end
	end
end

function throttlePreventionLibrary.AddToSameKeySetExceptionList(dataStoreObject, dataStoreKey)
	throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject] = throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject] or {}
	throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject][dataStoreKey] = true
	
	-- This is the coroutine responsible for removing the same key set exception after the grace period has passed
	coroutine.wrap(function()
		wait(6)
		
		--
		throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject][dataStoreKey] = nil
		if not next(throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject]) then throttlePreventionLibrary.SameKeySetExceptionList[dataStoreObject] = nil end
	end)()
end

function throttlePreventionLibrary.IsRequestBudgetEmpty(requestType)
	return coreModule.Services.DataStoreService:GetRequestBudgetForRequestType(requestType) <= 0
end

--
return throttlePreventionLibrary