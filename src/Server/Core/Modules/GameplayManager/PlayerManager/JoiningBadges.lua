-- Variables
local joiningBadgesManager = {}
local coreModule = require(script:FindFirstAncestor("Core"))
local badgeService = require(coreModule.GetObject("Libraries.BadgeLibrary"))

-- Initialize
function joiningBadgesManager.Initialize(player: Player)
    -- Badge for joining the game.
    -- https://www.roblox.com/badges/2124520540/Let-the-Games-Begin
    badgeService.AwardBadge(player, 2124520540)

    -- Is this player a developer?
    if player:GetRankInGroup(4246980) >= 253 then
        for _, playerInServer in next, game:GetService("Players"):GetPlayers() do
            badgeService.AwardBadge(playerInServer, 2124520543)
        end
    else

        -- Maybe a developer is in the game?
        for _, playerInServer in next, game:GetService("Players"):GetPlayers() do
            if playerInServer:GetRankInGroup(4246980) >= 253 then
                badgeService.AwardBadge(player, 2124520543)
                break
            end
        end
    end
end

--
return joiningBadgesManager