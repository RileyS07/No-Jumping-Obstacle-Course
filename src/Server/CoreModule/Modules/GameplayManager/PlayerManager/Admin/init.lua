-- Variables
local adminManager = {}
adminManager.SavedRanksAssignedToPlayers = {}

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local config = require(script.Config)

-- Initialize
function adminManager.Initialize(player)
	if not script:FindFirstChild("Commands") then return end
	
	-- Precomputation
	for _, commandModule in next, script.Commands:GetChildren() do
		commandModule.Name = commandModule.Name:lower()	
	end
	
	-- Chatted
	player.Chatted:Connect(function(rawString)
		if not rawString:find(config.Keybinds.CommandPrefix) or not rawString:find(config.Keybinds.PublicCommandPrefix) then return end
		
		-- Let's get that information
		local commandInformationFromRawString = adminManager.GetCommandInformationFromRawString(rawString)
		for index, commandInformation in next, commandInformationFromRawString do
			if adminManager.CanPlayerExecuteCommand(player, commandInformation.Name) then
				require(script.Commands[commandInformation.Name]).RunCommand(player, commandInformation)
			end
		end
	end)
	
	-- Cleanup
	coreModule.Services.Players.PlayerRemoving:Connect(function(player)
		adminManager.SavedRanksAssignedToPlayers[player] = nil
	end)
end

-- Methods
-- Translates the raw string to a format usable by the rest of the code
function adminManager.GetCommandInformationFromRawString(rawString) 
	if not rawString:find(config.Keybinds.CommandPrefix) or not rawString:find(config.Keybinds.PublicCommandPrefix) then return end
	
	-- We're gonna store the command information in this array as dictionaries
	local commandInformation = {}
	while rawString:find(config.Keybinds.CommandPrefix) or rawString:find(config.Keybinds.PublicCommandPrefix) do
		rawString = rawString:sub((rawString:find(config.Keybinds.CommandPrefix) or rawString:find(config.Keybinds.PublicCommandPrefix)) + 1)
		rawString = rawString:gsub("%a+%,+%s*", function(match) 
			return match:gsub("%s+", "")
		end)
		
		if rawString:match("([%a+%s*%,*]+)") then	-- Hello World,Riley
			local commandArguments = rawString:match("([%a+%s*%,*]+)"):gsub("%s+", " "):split(config.Keybinds.CommandSplitKey)
			if script.Commands:FindFirstChild(commandArguments[1]:lower()) then 	-- The first argument is the command name
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
	
	--
	return commandInformation
end


-- Checks if the player has the ABILITY to execute the command, not if they will actually be able to execute the command based on the arguments
function adminManager.CanPlayerExecuteCommand(player, commandName)
	if not script.Commands:FindFirstChild(commandName) then return false end
	if not script.Commands[commandName]:IsA("ModuleScript") then return false end
	if not require(script.Commands[commandName]).CommandType then return false end
	if require(script.Commands[commandName]).CommandType == "Public" then return true end
	
	if not adminManager.GetPlayerRankInformation(player) then return false end
	if not adminManager.GetPlayerRankInformation(player).Permissions then return false end
	if adminManager.GetPlayerRankInformation(player).Permissions == math.huge then return true end
	if adminManager.GetPlayerRankInformation(player).Permissions[commandName] then return true end
	if adminManager.GetPlayerRankInformation(player).Permissions[require(script.Commands[commandName]).CommandType] then return true end
	
	-- Well what happened?
	return false
end


-- Searches the rank information to see if the player qualifies for any of them and then stores that result to save on processing power
function adminManager.GetPlayerRankInformation(player)
	if adminManager.SavedRanksAssignedToPlayers[player] then return config.RankInformation[adminManager.SavedRanksAssignedToPlayers[player]] end
	
	-- Let's find out
	for rankName, rankInformation in next, config.RankInformation do
		if rankInformation.Users then
			for _, rankRequirement in next, rankInformation.Users do
				if 	-- UserId:12345678, Group:12345678, Group:12345678:123
					(rankRequirement:match("UserId:%d+") and player.UserId == tonumber(rankRequirement:match("UserId:(%d+)")))
						or (rankRequirement:match("Group:%d+") and not rankRequirement:match("Group:%d+:%d+")) and player:IsInGroup(tonumber(rankRequirement:match("Group:(%d+)")))
						or (rankRequirement:match("Group:%d+:%d+") and player:GetRankInGroup(tonumber(rankRequirement:match("Group:(%d+)"))) == tonumber(rankRequirement:match("Group:%d+:(%d+)")))
				then
					adminManager.SavedRanksAssignedToPlayers[player] = rankName
					return rankInformation
				end
			end
		end
	end
end


-- Translates something like me, all, others, 2he*, ... to a usable array
function adminManager.GetTargetArrayFromRawString(player, rawString, allowNonPlayerEntries)
	if not rawString then return {player} end
	rawString = rawString:gsub("%a+%,+%s*", function(match) 
		return match:gsub("%s+", "")
	end)
	
	-- Decode time babey
	local targetArray = {}
	for targetString in rawString:gmatch("[^%,]+") do
		if targetString == "me" then			-- You
			table.insert(targetArray, player)
		elseif targetString == "all" then		-- All players
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				table.insert(targetArray, nestedPlayer)
			end
		elseif targetString == "others" then	-- Everyone but you
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				if nestedPlayer ~= player then
					table.insert(targetArray, nestedPlayer)
				end
			end
		elseif targetString:match("%*$") then	-- Name* (get's all users with a name similar to that)
			for _, nestedPlayer in next, coreModule.Services.Players:GetPlayers() do
				if nestedPlayer.Name:match("[^%*]+") then
					table.insert(targetArray, nestedPlayer)
				end
			end
		else									-- Assume it's a player's name/userid?
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
	
	--
	return targetArray
end


--
return adminManager