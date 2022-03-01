local players: Players = game:GetService("Players")

local SpatialQueryUtilities = {}

-- Returns a list of players that have part of their character inside of the given part.
function SpatialQueryUtilities.GetPlayersWithinParts(part: BasePart, overlapParameters: OverlapParams?) : {Player}

    local playersArray: {Player} = {}

    for _, partWithinPart: BasePart in next, workspace:GetPartsInPart(part, overlapParameters) do

        -- Is this a player and one that is not in the array already?
        local player = players:GetPlayerFromCharacter(partWithinPart:FindFirstAncestorOfClass("Model"))

        if player and not table.find(playersArray, player) then
            table.insert(playersArray, player)
        end
    end

    return playersArray
end

return SpatialQueryUtilities