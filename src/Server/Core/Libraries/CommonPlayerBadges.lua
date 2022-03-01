--[[
    This libraries purpose is to implement common player badges.
    Those being "Met the Creator" and "Joined for the First Time"...
]]

local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))

local CommonPlayerBadges = {}
CommonPlayerBadges.FIRST_TIME_PLAYING_BADGE_ID = 2124520540
CommonPlayerBadges.MET_THE_CREATOR_BADGE_ID = 2124520543
CommonPlayerBadges.MET_THE_CREATOR_GROUP_ID = 4246980
CommonPlayerBadges.MET_THE_CREATOR_GROUP_MINIMUM_RANK_VALUE = 253
CommonPlayerBadges.MET_THE_CREATOR_USER_IDS = {}

-- Attempts to award the server any eligible badges.
function CommonPlayerBadges.AwardBadges(player: Player)

    -- We attempt to award FIRST_TIME_PLAYING_BADGE_ID always.
    badgeService.AwardBadge(player, CommonPlayerBadges.FIRST_TIME_PLAYING_BADGE_ID)

    -- Is this player a developer?
    if CommonPlayerBadges._IsPlayerDeveloper(player) then
        for _, thisPlayer: Player in next, players:GetPlayers() do
            badgeService.AwardBadge(thisPlayer, CommonPlayerBadges.MET_THE_CREATOR_BADGE_ID)
        end

        return
    end

    -- Is there a developer in the server?
    -- If so we want to award the badge to the player originally given to us.
    for _, thisPlayer: Player in next, players:GetPlayers() do
        if CommonPlayerBadges._IsPlayerDeveloper(thisPlayer) then
            badgeService.AwardBadge(player, CommonPlayerBadges.MET_THE_CREATOR_BADGE_ID)
            break
        end
    end
end

-- Returns whether or not that this player is classified as a Developer.
function CommonPlayerBadges._IsPlayerDeveloper(player: Player) : boolean

    -- Can we check the group?
    if CommonPlayerBadges.MET_THE_CREATOR_GROUP_ID > 0 then
        if player:GetRankInGroup(CommonPlayerBadges.MET_THE_CREATOR_GROUP_ID) >= (CommonPlayerBadges.MET_THE_CREATOR_GROUP_MINIMUM_RANK_VALUE or 255) then
            return true
        end
    end

    -- Can we check user ids?
    if table.find(CommonPlayerBadges.MET_THE_CREATOR_USER_IDS, player.UserId) then
        return true
    end

    return false
end

return CommonPlayerBadges
