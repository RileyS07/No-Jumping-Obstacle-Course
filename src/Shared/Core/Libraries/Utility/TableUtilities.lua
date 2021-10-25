-- Variables
local tableUtilities = {}

-- Public Methods

--[[
	local originalTable: {} = {1, 2, {x = 10}}
	local copiedTable: {} = tableUtilities.Copy(originalTable)
	print(originalTable[3] == copiedTable[3]) --> false
]]
-- Performs a deep copy of the given table.
-- In other words, all nested tables will also get copied.
-- Returns the copied table.
function tableUtilities.Copy(originalTable: {}) : {}
	assert(typeof(originalTable) == "table", "Argument #1 expected table. Got " .. typeof(originalTable))

	local copiedTable = table.create(#originalTable)

	for key, value in next, originalTable do
		if typeof(value) == "table" then
			copiedTable[key] = tableUtilities.Copy(value)
		else
			copiedTable[key] = value
		end
	end

	return copiedTable
end

--[[
	local originalTable: {} = {1, 2, {x = 10}}
	local copiedTable: {} = tableUtilities.ShallowCopy(originalTable)
	print(originalTable[3] == copiedTable[3]) --> true
]]
-- Performs a shallow copy of the given table.
-- In other words, all nested tables will not be copied, but only moved by reference.
-- Thus, a nested table in both the original and the copy will be the same.
-- Returns the copied table.
function tableUtilities.ShallowCopy(originalTable: {}) : {}
	assert(typeof(originalTable) == "table", "Argument #1 expected table. Got " .. typeof(originalTable))

	local copiedTable = table.create(#originalTable)

	for key, value in next, originalTable do
		copiedTable[key] = value
	end

	return copiedTable
end

--[[
	local defaultData: {} = {Kills = 0, Deaths = 0, Money = 100}
	local outdatedData: {} = {Kills = 7, LegacyValue = 37}
	local updatedData: {} = tableUtilities.Synchronize(outdatedData, defaultData)
	print(updatedData.Kills, updatedData.LegacyValue, updatedData.Money) --> 7, 37, 100
]]
-- Synchronizes a table to a parent table.
-- If the table does not have an entry that exists in the parent table, it gets added.
-- Returns the synchronized table.
function tableUtilities.Synchronize(childTable: {}, parentTable: {}) : {}
	assert(typeof(childTable) == "table", "Argument #1 expected table. Got " .. typeof(childTable))
	assert(typeof(parentTable) == "table", "Argument #2 expected table. Got " .. typeof(parentTable))

	-- Essentially this function does a deep copy but in a friendly way.
	for key, value in next, parentTable do
		if typeof(value) == "table" then
			assert(typeof(childTable[key]) == "nil" or typeof(childTable[key]) == "table", "Key collision encountered, cannot sync tables. Key = " .. tostring(key))

			childTable[key] = childTable[key] or {}
			tableUtilities.Synchronize(childTable[key], value)
		elseif value ~= nil and childTable[key] == nil then
			childTable[key] = value
		end
	end

	return childTable
end

--[[
	local itemColorData = {
		PrimaryColor = Color3.fromRGB(255, 255, 0),
		SecondaryColor = Color3.fromRGB(0, 255, 0)
	}

	local serializedColorData = tableUtilities.Map(itemColorData, function(key: string, value: Color3)
		return string.format("%03d%03d%03d", value.R, value.G, value.B)
	end)
]]
-- Used to map data into a different format.
-- Returns the mapped data.
function tableUtilities.Map(originalTable: {}, mappingFunction: (any, any) -> ({})) : {}
	assert(typeof(originalTable) == "table", "Argument #1 expected table. Got " .. typeof(originalTable))
	assert(typeof(mappingFunction) == "function", "Argument #2 expected function. Got " .. typeof(mappingFunction))

	local newTable = table.create(#originalTable)

	for key, value in next, originalTable do
		newTable[key] = mappingFunction(key, value)
	end

	return newTable
end

--[[
	local accountsOverAYearOld = tableUtilities.Filter(game:GetService("Players"):GetPlayers(), function(key: number, value: Player)
		return value.AccountAge > 365
	end)
]]
-- Creates a new filtered table based on what filterFunction returns.
-- If true it carries over to the new array, if false it doesn't.
-- Returns the filtered table.
function tableUtilities.Filter(originalTable: {}, filterFunction: (any, any) -> boolean) : {}
	assert(typeof(originalTable) == "table", "Argument #1 expected table. Got " .. typeof(originalTable))
	assert(typeof(filterFunction) == "function", "Argument #2 expected function. Got " .. typeof(filterFunction))

	local newTable = table.create(#originalTable)

	for key, value in next, originalTable do
		if filterFunction(key, value) then
			if typeof(key) == "string" then
				newTable[key] = value
			else
				table.insert(newTable, value)
			end
		end
	end

	return newTable
end

--[[
	local randomNumbers = {1, 10, 101, 1010, 2}
	local randomNumbersSum = tableUtilities.Reduce(randomNumbers, function(currentValue: number, key: string, value: number)
		return currentValue + value
	end)

	print(randomNumbersSum) --> 1124
]]
-- Used to reduce a table down to a single value.
-- Common use case is for quickly summing up a table.
-- Returns the reduced value.
function tableUtilities.Reduce(thisTable: {}, reducingFunction: (any, any, any) -> any, intialValue: any?) : any
	assert(typeof(thisTable) == "table", "Argument #1 expected table. Got " .. typeof(thisTable))
	assert(typeof(reducingFunction) == "function", "Argument #2 expected function. Got " .. typeof(reducingFunction))

	local finalValue = intialValue or 0

	for key, value in next, thisTable do
		finalValue = reducingFunction(finalValue, key, value)
	end

	return finalValue
end

-- Returns whether or not the table is empty.
function tableUtilities.IsEmpty(thisTable: {}) : boolean
	assert(typeof(thisTable) == "table", "Argument #1 expected table. Got " .. typeof(thisTable))

	return next(thisTable) == nil
end

--
return tableUtilities