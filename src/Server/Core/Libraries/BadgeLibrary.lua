-- Variables
local badgeLibrary = {}
badgeLibrary.BadgeOwnershipUpdated = Instance.new("BindableEvent")
badgeLibrary.BadgeOwnershipCache = {}
badgeLibrary.PlayerRemovingListener = nil

local coreModule = require(script:FindFirstAncestor("Core"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Methods
function badgeLibrary.AwardBadge(player, badgeId)

	-- Guard clauses against very simple mistakes.
	if game:GetService("RunService"):IsStudio() then return end
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not tonumber(badgeId) or badgeId <= 0 then return end
	if badgeLibrary.UserOwnsBadge(player, badgeId) then return end
	
	-- Set PlayerRemovingListener; Just to help on server memory/memory leaks with the cache.
	if not badgeLibrary.PlayerRemovingListener then
		badgeLibrary.PlayerRemovingListener = game:GetService("Players").PlayerRemoving:Connect(function(player)
			badgeLibrary.BadgeOwnershipCache[player] = nil
		end)
	end
	
	-- Update BadgeOwnershipCache.
	badgeLibrary.BadgeOwnershipCache[player] = badgeLibrary.BadgeOwnershipCache[player] or {}
	badgeLibrary.BadgeOwnershipCache[player][badgeId] = true

	-- Award the badge + notify the server and client.
	game:GetService("BadgeService"):AwardBadge(player.UserId, badgeId)
	badgeLibrary.BadgeOwnershipUpdated:Fire(player, badgeId)
	coreModule.Shared.GetObject("//Remotes.Server.BadgeOwnershipUpdated"):FireClient(player, badgeId)
end


function badgeLibrary.UserOwnsBadge(player, badgeId)

	-- Guard clauses against very simple mistakes.
	if not utilitiesLibrary.IsPlayerValid(player) then return end
	if not tonumber(badgeId) or badgeId <= 0 then return end
	
	--  Check the BadgeOwnershipCache and update it if possible.
	badgeLibrary.BadgeOwnershipCache[player] = badgeLibrary.BadgeOwnershipCache[player] or {}
	if badgeLibrary.BadgeOwnershipCache[player][badgeId] == nil then
		badgeLibrary.BadgeOwnershipCache[player][badgeId] = game:GetService("BadgeService"):UserHasBadgeAsync(player.UserId, badgeId)
	end
	
	return badgeLibrary.BadgeOwnershipCache[player][badgeId]
end


--
return badgeLibrary