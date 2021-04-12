-- Variables
local tableUtilitiesLibrary = {}

-- Methods
function tableUtilitiesLibrary.CloneTable(baseTable)
	return tableUtilitiesLibrary.SynchronizeTables({}, baseTable)
end

-- This will create keys if they do not exist and give them the values from the baseTable
function tableUtilitiesLibrary.SynchronizeTables(childTable, baseTable)
	for key, value in next, baseTable do
		if typeof(value) == "table" then
			childTable[key] = childTable[key] or {}
			tableUtilitiesLibrary.SynchronizeTables(childTable[key], baseTable[key])
		elseif value ~= nil and childTable[key] == nil then
			childTable[key] = baseTable[key]
		end
	end
	
	-- Now that it's been all sync'd up we can return the same table
	return childTable
end

-- This method will help get rid of mixed arrays
function tableUtilitiesLibrary.EnforceKeyTyping(baseTable, enforceNumericKeysOnly)
	for key, value in next, baseTable do
		if (enforceNumericKeysOnly and typeof(key) ~= "number") or (not enforceNumericKeysOnly and typeof(key) == "number") then
			baseTable[key] = nil
		end
		
		if typeof(value) == "table" then
			tableUtilitiesLibrary.EnforceKeyTyping(baseTable[key], enforceNumericKeysOnly)
		end
	end
	
	-- 
	return baseTable
end

--
return tableUtilitiesLibrary