-- Variables
local badgeLibrary = {}
badgeLibrary.BadgeOwnershipUpdated = Instance.new("BindableEvent")
badgeLibrary.BadgeOwnershipCache = {}
badgeLibrary.PlayerRemovingListener = nil

local coreModule = require(script:FindFirstAncestor("CoreModule"))
local utilitiesLibrary = require(coreModule.Shared.GetObject("Libraries.Utilities"))

-- Methods
function badgeLibrary.AwardBadge(player, badgeId)
	if coreModule.Services.RunService:IsStudio() then return end
	if not utilitiesLibrary.IsValidPlayer(player) then return end
	if not tonumber(badgeId) or badgeId <= 0 then return end
	if badgeLibrary.UserOwnsBadge(player, badgeId) then return end
	
	-- Set PlayerRemovingListener?
	if not badgeLibrary.PlayerRemovingListener then
		badgeLibrary.PlayerRemovingListener = coreModule.Services.Players.PlayerRemoving:Connect(function(player)
			badgeLibrary.BadgeOwnershipCache[player] = nil
		end)
	end
	
	-- Update BadgeOwnershipCache
	badgeLibrary.BadgeOwnershipCache[player] = badgeLibrary.BadgeOwnershipCache[player] or {}
	badgeLibrary.BadgeOwnershipCache[player][badgeId] = true
	coreModule.Services.BadgeService:AwardBadge(player.UserId, badgeId)
	badgeLibrary.BadgeOwnershipUpdated:Fire(player, badgeId)
	coreModule.Shared.GetObject("//Remotes.BadgeOwnershipUpdated"):FireClient(player, badgeId)
end

function badgeLibrary.UserOwnsBadge(player, badgeId)
	if not utilitiesLibrary.IsValidPlayer(player) then return end
	if not tonumber(badgeId) or badgeId <= 0 then return end
	
	--  Check
	badgeLibrary.BadgeOwnershipCache[player] = badgeLibrary.BadgeOwnershipCache[player] or {}
	if badgeLibrary.BadgeOwnershipCache[player][badgeId] == nil then
		badgeLibrary.BadgeOwnershipCache[player][badgeId] = coreModule.Services.BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end
	
	--
	return badgeLibrary.BadgeOwnershipCache[player][badgeId]
end

--
return badgeLibrary