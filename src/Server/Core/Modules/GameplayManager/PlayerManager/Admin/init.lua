-- Variables
local adminManager = {}
adminManager.SavedRanksAssignedToPlayers = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local config = require(script.Config)

-- Initialize
function adminManager.Initialize(player)
	if not script:FindFirstChild("Commands") then return end
	
	-- Precomputation; This however does mean case-sensitive commands cannot exist.
	for _, commandModule in next, script.Commands:GetChildren() do
		commandModule.Name = commandModule.Name:lower()	
	end
	
	-- Chatted; Handling all of the core logic.
	player.Chatted:Connect(function(rawString)
		if not rawString:find(config.Keybinds.CommandPrefix) or not rawString:find(config.Keybinds.PublicCommandPrefix) then return end
		
		-- Getting the command information from the raw string.
		local commandInformationFromRawString = adminManager.GetCommandInformationFromRawString(rawString)
		for index, commandInformation in next, commandInformationFromRawString do

			-- This a surface level look into command execution for the player; The commands themselves will do deeper checks.
			if adminManager.CanPlayerExecuteCommand(player, commandInformation.Name) then
				require(script.Commands[commandInformation.Name]).RunCommand(player, commandInformation)
			end
		end
	end)
	
	-- Cleanup; clear the cache.
	coreModule.Services.Players.PlayerRemoving:Connect(function(player)
		adminManager.SavedRanksAssignedToPlayers[player] = nil
	end)
end


-- Methods
-- Translates the raw string to a format usable by the rest of the code
function adminManager.GetCommandInformationFromRawString(rawString) 
	if not rawString:find(config.Keybinds.CommandPrefix) or not rawString:find(config.Keybinds.PublicCommandPrefix) then return end
	
	-- We're gonna store the command information in this array as dictionaries.
	local commandInformation = {}
	while rawString:find(config.Keybinds.CommandPrefix) or rawString:find(config.Keybinds.PublicCommandPrefix) do
		-- Just ignores the prefix used.
		rawString = rawString:sub((rawString:find(config.Keybinds.CommandPrefix) or rawString:find(config.Keybinds.PublicCommandPrefix)) + 1)

		--[[
			A little more complex but this turns argumentOne, argumentTwo, argumentThree into argumentOne,argumentTwo,argumentThree.
			This allows a neater way to target players specific with your commands.
			It also assumes you're seperating arguments that are supposed to be separate with a the CommandSplitKey not a comma.
		]]

		rawString = rawString:gsub("%a+%,+%s*", function(match) 
			return match:gsub("%s+", "")
		end)
		
		-- commandName argumentOneA,argumentOneB,argumentOneC argumentTwo -> {commandName, argumentOneA,argumentOneB,argumentOneC, argumentTwo}
		if rawString:match("([%a+%s*%,*]+)") then	-- Hello World,Riley
			local commandArguments = rawString:match("([%a+%s*%,*]+)"):gsub("%s+", " "):split(config.Keybinds.CommandSplitKey)

			-- The first argument is always assumed to be the command name
			if script.Commands:FindFirstChild(commandArguments[1]:lower()) then
				table.insert(commandInformation, {Name = commandArguments[1], Arguments = {unpack(commandArguments, 2)}})
			end
			
			-- Batched commands?
			if rawString:find(config.Keybinds.CommandBatchKey) then
				rawString = rawString:sub((rawString:find(config.Keybinds.CommandBatchKey)))
			end
		else
			break
		end
	end
	
	return commandInformation
end


-- Checks if the player has the ABILITY to execute the command, not if they will actually be able to execute the command based on the arguments
function adminManager.CanPlayerExecuteCommand(player, commandName)
	if not script.Commands:FindFirstChild(commandName) then return false end
	if not script.Commands[commandName]:IsA("ModuleScript") then return false end
	if not require(script.Commands[commandName]).CommandType then return false end

	-- All players can execute commands with the CommandType of 'Public'.
	if require(script.Commands[commandName]).CommandType == "Public" then return true end
	
	if not adminManager.GetPlayerRankInformation(player) then return false end
	if not adminManager.GetPlayerRankInformation(player).Permissions then return false end

	--[[
		Here we have 3 separate clauses for success:
		1) If they have Infinite permissions they can without a doubt run this command.
		2) If they were specifically allowed to run this command then we let them.
		3) If they are allowed to run all commands matching this command's CommandType then they can.
	]]

	if adminManager.GetPlayerRankInformation(player).Permissions == math.huge then return true end
	if adminManager.GetPlayerRankInformation(player).Permissions[commandName] then return true end
	if adminManager.GetPlayerRankInformation(player).Permissions[require(script.Commands[commandName]).CommandType] then return true end
	
	-- All else failed so we assume they can't run it.
	return false
end


-- Searches the rank information to see if the player qualifies for any of them and then stores that result to save on processing power.
function adminManager.GetPlayerRankInformation(player)
	if adminManager.SavedRanksAssignedToPlayers[player] then return config.RankInformation[adminManager.SavedRanksAssignedToPlayers[player]] end
	
	-- Looking to see if we can match the user to any rank.
	for rankName, rankInformation in next, config.RankInformation do
		if rankInformation.Users then
			for _, rankRequirement in next, rankInformation.Users do

				-- UserId:12345678
				if rankRequirement:match("UserId:%d+") and player.UserId == tonumber(rankRequirement:match("UserId:(%d+)")) then
					adminManager.SavedRanksAssignedToPlayers[player] = rankName
					break

				-- Group:12345678
				elseif  (rankRequirement:match("Group:%d+") and not rankRequirement:match("Group:%d+:%d+")) and player:IsInGroup(tonumber(rankRequirement:match("Group:(%d+)"))) then
					adminManager.SavedRanksAssignedToPlayers[player] = rankName
					break

				-- Group:12345678:123
				elseif rankRequirement:match("Group:%d+:%d+") and player:GetRankInGroup(tonumber(rankRequirement:match("Group:(%d+)"))) == tonumber(rankRequirement:match("Group:%d+:(%d+)")) then
					adminManager.SavedRanksAssignedToPlayers[player] = rankName
					break
				end
			end
		end
	end

	return adminManager.SavedRanksAssignedToPlayers[player]
end


-- Translates something like me, all, others, 2he*, ... to a usable array.
function adminManager.GetTargetArrayFromRawString(player, rawString, allowNonPlayerEntries)
	-- This little bit of code is neat because it let's you do just for example, '!kill' instead of '!kill me'.
	if not rawString then return {player} end

	-- I example in more detail in the GetCommandInformationFromRawString method; This turns argumentOne, argumentTwo, argumentThree into argumentOne,argumentTwo,argumentThree.
	rawString = rawString:gsub("%a+%,+%s*", function(match) 
		return match:gsub("%s+", "")
	end)
	
	-- Decoding the rawString into an array of targets that we can use.
	local targetArray = {}
	for targetString in rawString:gmatch("[^%,]+") do
		
		-- You.
		if targetString == "me" then
			table.insert(targetArray, player)

		-- All players.
		elseif targetString == "all" then
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				table.insert(targetArray, nestedPlayer)
			end

		-- Everyone but you.
		elseif targetString == "others" then
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				if nestedPlayer ~= player then
					table.insert(targetArray, nestedPlayer)
				end
			end

		-- Name* (get's all users with a name similar to that).
		elseif targetString:match("%*$") then
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				if nestedPlayer.Name:match("[^%*]+") then
					table.insert(targetArray, nestedPlayer)
				end
			end

		-- Here we assume it's a player's name/userid.
		else
			if tonumber(targetString) then
				if coreModule.Services.Players:GetPlayerByUserId(tonumber(targetString)) then
					table.insert(targetArray, coreModule.Services.Players:GetPlayerByUserId(tonumber(targetString)))
				elseif allowNonPlayerEntries then
					table.insert(targetArray, tonumber(targetString))
				end
			else
				for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
					if nestedPlayer.Name:lower() == targetString then
						table.insert(targetArray, nestedPlayer)
					end
				end
			end
		end
	end
	
	return targetArray
end


--
return adminManager