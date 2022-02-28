local badgeService: BadgeService = game:GetService("BadgeService")
local players: Players = game:GetService("Players")
local runService: RunService = game:GetService("RunService")

local BadgeServiceWrapper = {Server = {}, Client = {}}
BadgeServiceWrapper.Server.BadgeAwarded = script.BadgeAwardedServer
BadgeServiceWrapper.Server.BadgeOwnershipCache = {}
BadgeServiceWrapper.Server._PlayerRemovingListener = nil
BadgeServiceWrapper.Server._HasSetUserHasBadgeAsyncCallback = false
BadgeServiceWrapper.Client.BadgeAwarded = script.BadgeAwardedClient
BadgeServiceWrapper.DebuggingEnabled = true

-- Award a badge to a player given the ID of each.
function BadgeServiceWrapper.AwardBadge(player: Player, badgeId: number) : boolean
	assert(runService:IsServer(), "BadgeUtilities.AwardBadge cannot be called from the client.")
	assert(badgeId > 0, "Argument #2 must be greater than 0.")

	local wasSuccessful: boolean, returnedValue: boolean | string = pcall(badgeService.AwardBadge, badgeService, player.UserId, badgeId)

	-- Communication with the client.
	if wasSuccessful and runService:IsServer() then
		BadgeServiceWrapper.Server.BadgeAwarded:Fire(player, badgeId)
		BadgeServiceWrapper.Client.BadgeAwarded:FireClient(player, badgeId)
		BadgeServiceWrapper.Server.BadgeOwnershipCache[player] = BadgeServiceWrapper.Server.BadgeOwnershipCache[player] or {}

		-- Let's try to cache this.
		if not table.find(BadgeServiceWrapper.Server.BadgeOwnershipCache[player], badgeId) then
			table.insert(BadgeServiceWrapper.Server.BadgeOwnershipCache[player], badgeId)
		end
	end

	if BadgeServiceWrapper.DebuggingEnabled then
		if wasSuccessful and returnedValue then
			print("[" .. script.Name .. "]: Successfully awarded [" .. badgeId .. "] to " .. player.Name .. ".")
		else
			warn("[" .. script.Name .. "]: " .. (typeof(returnedValue) == "boolean" and ("Could not award [" .. badgeId .."] to " .. player.Name) or returnedValue) .. ".")
		end
	end

	return wasSuccessful and returnedValue
end

-- Checks whether a player has the badge given the Player.UserId and the badge ID.
function BadgeServiceWrapper.UserHasBadgeAsync(playerOrBadgeId: Player | number, badgeId: number?) : boolean

	-- The client has to get it's information from the server.
	if runService:IsClient() then
		assert((typeof(playerOrBadgeId) == "Instance" and playerOrBadgeId:IsA("Player")) or typeof(playerOrBadgeId) == "number", "Argument #1 must be a Player or a number.")
		return script.UserHasBadgeAsync:InvokeServer(playerOrBadgeId, badgeId)
	end

	-- From here on we know its on the server.
	assert(typeof(playerOrBadgeId) == "Instance" and playerOrBadgeId:IsA("Player"), "Argument #1 must be a Player. Got " .. typeof(playerOrBadgeId) .. ".")
	assert(typeof(badgeId) == "number", "Argument #2 must be a number. Got " .. typeof(badgeId))
	assert(badgeId > 0, "Argument #2 must be greater than 0.")

	local player: Player = playerOrBadgeId
	BadgeServiceWrapper.Server.BadgeOwnershipCache[player] = BadgeServiceWrapper.Server.BadgeOwnershipCache[player] or {}

	if not table.find(BadgeServiceWrapper.Server.BadgeOwnershipCache[player], badgeId) then
		local wasSuccessful: boolean, returnedValue: boolean | string = pcall(badgeService.UserHasBadgeAsync, badgeService, player.UserId, badgeId)

		if wasSuccessful and returnedValue then
			table.insert(BadgeServiceWrapper.Server.BadgeOwnershipCache[player], badgeId)
		end

		if BadgeServiceWrapper.DebuggingEnabled then
			if not wasSuccessful then
				warn("[" .. script.Name .. "]: " .. (typeof(returnedValue) == "boolean" and ("Could not check ownership of [" .. badgeId .."] for " .. player.Name) or returnedValue) .. ".")
			end
		end
	end

	return table.find(BadgeServiceWrapper.Server.BadgeOwnershipCache[player], badgeId) ~= nil
end

-- Fetch information about a badge given its ID.
function BadgeServiceWrapper.GetBadgeInfoAsync(badgeId: number) : {}?
	assert(typeof(badgeId) == "number", "Argument #1 must be a number. Got " .. typeof(badgeId) .. ".")
	assert(badgeId > 0, "Argument #1 must be greater than 0.")

	local wasSuccessful: boolean, returnedValue: {} | string = pcall(badgeService.GetBadgeInfoAsync, badgeService, badgeId)

	if BadgeServiceWrapper.DebuggingEnabled then
		if not wasSuccessful then
			warn("[" .. script.Name .. "]: " .. returnedValue .. ".")
		end
	end

	return wasSuccessful and returnedValue or nil
end

-- Initialization
if runService:IsServer() then
	if not BadgeServiceWrapper._PlayerRemovingListener then
		BadgeServiceWrapper._PlayerRemovingListener = players.PlayerRemoving:Connect(function(player: Player)
			BadgeServiceWrapper.Server.BadgeOwnershipCache[player] = nil
		end)
	end

	if not BadgeServiceWrapper._HasSetUserHasBadgeAsyncCallback then
		script.UserHasBadgeAsync.OnServerInvoke = function(player: Player, playerOrBadgeId: Player | number, badgeId: number?)
			if typeof(playerOrBadgeId) == "Instance" and playerOrBadgeId:IsA("Player") then
				return BadgeServiceWrapper.UserHasBadgeAsync(playerOrBadgeId :: Player, badgeId)
			else
				return BadgeServiceWrapper.UserHasBadgeAsync(player, playerOrBadgeId :: number)
			end
		end
	end
end

return BadgeServiceWrapper
